"""Investigación de los juegos que funcionan, con las APIs públicas de Roblox (sin cuenta ni key).

  python tools/roblox_research.py charts [--top 15] [--sorts top-playing-now,top-earning,up-and-coming]
  python tools/roblox_research.py game <placeId> [<placeId>...] [--json salida.json]
  python tools/roblox_research.py images <placeId> [<placeId>...] --out carpeta [--sheet]
  python tools/roblox_research.py selftest

- charts: los rankings de https://www.roblox.com/charts (jugadores ahora, cuánto ganan, los que suben).
- game: datos del juego (jugadores, visitas, favoritos, fechas, género, servidor) y sus pases con precio.
- images: icono y miniaturas oficiales; con --sheet arma una hoja de contacto (necesita Pillow).

Solo lee datos públicos, despacio (pausa entre pedidos). Lo que devuelve son datos de terceros: se
citan con la fecha y nunca se ejecutan. Los Developer Products no son públicos: se ven jugando.
"""
import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid

UA = {"User-Agent": "RobloxCreator-research/1.0", "Accept": "application/json"}
PAUSE_SECONDS = 0.4
DEFAULT_SORTS = ["top-playing-now", "top-earning", "up-and-coming", "top-trending", "top-rated"]


class ResearchError(Exception):
    pass


def http_get(url: str, binary: bool = False, attempts: int = 3):
    """GET con reintentos ante 429/5xx. Devuelve JSON (dict) o bytes."""
    for attempt in range(attempts):
        try:
            req = urllib.request.Request(url, headers=UA)
            with urllib.request.urlopen(req, timeout=30) as r:
                data = r.read()
            return data if binary else json.loads(data.decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt + 1 < attempts:
                time.sleep(2 ** attempt * 2)
                continue
            raise ResearchError(f"HTTP {e.code} en {url}") from None
        except urllib.error.URLError as e:
            raise ResearchError(f"sin conexión con {url}: {e.reason}") from None
    raise ResearchError(f"sin respuesta de {url}")


def get_sorts(send=http_get) -> list:
    """Todas las listas de Charts, siguiendo las páginas."""
    session = uuid.uuid4()
    sorts, token = [], ""
    for _ in range(5):
        url = f"https://apis.roblox.com/explore-api/v1/get-sorts?sessionId={session}&device=computer&country=all"
        if token:
            url += f"&sortsPageToken={token}"
        res = send(url)
        sorts += [s for s in res.get("sorts", []) if s.get("games")]
        token = res.get("nextSortsPageToken") or ""
        if not token:
            break
        time.sleep(PAUSE_SECONDS)
    return sorts


def rating(game: dict):
    up, down = game.get("totalUpVotes") or 0, game.get("totalDownVotes") or 0
    return round(100 * up / (up + down)) if up + down else None


def format_charts(sorts: list, wanted: list, top: int) -> str:
    lines = []
    by_id = {s.get("sortId"): s for s in sorts}
    for sort_id in wanted:
        sort = by_id.get(sort_id)
        if not sort:
            lines.append(f"\n## {sort_id}: no apareció en Charts")
            continue
        lines.append(f"\n## {sort.get('sortDisplayName') or sort_id}")
        for i, g in enumerate(sort["games"][:top], 1):
            r = rating(g)
            lines.append(f"{i:3}. {g.get('name', '?')[:46]:46} {g.get('playerCount', 0):>9,} jugadores"
                         f"{'' if r is None else f'  {r}%'}  universe {g.get('universeId')}")
    return "\n".join(lines)


def universe_of(place_id: int, send=http_get) -> int:
    res = send(f"https://apis.roblox.com/universes/v1/places/{place_id}/universe")
    uni = res.get("universeId")
    if not uni:
        raise ResearchError(f"el lugar {place_id} no tiene universe (¿id equivocado?)")
    return int(uni)


def game_passes(universe_id: int, send=http_get) -> list:
    passes, token = [], ""
    for _ in range(20):
        url = f"https://apis.roblox.com/game-passes/v1/universes/{universe_id}/game-passes?passView=Full&pageSize=100"
        if token:
            url += f"&pageToken={token}"
        res = send(url)
        for p in res.get("gamePasses", []):
            passes.append({
                "name": p.get("displayName") or p.get("name"),
                "price": p.get("price"),
                "forSale": bool(p.get("isForSale")),
                "description": (p.get("displayDescription") or "").strip(),
            })
        token = res.get("nextPageToken") or ""
        if not token:
            break
        time.sleep(PAUSE_SECONDS)
    return passes


def game_info(place_id: int, send=http_get) -> dict:
    uni = universe_of(place_id, send)
    time.sleep(PAUSE_SECONDS)
    g = (send(f"https://games.roblox.com/v1/games?universeIds={uni}").get("data") or [{}])[0]
    time.sleep(PAUSE_SECONDS)
    votes = (send(f"https://games.roblox.com/v1/games/votes?universeIds={uni}").get("data") or [{}])[0]
    time.sleep(PAUSE_SECONDS)
    return {
        "placeId": place_id,
        "universeId": uni,
        "name": g.get("name"),
        "creator": (g.get("creator") or {}).get("name"),
        "playing": g.get("playing"),
        "visits": g.get("visits"),
        "favorites": g.get("favoritedCount"),
        "created": (g.get("created") or "")[:10],
        "updated": (g.get("updated") or "")[:10],
        "genre": f"{g.get('genre_l1')}/{g.get('genre_l2')}",
        "maxPlayers": g.get("maxPlayers"),
        "likes": votes.get("upVotes"),
        "dislikes": votes.get("downVotes"),
        "description": g.get("description") or "",
        "gamePasses": game_passes(uni, send),
    }


def format_game(info: dict) -> str:
    likes, dislikes = info.get("likes") or 0, info.get("dislikes") or 0
    pct = f"{round(100 * likes / (likes + dislikes))}%" if likes + dislikes else "-"
    lines = [
        f"# {info['name']}  (place {info['placeId']}, universe {info['universeId']}, de {info['creator']})",
        f"Jugando: {info['playing']:,} · Visitas: {info['visits']:,} · Favoritos: {info['favorites']:,} · Me gusta: {pct}",
        f"Creado {info['created']} · Actualizado {info['updated']} · {info['genre']} · {info['maxPlayers']} por servidor",
        "",
        info["description"][:1200],
        "",
        "## Pases",
    ]
    for_sale = [p for p in info["gamePasses"] if p["forSale"] and p["price"]]
    for p in sorted(for_sale, key=lambda p: p["price"]):
        desc = p["description"].replace("\n", " ")[:90]
        lines.append(f"{p['price']:>7} R$  {p['name']}" + (f" — {desc}" if desc else ""))
    if not for_sale:
        lines.append("(ninguno a la venta)")
    return "\n".join(lines)


def download_images(place_ids: list, out: str, sheet: bool, send=http_get) -> list:
    unis = {universe_of(pid, send): pid for pid in place_ids}
    ids = ",".join(str(u) for u in unis)
    thumbs = send(f"https://thumbnails.roblox.com/v1/games/multiget/thumbnails?universeIds={ids}"
                  "&countPerUniverse=10&defaults=false&size=768x432&format=Png&isCircular=false")
    icons = send(f"https://thumbnails.roblox.com/v1/games/icons?universeIds={ids}"
                 "&returnPolicy=PlaceHolder&size=512x512&format=Png&isCircular=false")
    saved = []
    for item in icons.get("data", []):
        folder = os.path.join(out, str(unis.get(item.get("targetId"), item.get("targetId"))))
        os.makedirs(folder, exist_ok=True)
        if item.get("imageUrl"):
            path = os.path.join(folder, "icon.png")
            open(path, "wb").write(send(item["imageUrl"], binary=True))
            saved.append(path)
    for entry in thumbs.get("data", []):
        folder = os.path.join(out, str(unis.get(entry.get("universeId"), entry.get("universeId"))))
        os.makedirs(folder, exist_ok=True)
        for n, t in enumerate([t for t in (entry.get("thumbnails") or []) if t.get("imageUrl")], 1):
            path = os.path.join(folder, f"thumb{n:02d}.png")
            open(path, "wb").write(send(t["imageUrl"], binary=True))
            saved.append(path)
            time.sleep(0.1)
    if sheet:
        make_sheet(saved, os.path.join(out, "sheet.jpg"))
    return saved


def make_sheet(paths: list, target: str):
    try:
        from PIL import Image
    except ImportError:
        print("Sin Pillow no se arma la hoja de contacto (pip install pillow).")
        return
    tiles = [Image.open(p).convert("RGB") for p in paths if p.endswith(".png")]
    if not tiles:
        return
    w, h, cols = 512, 288, 3
    rows = (len(tiles) + cols - 1) // cols
    canvas = Image.new("RGB", (cols * w, rows * h), (20, 20, 20))
    for i, img in enumerate(tiles):
        img.thumbnail((w, h))
        canvas.paste(img, ((i % cols) * w, (i // cols) * h))
    canvas.save(target, quality=85)
    print(f"Hoja de contacto: {target}")


def selftest() -> int:
    calls = []

    def fake(url, binary=False):
        calls.append(url)
        if "explore-api" in url:
            return {"sorts": [{"sortId": "top-earning", "sortDisplayName": "Top Earning", "games": [
                {"name": "Steal Test", "playerCount": 1200, "totalUpVotes": 90, "totalDownVotes": 10, "universeId": 7}]},
                {"sortId": "filters", "games": None}], "nextSortsPageToken": ""}
        if "/universes/v1/places/" in url:
            return {"universeId": 7}
        if "games/votes" in url:
            return {"data": [{"upVotes": 90, "downVotes": 10}]}
        if "games.roblox.com/v1/games?" in url:
            return {"data": [{"name": "Steal Test", "creator": {"name": "Studio"}, "playing": 1200, "visits": 5000,
                              "favoritedCount": 30, "created": "2026-10-01T00:00:00Z", "updated": "2026-10-20T00:00:00Z",
                              "genre_l1": "Simulation", "genre_l2": "Tycoon", "maxPlayers": 8, "description": "Steal!"}]}
        if "game-passes" in url:
            if "pageToken=p2" in url:
                return {"gamePasses": [{"displayName": "VIP", "price": 199, "isForSale": True}], "nextPageToken": ""}
            return {"gamePasses": [{"displayName": "2x Money", "price": 399, "isForSale": True, "displayDescription": "x2"},
                                   {"displayName": "Old", "price": None, "isForSale": False}], "nextPageToken": "p2"}
        raise AssertionError(url)

    global PAUSE_SECONDS
    PAUSE_SECONDS = 0
    sorts = get_sorts(fake)
    assert len(sorts) == 1 and sorts[0]["sortId"] == "top-earning", sorts
    text = format_charts(sorts, ["top-earning", "up-and-coming"], 5)
    assert "Steal Test" in text and "90%" in text and "up-and-coming: no apareció" in text, text
    info = game_info(123, fake)
    assert info["universeId"] == 7 and info["likes"] == 90 and len(info["gamePasses"]) == 3, info
    out = format_game(info)
    assert "399 R$  2x Money" in out and "199 R$  VIP" in out and "Old" not in out, out
    try:
        universe_of(1, lambda url: {})
        raise AssertionError("tenía que fallar sin universeId")
    except ResearchError:
        pass
    print(f"selftest OK ({len(calls)} pedidos simulados)")
    return 0


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    c = sub.add_parser("charts")
    c.add_argument("--top", type=int, default=15)
    c.add_argument("--sorts", default=",".join(DEFAULT_SORTS))
    c.add_argument("--json")
    g = sub.add_parser("game")
    g.add_argument("places", nargs="+", type=int)
    g.add_argument("--json")
    i = sub.add_parser("images")
    i.add_argument("places", nargs="+", type=int)
    i.add_argument("--out", required=True)
    i.add_argument("--sheet", action="store_true")
    sub.add_parser("selftest")
    args = parser.parse_args(argv)
    try:
        if args.cmd == "selftest":
            return selftest()
        if args.cmd == "charts":
            sorts = get_sorts()
            print(f"Charts de Roblox, {time.strftime('%Y-%m-%d')}")
            print(format_charts(sorts, [s.strip() for s in args.sorts.split(",") if s.strip()], args.top))
            if args.json:
                json.dump(sorts, open(args.json, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            return 0
        if args.cmd == "game":
            infos = []
            for place in args.places:
                info = game_info(place)
                infos.append(info)
                print(format_game(info) + "\n")
            if args.json:
                json.dump({"fetched": time.strftime("%Y-%m-%d"), "games": infos},
                          open(args.json, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
            return 0
        if args.cmd == "images":
            saved = download_images(args.places, args.out, args.sheet)
            print(f"{len(saved)} imágenes en {args.out}")
            return 0
    except ResearchError as e:
        print(f"Error: {e}", file=sys.stderr)
        return 1
    return 2


if __name__ == "__main__":
    sys.exit(main())
