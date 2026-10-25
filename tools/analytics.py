"""Métricas del juego con la API oficial Open Cloud Analytics (create.roblox.com/docs/cloud/guides/analytics).

  python tools/analytics.py summary --universe <id> [--days 28]
  python tools/analytics.py query --universe <id> --metric DailyActiveUsers [--granularity OneDay] [--days 7] [--breakdown Platform]
  python tools/analytics.py selftest

Necesita una API key en la variable de entorno ROBLOX_ANALYTICS_API_KEY, creada en el Creator Dashboard
con permiso `universe.analytics:read` sobre el juego. La key nunca va al repo ni a los documentos.
El Universe ID está en la página del juego en el Creator Dashboard.
Las señales de Home Recommendations (PTR, bounce) no están en esta API: se leen del dashboard.
"""
import argparse
import datetime as dt
import json
import os
import sys
import time
import urllib.error
import urllib.request

BASE = "https://apis.roblox.com/analytics-query-api/"
API_KEY_ENV = "ROBLOX_ANALYTICS_API_KEY"
POLL_SECONDS = 2
MAX_WAIT_SECONDS = 120

# (métrica de la API, nombre en el reporte). Todas aceptan granularidad OneDay (/cloud/guides/analytics/metrics).
SUMMARY_METRICS = [
    ("DailyActiveUsers", "Usuarios activos por día"),
    ("ForwardD1Retention", "Retención D1"),
    ("ForwardD7Retention", "Retención D7"),
    ("AveragePlayTimeMinutesPerDAU", "Minutos de juego por usuario activo"),
    ("AverageSessionLengthMinutes", "Minutos por sesión"),
    ("DailyRevenue", "Ingresos"),
    ("PayingUsers", "Usuarios que pagan"),
]

HINTS = {
    401: "API key inválida o sin permiso universe.analytics:read sobre este juego",
    404: "Universe ID u operación inexistente",
    429: "consulta demasiado grande: menos días, granularidad más gruesa o menos desgloses",
}


class AnalyticsError(Exception):
    pass


def http_sender(api_key: str):
    """Devuelve send(method, url, body) -> (status, json) usando urllib."""
    def send(method: str, url: str, body):
        data = json.dumps(body).encode("utf-8") if body is not None else None
        request = urllib.request.Request(url, data=data, method=method,
                                         headers={"x-api-key": api_key, "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.status, json.loads(response.read() or b"null")
        except urllib.error.HTTPError as e:
            raw = e.read()
            try:
                return e.code, json.loads(raw) if raw else None
            except ValueError:
                return e.code, None
    return send


def query(send, universe: str, metric: str, granularity: str, start: dt.datetime, end: dt.datetime,
          breakdown=None, sleep=time.sleep) -> list:
    """Corre la consulta (esperando si la API la deja pendiente) y devuelve `response.values`."""
    body = {"metric": metric, "granularity": granularity,
            "startTime": start.strftime("%Y-%m-%dT%H:%M:%SZ"), "endTime": end.strftime("%Y-%m-%dT%H:%M:%SZ")}
    if breakdown:
        body["breakdown"] = breakdown
    status, result = send("POST", f"{BASE}v1/universes/{universe}/metrics", body)
    waited = 0
    while status in (200, 202) and isinstance(result, dict) and not result.get("done"):
        if waited >= MAX_WAIT_SECONDS:
            raise AnalyticsError(f"{metric}: la consulta sigue pendiente después de {MAX_WAIT_SECONDS} s")
        sleep(POLL_SECONDS)
        waited += POLL_SECONDS
        status, result = send("GET", BASE + result["path"], None)
    if status not in (200, 202):
        detail = (result or {}).get("error", {}).get("message") if isinstance(result, dict) else None
        raise AnalyticsError(f"{metric}: HTTP {status} ({detail or HINTS.get(status, 'error de la API')})")
    if not isinstance(result, dict):
        raise AnalyticsError(f"{metric}: respuesta vacía o inesperada de la API")
    if "error" in result:
        raise AnalyticsError(f"{metric}: {result['error'].get('message')} (código {result['error'].get('code')})")
    return result.get("response", {}).get("values", [])


def stats(points: list):
    """(último valor con fecha, promedio, mínimo, máximo, cantidad) ignorando días sin dato."""
    values = [(p["time"][:10], p["value"]) for p in points if isinstance(p.get("value"), (int, float))]
    if not values:
        return None
    numbers = [v for _, v in values]
    return values[-1], sum(numbers) / len(numbers), min(numbers), max(numbers), len(numbers)


def window(days: int, today=None):
    # endTime es exclusivo y los días van en UTC: hasta ayer inclusive.
    end = dt.datetime.combine(today or dt.datetime.now(dt.timezone.utc).date(), dt.time(), dt.timezone.utc)
    return end - dt.timedelta(days=days), end


def fmt(n: float) -> str:
    return f"{n:,.2f}".rstrip("0").rstrip(".")


def summary(send, universe: str, days: int, sleep=time.sleep, today=None) -> str:
    start, end = window(days, today)
    lines = [f"Métricas del universo {universe}, {start:%Y-%m-%d} a {end - dt.timedelta(days=1):%Y-%m-%d} "
             f"(fuente: Open Cloud Analytics, consultado {dt.datetime.now(dt.timezone.utc):%Y-%m-%d}).",
             "Valores tal como los devuelve la API.", "",
             "| Métrica | Último (fecha) | Promedio | Mínimo | Máximo | Días con dato |", "|---|---|---|---|---|---|"]
    for metric, label in SUMMARY_METRICS:
        try:
            series = query(send, universe, metric, "OneDay", start, end, sleep=sleep)
            result = stats(series[0]["dataPoints"]) if series else None
        except AnalyticsError as e:
            lines.append(f"| {label} | error: {e} | | | | |")
            continue
        if not result:
            lines.append(f"| {label} | sin datos | | | | 0 |")
            continue
        (day, last), avg, low, high, count = result
        lines.append(f"| {label} | {fmt(last)} ({day}) | {fmt(avg)} | {fmt(low)} | {fmt(high)} | {count} |")
    return "\n".join(lines)


def selftest():
    calls = []

    def fake(responses):
        def send(method, url, body):
            calls.append((method, url, body))
            return responses.pop(0)
        return send

    start, end = window(7, dt.date(2026, 1, 8))
    assert (start.isoformat(), end.isoformat()) == ("2026-01-01T00:00:00+00:00", "2026-01-08T00:00:00+00:00")

    points = [{"time": "2026-01-01T00:00:00Z", "value": 10}, {"time": "2026-01-02T00:00:00Z", "value": 20}]
    done = {"done": True, "response": {"values": [{"breakdowns": [], "dataPoints": points}]}}
    pending = {"done": False, "path": "v1/universes/1/operations/metrics/abc"}
    values = query(fake([(202, pending), (200, done)]), "1", "DailyActiveUsers", "OneDay", start, end,
                   sleep=lambda s: None)
    assert values[0]["dataPoints"] == points
    assert calls[0][0] == "POST" and calls[0][1].endswith("/v1/universes/1/metrics")
    assert calls[0][2]["startTime"] == "2026-01-01T00:00:00Z" and calls[0][2]["endTime"] == "2026-01-08T00:00:00Z"
    assert calls[1] == ("GET", BASE + "v1/universes/1/operations/metrics/abc", None)

    for responses, fragment in (
        ([(401, None)], "universe.analytics:read"),
        ([(200, {"done": True, "error": {"code": 2001, "message": "bad granularity"}})], "bad granularity"),
        ([(429, {"error": {"code": 3000, "message": "budget"}})], "budget"),
    ):
        try:
            query(fake(responses), "1", "X", "OneDay", start, end, sleep=lambda s: None)
            raise AssertionError("debía fallar: " + fragment)
        except AnalyticsError as e:
            assert fragment in str(e), str(e)

    assert stats([{"time": "2026-01-01T00:00:00Z"}]) is None
    (day, last), avg, low, high, count = stats(points)
    assert (day, last, avg, low, high, count) == ("2026-01-02", 20, 15, 10, 20, 2)

    report = summary(fake([(200, done)] + [(401, None)] * (len(SUMMARY_METRICS) - 1)), "1", 7,
                     sleep=lambda s: None, today=dt.date(2026, 1, 8))
    assert "| Usuarios activos por día | 20 (2026-01-02) | 15 | 10 | 20 | 2 |" in report, report
    assert report.count("error:") == len(SUMMARY_METRICS) - 1
    print("selftest OK")


def main():
    sys.stdout.reconfigure(encoding="utf-8")  # la consola de Windows no es UTF-8 por defecto
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = parser.add_subparsers(dest="cmd", required=True)
    s = sub.add_parser("summary")
    s.add_argument("--universe", required=True)
    s.add_argument("--days", type=int, default=28)
    q = sub.add_parser("query")
    q.add_argument("--universe", required=True)
    q.add_argument("--metric", required=True)
    q.add_argument("--granularity", default="OneDay")
    q.add_argument("--days", type=int, default=7)
    q.add_argument("--breakdown", action="append")
    sub.add_parser("selftest")
    args = parser.parse_args()

    if args.cmd == "selftest":
        return selftest()
    api_key = os.environ.get(API_KEY_ENV)
    if not api_key:
        sys.exit(f"Falta la variable de entorno {API_KEY_ENV} (API key con permiso universe.analytics:read).")
    send = http_sender(api_key)
    try:
        if args.cmd == "summary":
            print(summary(send, args.universe, args.days))
        else:
            start, end = window(args.days)
            print(json.dumps(query(send, args.universe, args.metric, args.granularity, start, end, args.breakdown),
                             indent=2, ensure_ascii=False))
    except AnalyticsError as e:
        sys.exit(f"Error: {e}")


if __name__ == "__main__":
    main()
