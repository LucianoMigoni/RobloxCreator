"""Creador de campañas: plan por etapas, campañas de Ads Manager por API y lectura de resultados.

  python tools/campaigns.py plan --game games/<juego> --goal launch --budget 300 [--start 2026-11-05]
         [--universe <id>] [--kids-pending] [--countries US,GB] [--devices PHONE,TABLET] [--name "Launch"]
  python tools/campaigns.py create <plan.json> [--only N] [--yes]
  python tools/campaigns.py status <campaignId> [<campaignId>...]
  python tools/campaigns.py set <campaignId> (--pause | --resume | --cancel | --daily USD) --yes
  python tools/campaigns.py report <export.csv> [--json]
  python tools/campaigns.py thumbs --universe <id> [--days 7]
  python tools/campaigns.py selftest

- plan: escribe games/<juego>/docs/campanas/<fecha>-<nombre>.md (para leer y aprobar en el PR) y .json
  (para `create`). Etapas, fechas (empiezan un jueves: el aprendizaje de 24-48 h termina antes del
  pico del sábado), presupuesto por etapa, creatividades a producir, LaunchData para el premio de
  bienvenida y reglas de corte. Objetivos: launch, update, earnings, lapsed.
- create/status/set: Ads API de Open Cloud (experimental, https://create.roblox.com/docs/cloud/guides/advertising).
  `create` y `set` simulan por defecto: con --yes gastan dinero real. La clave va en ROBLOX_ADS_API_KEY
  (clave de USUARIO con ad.campaign:read, ad.campaign:write y ad.billing:read; la API no acepta claves
  de grupo).
- report: lee el CSV exportado de Ads Manager (encabezados flexibles) y calcula CTR, tasa de juego, CPM,
  CPP y ROAS con las reglas de corte de skills/_shared/anuncios-2026.md.
- thumbs: rendimiento de cada miniatura de Home (Analytics API, ROBLOX_ANALYTICS_API_KEY).
Las reglas y montos son criterio del hub (skills/_shared/anuncios-2026.md), no garantías.
"""
import argparse
import csv
import datetime as dt
import json
import os
import re
import statistics
import sys
import urllib.error
import urllib.request
import uuid
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import analytics  # noqa: E402  (mismo directorio: tools/analytics.py)

ADS_API = "https://apis.roblox.com/ads-management/v1"
ADS_KEY_ENV = "ROBLOX_ADS_API_KEY"
PLAN_NAMESPACE = uuid.UUID("6f1d3c52-6a0b-4f8e-9a51-2b7f0c9e4d11")

# Recetas de skills/_shared/vitrina/recetas y la hipótesis que prueba cada una.
CREATIVE_IDEAS = [
    ("robo-tension", "La mecánica: robarle el premio a la criatura gigante"),
    ("numero-gigante", "El número: la ganancia por segundo enorme"),
    ("rareza-secret", "La suerte: la criatura SECRET y su probabilidad"),
    ("objeto-gigante", "El premio: el huevo o cofre gigante brillando"),
    ("mas-uno", "El progreso: cada paso suma +1"),
    ("evento-temporada", "La novedad: el evento o update de temporada"),
    ("robo-tension", "Variante: otra criatura o bioma"),
    ("numero-gigante", "Variante: otra criatura SECRET"),
    ("objeto-gigante", "Variante: otro color de huevo o rareza"),
    ("rareza-secret", "Variante: otra probabilidad"),
]

# Reglas de corte (criterio del hub, anuncios-2026.md §3).
RULES = {
    "ctr_min": 2.0,            # % con más de min_impressions: apagar la miniatura
    "ctr_good": 3.0,
    "ctr_great": 4.0,
    "min_impressions": 20000,
    "cpp_factor": 3.0,         # CPP mayor a 3 veces la mediana de la cuenta
    "roas_cut": 70.0,          # % estimado a los 7 días: bajar presupuesto
    "roas_scale": 100.0,       # % o más: subir 20-30 %
}


class CampaignError(Exception):
    pass


def slug(text: str) -> str:
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-") or "campana"


def next_thursday(today: dt.date) -> dt.date:
    days = (3 - today.weekday()) % 7
    return today + dt.timedelta(days=days or 7)


def stages_for(goal: str, budget: float, kids_pending: bool) -> list:
    """Etapas con su parte del presupuesto, días y objetivo de Ads Manager."""
    if goal == "launch":
        parts = [
            {"key": "humo", "title": "Prueba de humo: ¿retiene a desconocidos?", "objective": "Plays",
             "audience": "New Players", "days": 4, "share": 0.10, "creatives": 4,
             "pass": "D1 de los que llegan por anuncio de 20 % o más y rebote en 60 s de 30 % o menos"},
            {"key": "miniaturas", "title": "Miniaturas: ¿qué imagen hace clic?", "objective": "Plays",
             "audience": "New Players", "days": 7, "share": 0.20, "creatives": 10,
             "pass": "Alguna miniatura con CTR de 3 % o más y CPP en el rango normal"},
        ]
        if kids_pending:
            parts.append({"key": "kids", "title": "Kids y Select: llegar al umbral de jugadores comprometidos",
                          "objective": "Engagement", "audience": "All Players", "days": 10, "share": 0.20,
                          "creatives": 3, "pass": "Juego habilitado para menores de 16 (Audience Reach en Creator Hub)"})
        parts.append({"key": "empuje", "title": "Empuje: entrar en Home", "objective": "Plays",
                      "audience": "New Players", "days": 10,
                      "share": round(1 - sum(p["share"] for p in parts), 2), "creatives": 3,
                      "pass": "Home recommendations sube sola y los que llegan por Home retienen"})
        return parts
    if goal == "update":
        return [{"key": "update", "title": "Update: traer nuevos y recuperar inactivos", "objective": "Plays",
                 "audience": "New Players", "days": 7, "share": 1.0, "creatives": 6,
                 "pass": "Jugadas y D7 de la semana del update mayores a las de la semana anterior"}]
    if goal == "lapsed":
        return [{"key": "inactivos", "title": "Recuperar inactivos (30 a 180 días)", "objective": "Plays",
                 "audience": "Lapsed Players", "days": 7, "share": 1.0, "creatives": 4,
                 "pass": "Usuarios resucitados con D7 igual o mayor al de los activos (exige 20 000 inactivos)"}]
    if goal == "earnings":
        return [{"key": "ganancias", "title": "Earnings: jugadores que gastan", "objective": "Earnings",
                 "audience": "New Players", "days": 14, "share": 1.0, "creatives": 4,
                 "pass": "ROAS estimado de 100 % o más (si baja de 70 % a los 7 días, bajar presupuesto)"}]
    raise CampaignError(f"objetivo desconocido: {goal} (launch, update, lapsed o earnings)")


def build_plan(game: str, goal: str, budget: float, start: dt.date, name: str = "", universe: str = "",
               kids_pending: bool = False, countries=None, devices=None, payment: str = "ADS_CREDIT") -> dict:
    if budget <= 0:
        raise CampaignError("el presupuesto tiene que ser mayor a 0")
    stages = stages_for(goal, budget, kids_pending)
    game_name = Path(game).name
    plan_name = name or f"{game_name} {goal}"
    plan_id = str(uuid.uuid5(PLAN_NAMESPACE, f"{game}|{plan_name}|{start.isoformat()}"))
    campaigns, day = [], start
    for i, st in enumerate(stages):
        total = round(budget * st["share"], 2)
        daily = round(total / st["days"], 2)
        if st["key"] == "empuje":
            # El empuje arranca un jueves para llegar con el aprendizaje hecho al sábado.
            day = next_thursday(day - dt.timedelta(days=1))
        creatives = [{"slot": j + 1, "recipe": CREATIVE_IDEAS[j][0], "hypothesis": CREATIVE_IDEAS[j][1],
                      "file": f"{game}/marketing/ads/{st['key']}-{j + 1:02d}.png", "assetId": ""}
                     for j in range(st["creatives"])]
        campaigns.append({
            "index": i,
            "stage": st["key"],
            "title": st["title"],
            "name": f"{plan_name} - {st['key']}",
            "objective": st["objective"],
            "apiObjective": "ENGAGEMENT",
            "audience": st["audience"],
            "paymentType": payment,
            "budget": {"type": "DAILY", "amountMicros": str(int(round(daily * 1_000_000))), "usd": daily},
            "totalUsd": total,
            "schedule": {"startTime": f"{day.isoformat()}T15:00:00Z", "durationInDays": st["days"]},
            "targeting": {k: v for k, v in (("countries", countries or []), ("devices", devices or [])) if v},
            "launchData": f"ad_{slug(st['key'])}",
            "creatives": creatives,
            "creativeAssetIds": [],
            "pass": st["pass"],
            "campaignId": "",
        })
        day = day + dt.timedelta(days=st["days"])
    return {"planId": plan_id, "name": plan_name, "game": game, "goal": goal, "universeId": universe,
            "budgetUsd": budget, "created": dt.date.today().isoformat(), "rules": RULES, "campaigns": campaigns}


def plan_markdown(plan: dict) -> str:
    c0 = plan["campaigns"][0]
    end = dt.date.fromisoformat(plan["campaigns"][-1]["schedule"]["startTime"][:10]) + dt.timedelta(
        days=plan["campaigns"][-1]["schedule"]["durationInDays"] - 1)
    lines = [
        f"# Campaña: {plan['name']}",
        "",
        f"Plan generado con `tools/campaigns.py plan` el {plan['created']}. Objetivo `{plan['goal']}`, "
        f"presupuesto total **{plan['budgetUsd']:.2f} USD**, del {c0['schedule']['startTime'][:10]} al {end.isoformat()}. "
        "Los montos y umbrales son criterio del hub (`skills/_shared/anuncios-2026.md`): se ajustan con lo que mida "
        "cada etapa. Gastar lo aprueba una persona: `create` solo gasta con `--yes`.",
        "",
        "## Antes de gastar",
        "",
        "- [ ] Miniatura propia y video de gameplay subidos; 2 a 5 miniaturas activas en la personalización de Home.",
        "- [ ] El primer minuto funciona: nada de rebote en 60 s por bugs (revisar `qa.md`).",
        "- [ ] Premio de bienvenida para quien entra por un anuncio configurado en `Config/CampaignConfig.luau` "
        "con los LaunchData de abajo, y anunciado en el juego (\"Welcome gift!\").",
        "- [ ] Si el juego apunta a chicos: estado de Kids y Select en Creator Hub → Audience Reach "
        "(o revisión rápida de 100 000 Robux devolvibles).",
        "- [ ] Share links creados por canal externo (TikTok, YouTube, Discord no: links a Discord no van en el juego).",
        "- [ ] Evento del juego programado para el fin de semana del empuje (\"Notify Me\").",
        "",
        "## Etapas",
        "",
        "| # | Etapa | Objetivo | Público | Inicio | Días | USD/día | Total USD | Pasa si… |",
        "|---|---|---|---|---|---|---|---|---|",
    ]
    for c in plan["campaigns"]:
        lines.append(f"| {c['index'] + 1} | {c['title']} | {c['objective']} | {c['audience']} | "
                     f"{c['schedule']['startTime'][:10]} | {c['schedule']['durationInDays']} | {c['budget']['usd']:.2f} | "
                     f"{c['totalUsd']:.2f} | {c['pass']} |")
    lines += [
        "",
        "No pausar una campaña en marcha salvo por las reglas de corte: cada pausa reinicia el aprendizaje de 24-48 h.",
        "",
        "## Creatividades",
        "",
        "Hasta 10 por campaña, en 16:9 (1920×1080). Se arman con `tools/thumbs.py` y las recetas de "
        "`skills/_shared/vitrina/recetas/`, con renders y capturas del juego (`skills/_shared/vitrina-hits.md`). "
        "Subirlas a la biblioteca de Ads Manager o con `tools/roblox_upload.py` y anotar el assetId en el JSON.",
        "",
        "| Etapa | Slot | Receta | Hipótesis | Archivo | assetId |",
        "|---|---|---|---|---|---|",
    ]
    for c in plan["campaigns"]:
        for cr in c["creatives"]:
            lines.append(f"| {c['stage']} | {cr['slot']} | `{cr['recipe']}` | {cr['hypothesis']} | `{cr['file']}` | |")
    lines += [
        "",
        "## LaunchData (premio de bienvenida y medición)",
        "",
        "| Etapa | LaunchData |",
        "|---|---|",
    ]
    for c in plan["campaigns"]:
        lines.append(f"| {c['stage']} | `{c['launchData']}` |")
    lines += [
        "",
        "En Ads Manager: Advanced options → launch data. El juego lo lee con `player:GetJoinData().LaunchData`.",
        "",
        "## Reglas de corte (revisar cada 24 h después de las primeras 48)",
        "",
        f"- CTR menor a {RULES['ctr_min']} % con más de {RULES['min_impressions']:,} impresiones: apagar esa miniatura "
        f"y reemplazarla. {RULES['ctr_good']} % es bueno; {RULES['ctr_great']} % es excelente.",
        f"- CPP mayor a {RULES['cpp_factor']:.0f} veces la mediana de la cuenta durante 48 h: revisar segmentación o cortar.",
        "- D7 de los que llegan por anuncio menor a la mitad del orgánico: pausar y arreglar el juego antes de seguir.",
        f"- Earnings: ROAS estimado menor a {RULES['roas_cut']:.0f} % a los 7 días, bajar; {RULES['roas_scale']:.0f} % o más, subir 20-30 %.",
        "",
        "Análisis: exportar el reporte de Ads Manager a CSV y correr `python tools/campaigns.py report <archivo.csv>`.",
        "",
        "## Seguimiento",
        "",
        "| Fecha | Etapa | Gasto USD | Impresiones | Clics | CTR | Jugadas | CPP | D1 anuncio | Decisión |",
        "|---|---|---|---|---|---|---|---|---|---|",
        "| | | | | | | | | | |",
    ]
    return "\n".join(lines) + "\n"


def write_plan(plan: dict, out_dir: Path) -> tuple:
    out_dir.mkdir(parents=True, exist_ok=True)
    base = out_dir / f"{plan['campaigns'][0]['schedule']['startTime'][:10]}-{slug(plan['name'])}"
    md, js = base.with_suffix(".md"), base.with_suffix(".json")
    md.write_text(plan_markdown(plan), encoding="utf-8")
    js.write_text(json.dumps(plan, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    return md, js


# --- Ads API -------------------------------------------------------------------------------------

def ads_sender(key: str):
    def send(method: str, path: str, body=None, headers=None):
        data = json.dumps(body).encode("utf-8") if body is not None else None
        h = {"x-api-key": key, "Content-Type": "application/json", "Accept": "application/json"}
        h.update(headers or {})
        req = urllib.request.Request(ADS_API + path, data=data, method=method, headers=h)
        try:
            with urllib.request.urlopen(req, timeout=60) as r:
                return r.status, json.loads(r.read() or b"null")
        except urllib.error.HTTPError as e:
            raw = e.read()
            try:
                return e.code, json.loads(raw) if raw else None
            except ValueError:
                return e.code, {"detail": raw.decode("utf-8", "replace")[:300]}
        except urllib.error.URLError as e:
            raise CampaignError(f"sin conexión con la Ads API: {e.reason}") from None
    return send


def api_error(status: int, body) -> str:
    if isinstance(body, dict):
        codes = ", ".join(e.get("code", "") for e in body.get("errors", []) if isinstance(e, dict))
        return f"HTTP {status} {body.get('title', '')} {body.get('detail', '')} {codes}".strip()
    return f"HTTP {status}"


def campaign_request(c: dict, universe: str) -> dict:
    if not universe:
        raise CampaignError("falta universeId en el plan (--universe al generar o editar el JSON)")
    if not c.get("creativeAssetIds"):
        raise CampaignError(f"{c['name']}: sin creativeAssetIds (subir las imágenes y anotar sus ids)")
    body = {"name": c["name"], "objective": c.get("apiObjective", "ENGAGEMENT"), "paymentType": c["paymentType"],
            "targetUniverseId": str(universe), "creativeAssetIds": [str(a) for a in c["creativeAssetIds"]],
            "budget": {"type": c["budget"]["type"], "amountMicros": str(c["budget"]["amountMicros"])},
            "schedule": {"startTime": c["schedule"]["startTime"], "durationInDays": int(c["schedule"]["durationInDays"])}}
    if c.get("targeting"):
        body["targeting"] = c["targeting"]
    return body


def idempotency_key(plan: dict, c: dict) -> str:
    return str(uuid.uuid5(PLAN_NAMESPACE, f"{plan['planId']}|{c['index']}|{c['schedule']['startTime']}"))


def create(plan: dict, send, yes: bool, only=None, out=print) -> dict:
    universe = plan.get("universeId", "")
    status, options = send("GET", f"/campaign-options?universeId={universe}") if yes else (200, None)
    if yes and status != 200:
        raise CampaignError(f"campaign-options: {api_error(status, options)} (¿el juego es publicitable con esta clave?)")
    for c in plan["campaigns"]:
        if only is not None and c["index"] != only:
            continue
        if c.get("campaignId"):
            out(f"  [ya creada] {c['name']}: {c['campaignId']}")
            continue
        body = campaign_request(c, universe)
        max_spend = c["budget"]["usd"] * c["schedule"]["durationInDays"]
        if not yes:
            out(f"  [simulado] {c['name']}: {c['budget']['usd']:.2f} USD/día × {c['schedule']['durationInDays']} días "
                f"= hasta {max_spend:.2f} USD. Pedido:\n{json.dumps(body, indent=2)}")
            continue
        status, res = send("POST", "/campaigns", body, {"x-idempotency-key": idempotency_key(plan, c)})
        if status not in (200, 201) or not isinstance(res, dict) or not res.get("id"):
            raise CampaignError(f"{c['name']}: {api_error(status, res)}")
        c["campaignId"] = res["id"]
        out(f"  [creada] {c['name']}: id {res['id']}, {res.get('status')} / {res.get('deliveryStatus')} "
            f"(hasta {max_spend:.2f} USD). Revisar en Ads Manager que el objetivo sea el del plan: la API v1 solo crea ENGAGEMENT.")
    return plan


def status(ids, send) -> list:
    code, res = send("POST", "/campaigns:batchGetStatus", {"campaignIds": [str(i) for i in ids]})
    if code != 200 or not isinstance(res, dict):
        raise CampaignError(f"batchGetStatus: {api_error(code, res)}")
    rows = [(s.get("id"), s.get("status"), s.get("deliveryStatus"), ", ".join(s.get("deliveryStatusReasons", []) or []))
            for s in res.get("statuses", [])]
    rows += [(f.get("id"), "NO ENCONTRADA", f.get("reason", ""), "") for f in res.get("failures", [])]
    return rows


def patch(campaign_id: str, change: dict, send) -> dict:
    code, res = send("PATCH", f"/campaigns/{campaign_id}", change)
    if code != 200:
        raise CampaignError(f"PATCH {campaign_id}: {api_error(code, res)}")
    return res


# --- Reporte -------------------------------------------------------------------------------------

def number(text) -> float:
    """'$1,234.5' / '3.2%' / '12.5K' / '1.2M' -> float. Vacío o '-' -> 0."""
    if text is None:
        return 0.0
    s = str(text).strip().replace(",", "").replace("$", "").replace("R$", "").replace("%", "")
    if s in ("", "-", "—"):
        return 0.0
    mult = 1.0
    if s[-1:].upper() in ("K", "M", "B"):
        mult = {"K": 1e3, "M": 1e6, "B": 1e9}[s[-1].upper()]
        s = s[:-1]
    try:
        return float(s) * mult
    except ValueError:
        return 0.0


def columns(header: list) -> dict:
    """Asigna columnas por nombre aproximado: el formato de exportación no está documentado."""
    found = {}
    for i, raw in enumerate(header):
        h = raw.strip().lower()
        if "creative" in h or "asset" in h or "thumbnail" in h or h == "ad":
            found.setdefault("creative", i)
        elif "campaign" in h or h == "name":
            found.setdefault("name", i)
        elif "spent" in h or "spend" in h or "amount" in h:
            found.setdefault("spent", i)
        elif "impression" in h:
            found.setdefault("impressions", i)
        elif "click" in h and "rate" not in h and "ctr" not in h and "cost" not in h:
            found.setdefault("clicks", i)
        elif "playtime" in h or "play time" in h:
            found.setdefault("playtime", i)
        elif "earning" in h or "revenue" in h:
            found.setdefault("earnings", i)
        elif "play" in h and "rate" not in h and "cost" not in h and "cpp" not in h:
            found.setdefault("plays", i)
    missing = [k for k in ("spent", "impressions") if k not in found]
    if missing:
        raise CampaignError(f"el CSV no tiene columnas de {', '.join(missing)}: encabezados {header}")
    return found


def analyze(rows: list) -> dict:
    """rows: dicts con name, creative, spent, impressions, clicks, plays, earnings (USD)."""
    for r in rows:
        imp, clk, plays, spent = r["impressions"], r["clicks"], r["plays"], r["spent"]
        r["ctr"] = clk / imp * 100 if imp else 0.0
        r["play_rate"] = plays / imp * 100 if imp else 0.0
        r["cpm"] = spent / imp * 1000 if imp else 0.0
        r["cpp"] = spent / plays if plays else None
        r["roas"] = r["earnings"] / spent * 100 if spent and r.get("earnings") else None
    cpps = [r["cpp"] for r in rows if r["cpp"]]
    median_cpp = statistics.median(cpps) if cpps else None
    for r in rows:
        flags = []
        if r["impressions"] >= RULES["min_impressions"] and r["ctr"] < RULES["ctr_min"]:
            flags.append(f"CTR {r['ctr']:.2f} % < {RULES['ctr_min']} %: apagar y reemplazar la miniatura")
        elif r["ctr"] >= RULES["ctr_great"]:
            flags.append("CTR excelente: hacer variantes de esta miniatura")
        elif r["ctr"] >= RULES["ctr_good"]:
            flags.append("CTR bueno")
        if median_cpp and r["cpp"] and len(cpps) >= 3 and r["cpp"] > RULES["cpp_factor"] * median_cpp:
            flags.append(f"CPP {r['cpp']:.3f} > {RULES['cpp_factor']:.0f}× la mediana ({median_cpp:.3f})")
        if r["clicks"] > 200 and r["plays"] < r["clicks"] * 0.05:
            flags.append("muchos clics y casi ninguna jugada: esperar 48 h (atribución) o revisar la página del juego")
        if r["roas"] is not None:
            if r["roas"] < RULES["roas_cut"]:
                flags.append(f"ROAS {r['roas']:.0f} % < {RULES['roas_cut']:.0f} %: bajar presupuesto")
            elif r["roas"] >= RULES["roas_scale"]:
                flags.append(f"ROAS {r['roas']:.0f} %: subir 20-30 %")
        r["flags"] = flags
    total = {k: sum(r[k] for r in rows) for k in ("spent", "impressions", "clicks", "plays", "earnings")}
    total["ctr"] = total["clicks"] / total["impressions"] * 100 if total["impressions"] else 0.0
    total["cpp"] = total["spent"] / total["plays"] if total["plays"] else None
    total["cpm"] = total["spent"] / total["impressions"] * 1000 if total["impressions"] else 0.0
    return {"rows": rows, "total": total, "median_cpp": median_cpp}


def read_csv(path: Path) -> list:
    with open(path, newline="", encoding="utf-8-sig") as f:
        data = list(csv.reader(f))
    if not data:
        raise CampaignError("CSV vacío")
    col = columns(data[0])
    rows = []
    for line in data[1:]:
        if not any(cell.strip() for cell in line):
            continue
        get = lambda k: line[col[k]] if k in col and col[k] < len(line) else ""  # noqa: E731
        name = get("name") or get("creative") or "(sin nombre)"
        if name.strip().lower() in ("total", "totals"):
            continue
        rows.append({"name": name, "creative": get("creative"), "spent": number(get("spent")),
                     "impressions": number(get("impressions")), "clicks": number(get("clicks")),
                     "plays": number(get("plays")), "earnings": number(get("earnings"))})
    return rows


def report_markdown(result: dict) -> str:
    def opt(value, fmt: str) -> str:
        return "" if value is None else format(value, fmt)

    t = result["total"]
    lines = ["| Campaña / creatividad | Gasto | Impresiones | Clics | CTR | Jugadas | Tasa de juego | CPM | CPP | ROAS | Lectura |",
             "|---|---|---|---|---|---|---|---|---|---|---|"]
    for r in result["rows"]:
        label = r["name"] + (f" / {r['creative']}" if r["creative"] and r["creative"] != r["name"] else "")
        roas = opt(r["roas"], ".0f")
        lines.append(f"| {label} | {r['spent']:.2f} | {r['impressions']:,.0f} | {r['clicks']:,.0f} | {r['ctr']:.2f} % | "
                     f"{r['plays']:,.0f} | {r['play_rate']:.2f} % | {r['cpm']:.3f} | {opt(r['cpp'], '.3f')} | "
                     f"{roas + ' %' if roas else ''} | {'; '.join(r['flags'])} |")
    lines.append(f"| **Total** | {t['spent']:.2f} | {t['impressions']:,.0f} | {t['clicks']:,.0f} | {t['ctr']:.2f} % | "
                 f"{t['plays']:,.0f} | | {t['cpm']:.3f} | {opt(t['cpp'], '.3f')} | | |")
    lines.append("")
    lines.append("Rangos de referencia (DevForum 2026): CTR normal 2-2,5 %, bueno 3 %, excelente 4 %; "
                 "6 000-10 000 impresiones por dólar. Jugadas y ganancias tardan hasta 48 h y se atribuyen por 30 días.")
    return "\n".join(lines)


def thumbs(send, universe: str, days: int, sleep=None) -> list:
    start, end = analytics.window(days)
    kwargs = {"sleep": sleep} if sleep else {}
    per = {}
    for metric in ("ThumbnailImpressions", "ThumbnailQualifiedPlays"):
        for series in analytics.query(send, universe, metric, "OneDay", start, end, ["ThumbnailAsset"], **kwargs):
            asset = next((b.get("value") for b in series.get("breakdowns", []) if b.get("dimension") == "ThumbnailAsset"), None)
            asset = asset or "(sin id)"
            total = sum(p.get("value") or 0 for p in series.get("dataPoints", []))
            per.setdefault(asset, {"impressions": 0, "plays": 0})
            per[asset]["impressions" if metric == "ThumbnailImpressions" else "plays"] += total
    rows = [(a, v["impressions"], v["plays"], v["plays"] / v["impressions"] * 100 if v["impressions"] else 0.0)
            for a, v in per.items()]
    return sorted(rows, key=lambda r: r[3], reverse=True)


# --- CLI -----------------------------------------------------------------------------------------

def need_key() -> str:
    key = os.environ.get(ADS_KEY_ENV, "")
    if not key:
        raise CampaignError(f"Falta {ADS_KEY_ENV}: clave de usuario con ad.campaign:read, ad.campaign:write y ad.billing:read")
    return key


def main(argv=None) -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("plan")
    p.add_argument("--game", required=True)
    p.add_argument("--goal", default="launch", choices=["launch", "update", "lapsed", "earnings"])
    p.add_argument("--budget", type=float, required=True, help="presupuesto total en USD")
    p.add_argument("--start", help="YYYY-MM-DD (por defecto el próximo jueves)")
    p.add_argument("--name", default="")
    p.add_argument("--universe", default="")
    p.add_argument("--kids-pending", action="store_true", help="el juego todavía no llega a menores de 16")
    p.add_argument("--countries", default="")
    p.add_argument("--devices", default="")
    p.add_argument("--payment", default="ADS_CREDIT", choices=["ADS_CREDIT", "CREDIT_CARD", "INVOICE"])
    c = sub.add_parser("create")
    c.add_argument("plan")
    c.add_argument("--only", type=int)
    c.add_argument("--yes", action="store_true", help="crear de verdad (gasta dinero)")
    s = sub.add_parser("status")
    s.add_argument("ids", nargs="+")
    t = sub.add_parser("set")
    t.add_argument("id")
    group = t.add_mutually_exclusive_group(required=True)
    group.add_argument("--pause", action="store_true")
    group.add_argument("--resume", action="store_true")
    group.add_argument("--cancel", action="store_true")
    group.add_argument("--daily", type=float)
    t.add_argument("--yes", action="store_true")
    r = sub.add_parser("report")
    r.add_argument("csv")
    r.add_argument("--json", action="store_true")
    h = sub.add_parser("thumbs")
    h.add_argument("--universe", required=True)
    h.add_argument("--days", type=int, default=7)
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "plan":
            start = dt.date.fromisoformat(args.start) if args.start else next_thursday(dt.date.today())
            plan = build_plan(args.game, args.goal, args.budget, start, args.name, args.universe, args.kids_pending,
                              [x for x in args.countries.split(",") if x], [x for x in args.devices.split(",") if x],
                              args.payment)
            md, js = write_plan(plan, Path(args.game) / "docs" / "campanas")
            print(f"  [ok] {md}\n  [ok] {js}")
            return 0
        if args.cmd == "create":
            plan_path = Path(args.plan)
            plan = json.loads(plan_path.read_text(encoding="utf-8"))
            send = ads_sender(need_key()) if args.yes else None
            create(plan, send, args.yes, args.only)
            if args.yes:
                plan_path.write_text(json.dumps(plan, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
            return 0
        if args.cmd == "status":
            for row in status(args.ids, ads_sender(need_key())):
                print("  " + " | ".join(str(x) for x in row))
            return 0
        if args.cmd == "set":
            change = ({"status": "PAUSED"} if args.pause else {"status": "ACTIVE"} if args.resume else
                      {"status": "CANCELLED"} if args.cancel else {"budget": {"amountMicros": str(int(round(args.daily * 1_000_000)))}})
            if not args.yes:
                print(f"  [simulado] PATCH /campaigns/{args.id} {json.dumps(change)} (agregar --yes para aplicarlo)")
                return 0
            res = patch(args.id, change, ads_sender(need_key()))
            print(f"  [ok] {res.get('id', args.id)}: {res.get('status')} / {res.get('deliveryStatus')}")
            return 0
        if args.cmd == "report":
            result = analyze(read_csv(Path(args.csv)))
            print(json.dumps(result, indent=2, ensure_ascii=False) if args.json else report_markdown(result))
            return 0
        if args.cmd == "thumbs":
            key = os.environ.get(analytics.API_KEY_ENV)
            if not key:
                raise CampaignError(f"Falta {analytics.API_KEY_ENV} (universe.analytics:read)")
            print("| Miniatura (assetId) | Impresiones | Jugadas que cuentan | QPTR |\n|---|---|---|---|")
            for asset, imp, plays, qptr in thumbs(analytics.http_sender(key), args.universe, args.days):
                print(f"| {asset} | {imp:,.0f} | {plays:,.0f} | {qptr:.2f} % |")
            return 0
        return selftest()
    except (CampaignError, analytics.AnalyticsError, OSError, ValueError) as e:
        print(e, file=sys.stderr)
        return 1


def selftest() -> int:
    import tempfile

    assert next_thursday(dt.date(2026, 10, 28)) == dt.date(2026, 10, 29)  # miércoles -> jueves
    assert next_thursday(dt.date(2026, 10, 29)) == dt.date(2026, 11, 5)   # jueves -> el siguiente
    plan = build_plan("games/demo", "launch", 300, dt.date(2026, 11, 5), "Demo", "123", kids_pending=True,
                      countries=["US"], devices=["PHONE"])
    stages = [c["stage"] for c in plan["campaigns"]]
    assert stages == ["humo", "miniaturas", "kids", "empuje"], stages
    assert abs(sum(c["totalUsd"] for c in plan["campaigns"]) - 300) < 0.05
    push = plan["campaigns"][-1]
    assert dt.date.fromisoformat(push["schedule"]["startTime"][:10]).weekday() == 3, push["schedule"]
    assert push["budget"]["amountMicros"] == str(int(round(push["budget"]["usd"] * 1e6)))
    assert len(plan["campaigns"][1]["creatives"]) == 10
    md = plan_markdown(plan)
    assert "## Etapas" in md and "`ad_empuje`" in md and "| Fecha |" in md
    assert [c["stage"] for c in build_plan("g", "launch", 100, dt.date(2026, 11, 5))["campaigns"]] == ["humo", "miniaturas", "empuje"]

    sent = []

    def fake(method, path, body=None, headers=None):
        sent.append((method, path, body, headers))
        if path.startswith("/campaign-options"):
            return 200, {"eligibility": "ELIGIBLE"}
        if path == "/campaigns":
            return 200, {"id": "999", "status": "ACTIVE", "deliveryStatus": "IN_REVIEW"}
        if path == "/campaigns:batchGetStatus":
            return 200, {"statuses": [{"id": "999", "status": "ACTIVE", "deliveryStatus": "SERVING",
                                       "deliveryStatusReasons": ["LEARNING"]}], "failures": [{"id": "5", "reason": "NOT_FOUND"}]}
        if method == "PATCH":
            return 200, {"id": "999", "status": body.get("status", "ACTIVE"), "deliveryStatus": "NOT_SERVING"}
        raise AssertionError(path)

    try:
        create(plan, fake, yes=True, only=0, out=lambda *_: None)
        raise AssertionError("debía pedir creativeAssetIds")
    except CampaignError as e:
        assert "creativeAssetIds" in str(e)
    plan["campaigns"][0]["creativeAssetIds"] = ["111", "222"]
    sent.clear()
    lines = []
    create(plan, None, yes=False, only=0, out=lines.append)
    assert "[simulado]" in lines[0] and not sent, lines
    create(plan, fake, yes=True, only=0, out=lambda *_: None)
    post = next(s for s in sent if s[1] == "/campaigns")
    assert post[2]["budget"]["amountMicros"].isdigit() and post[2]["objective"] == "ENGAGEMENT"
    assert post[2]["targeting"] == {"countries": ["US"], "devices": ["PHONE"]}
    assert post[3]["x-idempotency-key"] == idempotency_key(plan, plan["campaigns"][0])
    assert plan["campaigns"][0]["campaignId"] == "999"
    rows = status(["999", "5"], fake)
    assert rows[0] == ("999", "ACTIVE", "SERVING", "LEARNING") and rows[1][1] == "NO ENCONTRADA", rows
    assert patch("999", {"status": "PAUSED"}, fake)["status"] == "PAUSED"

    assert number("$1,234.50") == 1234.5 and number("3.2%") == 3.2 and number("12.5K") == 12500 and number("-") == 0
    with tempfile.TemporaryDirectory() as tmp:
        path = Path(tmp) / "r.csv"
        path.write_text(
            "Campaign,Creative,Amount Spent (USD),Impressions,Clicks,CTR,Plays,CPP,Earnings (USD)\n"
            "Launch,robo-01,20.00,40000,600,1.5%,300,0.07,0\n"
            "Launch,numero-02,20.00,30000,1350,4.5%,700,0.03,30\n"
            "Launch,objeto-03,20.00,25000,900,3.6%,30,0.67,5\n"
            "Launch,mas-uno-04,20.00,26000,800,3.1%,500,0.04,0\n"
            "Total,,80.00,121000,3650,,1530,,35\n", encoding="utf-8")
        result = analyze(read_csv(path))
        rows = {r["creative"]: r for r in result["rows"]}
        assert len(rows) == 4, rows.keys()
        assert any("apagar" in f for f in rows["robo-01"]["flags"]), rows["robo-01"]["flags"]
        assert any("excelente" in f for f in rows["numero-02"]["flags"])
        assert any("Mediana" in f or "mediana" in f for f in rows["objeto-03"]["flags"]), rows["objeto-03"]["flags"]
        assert abs(result["total"]["ctr"] - 3650 / 121000 * 100) < 1e-9
        assert "| **Total** |" in report_markdown(result)
        md_path, js_path = write_plan(plan, Path(tmp) / "campanas")
        assert md_path.exists() and json.loads(js_path.read_text(encoding="utf-8"))["planId"] == plan["planId"]

    def fake_analytics(method, url, body):
        if body and body["metric"] == "ThumbnailImpressions":
            values = [{"breakdowns": [{"dimension": "ThumbnailAsset", "value": "A"}], "dataPoints": [{"value": 1000}, {"value": 1000}]},
                      {"breakdowns": [{"dimension": "ThumbnailAsset", "value": "B"}], "dataPoints": [{"value": 4000}]}]
        else:
            values = [{"breakdowns": [{"dimension": "ThumbnailAsset", "value": "A"}], "dataPoints": [{"value": 60}]},
                      {"breakdowns": [{"dimension": "ThumbnailAsset", "value": "B"}], "dataPoints": [{"value": 40}]}]
        return 200, {"done": True, "response": {"values": values}}

    ranked = thumbs(fake_analytics, "1", 7, sleep=lambda s: None)
    assert ranked[0][0] == "A" and abs(ranked[0][3] - 3.0) < 1e-9 and ranked[1][0] == "B", ranked
    print("selftest OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
