#!/usr/bin/env python3
"""
update_mundial.py

Actualiza data/mundial2026.json con los partidos finalizados consultando la
API pública de ESPN (sin autenticación, sin claves, sin límites de cuota
relevantes para uso personal). Preserva los nombres en español y los datos
curados (canales TV, flag de España) — solo añade `done`, `result` y
`details` (alineaciones + eventos) para los partidos finalizados.

Pensado para ejecutarse desde GitHub Actions
(`.github/workflows/update-mundial.yml`) cada 30 min.

Uso local:
    python3 scripts/update_mundial.py
"""

from __future__ import annotations

import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import requests

MADRID_TZ = ZoneInfo("Europe/Madrid")


# -- Configuración --------------------------------------------------------

ESPN_BASE = "https://site.api.espn.com/apis/site/v2/sports/soccer/fifa.world"
JSON_PATH = Path("data/mundial2026.json")
REQUEST_TIMEOUT = 30


# -- Mapeo de nombres de equipo (ESPN inglés → app español) --------------

TEAM_NAME_MAP: dict[str, str] = {
    "Mexico": "México",
    "South Africa": "Sudáfrica",
    "Korea Republic": "Corea del Sur",
    "South Korea": "Corea del Sur",
    "Czech Republic": "Rep. Checa",
    "Czechia": "Rep. Checa",
    "Canada": "Canadá",
    "Bosnia and Herzegovina": "Bosnia Herz.",
    "Bosnia-Herzegovina": "Bosnia Herz.",
    "Bosnia & Herzegovina": "Bosnia Herz.",
    "USA": "EE.UU.",
    "United States": "EE.UU.",
    "Paraguay": "Paraguay",
    "Qatar": "Qatar",
    "Switzerland": "Suiza",
    "Brazil": "Brasil",
    "Morocco": "Marruecos",
    "Haiti": "Haití",
    "Scotland": "Escocia",
    "Australia": "Australia",
    "Turkey": "Turquía",
    "Türkiye": "Turquía",
    "Germany": "Alemania",
    "Curacao": "Curaçao",
    "Curaçao": "Curaçao",
    "Netherlands": "Países Bajos",
    "Japan": "Japón",
    "Ivory Coast": "C. de Marfil",
    "Côte d'Ivoire": "C. de Marfil",
    "Ecuador": "Ecuador",
    "Sweden": "Suecia",
    "Tunisia": "Túnez",
    "Spain": "🇪🇸 España",
    "Cape Verde": "Cabo Verde",
    "Cabo Verde": "Cabo Verde",
    "Belgium": "Bélgica",
    "Egypt": "Egipto",
    "Saudi Arabia": "Arabia Saudí",
    "Uruguay": "Uruguay",
    "Iran": "Irán",
    "IR Iran": "Irán",
    "New Zealand": "Nueva Zelanda",
    "France": "Francia",
    "Senegal": "Senegal",
    "Iraq": "Irak",
    "Norway": "Noruega",
    "Argentina": "Argentina",
    "Algeria": "Argelia",
    "Austria": "Austria",
    "Jordan": "Jordania",
    "Portugal": "Portugal",
    "DR Congo": "R.D. Congo",
    "Democratic Republic of the Congo": "R.D. Congo",
    "Congo DR": "R.D. Congo",
    "England": "Inglaterra",
    "Croatia": "Croacia",
    "Ghana": "Ghana",
    "Panama": "Panamá",
    "Uzbekistan": "Uzbekistán",
    "Colombia": "Colombia",
}


# -- Mapeo de posiciones ESPN → 3 letras de la app ------------------------

POSITION_MAP: dict[str, str] = {
    "G": "POR", "GK": "POR",
    "D": "DEF", "CD": "DEF", "CD-L": "DEF", "CD-R": "DEF",
    "LB": "DEF", "RB": "DEF", "CB": "DEF", "DEF": "DEF",
    "WB": "DEF", "LWB": "DEF", "RWB": "DEF",
    "M": "MED", "CM": "MED", "CM-L": "MED", "CM-R": "MED",
    "DM": "MED", "AM": "MED", "LM": "MED", "RM": "MED", "MED": "MED",
    "MF": "MED",
    "F": "DEL", "ST": "DEL", "LW": "DEL", "RW": "DEL", "W": "DEL",
    "FW": "DEL", "DEL": "DEL", "CF": "DEL",
}


def position_code(abbrev: str | None) -> str:
    if not abbrev:
        return "?"
    return POSITION_MAP.get(abbrev.upper(), "?")


# -- Cliente HTTP ---------------------------------------------------------

def espn_get(path: str, params: dict | None = None) -> dict[str, Any]:
    """GET a la API pública de ESPN."""
    r = requests.get(f"{ESPN_BASE}{path}", params=params, timeout=REQUEST_TIMEOUT)
    r.raise_for_status()
    return r.json()


# -- Mapeo de eventos del partido -----------------------------------------

def parse_clock(clock_str: str) -> tuple[int | None, int | None]:
    """Convierte '27\\''  →  (27, None);  '45+5\\''  →  (45, 5)."""
    if not clock_str:
        return None, None
    base = clock_str.rstrip("'").strip()
    if not base:
        return None, None
    try:
        if "+" in base:
            base_m, extra_m = base.split("+", 1)
            return int(base_m.strip()), int(extra_m.strip())
        return int(base), None
    except ValueError:
        return None, None


def map_key_event(api_event: dict) -> list[tuple[str, str, dict]]:
    """De un keyEvent de ESPN devuelve [(team_id, player_name, event_dict), ...].
    Soporta gol, gol en propia, penalti, amarillas, rojas y sustituciones."""
    etype = (api_event.get("type") or {}).get("type") or ""
    clock_str = (api_event.get("clock") or {}).get("displayValue") or ""
    minute, extra = parse_clock(clock_str)
    if minute is None:
        return []

    team_id = (api_event.get("team") or {}).get("id")
    participants = api_event.get("participants") or []
    p1_name = ((participants[0].get("athlete") or {}).get("displayName")
               if len(participants) >= 1 else None)
    p2_name = ((participants[1].get("athlete") or {}).get("displayName")
               if len(participants) >= 2 else None)
    text = (api_event.get("text") or "").lower()

    out: list[tuple[str, str, dict]] = []

    def make_event(kind: str) -> dict:
        ev = {"type": kind, "minute": minute}
        if extra:
            ev["extraTime"] = extra
        return ev

    if etype == "goal":
        if "penalty" in text:
            kind = "penalty"
        elif "own goal" in text:
            kind = "own_goal"
        else:
            kind = "goal"
        if team_id and p1_name:
            out.append((team_id, p1_name, make_event(kind)))
        return out

    if etype == "yellow-card":
        if team_id and p1_name:
            out.append((team_id, p1_name, make_event("yellow")))
        return out

    if etype == "red-card":
        if team_id and p1_name:
            out.append((team_id, p1_name, make_event("red")))
        return out

    if etype == "substitution":
        # En ESPN: participant[0] entra, participant[1] sale
        if team_id and p1_name:
            out.append((team_id, p1_name, make_event("sub_in")))
        if team_id and p2_name:
            out.append((team_id, p2_name, make_event("sub_out")))
        return out

    return out


def build_details(summary: dict) -> dict | None:
    """Construye la estructura MatchDetails (homeLineup, awayLineup) a partir
    del summary completo de ESPN."""
    rosters = summary.get("rosters") or []
    if len(rosters) < 2:
        return None

    # Localiza qué roster es local y cuál visitante usando el header
    header = summary.get("header") or {}
    competitions = header.get("competitions") or []
    home_id = away_id = None
    if competitions:
        for c in competitions[0].get("competitors", []):
            tid = (c.get("team") or {}).get("id")
            if c.get("homeAway") == "home":
                home_id = tid
            elif c.get("homeAway") == "away":
                away_id = tid

    home_roster = next(
        (r for r in rosters if r["team"]["id"] == home_id), rosters[0]
    )
    away_roster = next(
        (r for r in rosters if r["team"]["id"] == away_id), rosters[1]
    )

    # Indexa eventos por (team_id, player_name)
    events_per_player: dict[tuple[str, str], list[dict]] = {}
    for ev in summary.get("keyEvents") or []:
        for team_id, player_name, event_dict in map_key_event(ev):
            events_per_player.setdefault(
                (team_id, player_name), []
            ).append(event_dict)

    def build_team(roster_team: dict) -> dict:
        team_id = roster_team["team"]["id"]
        formation = (
            roster_team.get("formation")
            or (roster_team.get("team") or {}).get("formation")
            or "?"
        )
        players = []
        for entry in roster_team.get("roster", []) or []:
            athlete = entry.get("athlete") or {}
            name = athlete.get("displayName", "?")
            try:
                jersey = int(entry.get("jersey") or 0)
            except ValueError:
                jersey = 0
            pos_abbrev = (entry.get("position") or {}).get("abbreviation")
            is_starter = bool(entry.get("starter", False))
            evs = events_per_player.get((team_id, name), [])
            # Ordena cronológicamente
            evs = sorted(evs, key=lambda e: (e["minute"], e.get("extraTime") or 0))
            players.append({
                "number": jersey,
                "name": name,
                "position": position_code(pos_abbrev),
                "isStarter": is_starter,
                "events": evs,
            })
        return {"formation": formation, "players": players}

    return {
        "homeLineup": build_team(home_roster),
        "awayLineup": build_team(away_roster),
    }


# -- Localización de partidos en el calendario ----------------------------

def index_games(snapshot: dict) -> dict[tuple[str, str, str], dict]:
    """Indexa cada partido por (fecha-ISO, local-ES, visitante-ES)."""
    index: dict[tuple[str, str, str], dict] = {}
    for day in snapshot["matchDays"]:
        for game in day["games"]:
            index[(day["date"], game["home"], game["away"])] = game
    return index


def collect_espn_query_dates(snapshot: dict) -> list[str]:
    """Devuelve las fechas (yyyymmdd) que hay que consultar en la scoreboard
    de ESPN. Como ESPN da las fechas en la zona local de la sede (US/Mex/Can)
    y nosotros las tenemos en Madrid, para cada fecha de partido en Madrid
    consultamos también el día anterior — un partido a las 00:00 Madrid
    arranca al día anterior en Norteamérica."""
    today_madrid = datetime.now(MADRID_TZ).strftime("%Y-%m-%d")
    dates: set[str] = set()
    for day in snapshot["matchDays"]:
        if day["date"] > today_madrid:
            continue
        d = datetime.strptime(day["date"], "%Y-%m-%d")
        dates.add(d.strftime("%Y%m%d"))
        dates.add((d - timedelta(days=1)).strftime("%Y%m%d"))
    return sorted(dates)


def madrid_date_from_utc(utc_iso: str) -> str:
    """Convierte un timestamp ISO en UTC a la fecha local de Madrid."""
    dt = datetime.fromisoformat(utc_iso.replace("Z", "+00:00"))
    return dt.astimezone(MADRID_TZ).strftime("%Y-%m-%d")


# -- Orquestación ---------------------------------------------------------

def load_snapshot() -> dict:
    if not JSON_PATH.exists():
        sys.exit(f"ERROR: no existe {JSON_PATH}. "
                 "Genera primero con scripts/export_snapshot.swift")
    return json.loads(JSON_PATH.read_text(encoding="utf-8"))


def save_snapshot(snapshot: dict) -> None:
    snapshot["lastUpdated"] = datetime.now(timezone.utc).strftime(
        "%Y-%m-%dT%H:%M:%SZ"
    )
    JSON_PATH.parent.mkdir(parents=True, exist_ok=True)
    JSON_PATH.write_text(
        json.dumps(snapshot, indent=2, ensure_ascii=False, sort_keys=True)
            + "\n",
        encoding="utf-8",
    )


def main() -> int:
    snapshot = load_snapshot()
    games_by_key = index_games(snapshot)
    espn_dates = collect_espn_query_dates(snapshot)

    print(f"Consultando ESPN para {len(espn_dates)} días…")

    seen_event_ids: set[str] = set()
    updated = 0
    for date_param in espn_dates:
        try:
            board = espn_get("/scoreboard", {"dates": date_param})
        except requests.HTTPError as exc:
            print(f"  ⚠️  fallo scoreboard {date_param}: {exc}", file=sys.stderr)
            continue

        for event in board.get("events", []) or []:
            event_id = event.get("id")
            if event_id in seen_event_ids:
                continue
            seen_event_ids.add(event_id)

            status = ((event.get("status") or {}).get("type") or {}).get("name", "")
            if status != "STATUS_FULL_TIME":
                continue

            # Fecha del partido en Madrid (para cruzar con nuestro JSON)
            madrid_date = madrid_date_from_utc(event.get("date", ""))

            competition = (event.get("competitions") or [{}])[0]
            home_team = away_team = None
            home_score = away_score = 0
            for c in competition.get("competitors", []) or []:
                tname = (c.get("team") or {}).get("displayName")
                tname_es = TEAM_NAME_MAP.get(tname, tname)
                score = int(c.get("score") or 0)
                if c.get("homeAway") == "home":
                    home_team = tname_es
                    home_score = score
                else:
                    away_team = tname_es
                    away_score = score

            if not home_team or not away_team:
                continue

            game = games_by_key.get((madrid_date, home_team, away_team))
            if game is None:
                print(f"  ⚠️  Sin partido en JSON para "
                      f"{madrid_date} {home_team} vs {away_team}")
                continue

            result = f"{home_score}-{away_score}"
            already = (game.get("done")
                       and game.get("result") == result
                       and game.get("details"))
            if already:
                continue

            try:
                summary = espn_get("/summary", {"event": event_id})
            except requests.HTTPError as exc:
                print(f"    fallo summary {event_id}: {exc}",
                      file=sys.stderr)
                continue

            details = build_details(summary)

            game["done"] = True
            game["result"] = result
            if details:
                game["details"] = details
            updated += 1
            print(f"  ✅ {madrid_date}  {home_team} {result} {away_team}")

    if updated == 0:
        print("Sin cambios. No se reescribe el JSON.")
        return 0

    save_snapshot(snapshot)
    print(f"✅ Total partidos actualizados: {updated} → {JSON_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
