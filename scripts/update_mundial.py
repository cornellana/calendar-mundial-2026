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
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from zoneinfo import ZoneInfo

import requests

MADRID_TZ = ZoneInfo("Europe/Madrid")

# Si está activo, el script reprocesa todos los partidos finalizados aunque
# ya tengan `done` + `result` + `details` + `stadium` + `venueCity`. Útil para
# aplicar fixes del propio script a datos antiguos.
FORCE_REFRESH = os.environ.get("FORCE_REFRESH", "").lower() in (
    "true", "1", "yes", "y",
)


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


# -- Mapeo de país (ESPN inglés → español) -------------------------------

COUNTRY_NAME_MAP: dict[str, str] = {
    "United States": "EE.UU.",
    "United States of America": "EE.UU.",
    "USA": "EE.UU.",
    "US": "EE.UU.",
    "Mexico": "México",
    "MEX": "México",
    "Canada": "Canadá",
    "CAN": "Canadá",
}


def format_venue_city(venue: dict | None) -> str | None:
    """Formato "Ciudad, País" en español a partir del bloque venue de ESPN."""
    if not venue:
        return None
    address = venue.get("address") or {}
    city = (address.get("city") or "").strip()
    country = (address.get("country") or "").strip()
    country_es = COUNTRY_NAME_MAP.get(country, country)
    if city and country_es and country_es.lower() not in city.lower():
        return f"{city}, {country_es}"
    return city or None


def extract_venue(summary: dict) -> tuple[str | None, str | None]:
    """Devuelve (estadio, ciudad) extraídos del gameInfo del summary de ESPN."""
    info = summary.get("gameInfo") or {}
    venue = info.get("venue") or {}
    stadium = (venue.get("fullName") or venue.get("name") or "").strip() or None
    city = format_venue_city(venue)
    return stadium, city


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
    """Convierte '27\\''  →  (27, None);  '45\\'+5\\''  →  (45, 5).

    ESPN devuelve el minuto del tiempo añadido con APÓSTROFE DOBLE
    (p. ej. '45'+5''), no '45+5''. Por eso eliminamos todos los apóstrofes
    antes de parsear — si sólo quitásemos el último, fallaría el int()."""
    if not clock_str:
        return None, None
    base = clock_str.replace("'", "").strip()
    if not base:
        return None, None
    try:
        if "+" in base:
            base_m, extra_m = base.split("+", 1)
            return int(base_m.strip()), int(extra_m.strip())
        return int(base), None
    except ValueError:
        return None, None


def map_commentary_item(item: dict) -> list[tuple[str, str, dict]]:
    """Convierte un item de `summary.commentary` en eventos de nuestro modelo.

    A diferencia de `keyEvents` (que sólo lista algunos goles destacados),
    `commentary` recoge **todos** los eventos del partido. Tipos relevantes
    de ESPN que cubrimos:
      - Goal / Goal - Header / Goal - Volley / Goal - … → goal
      - Penalty - Scored                              → penalty
      - Own Goal                                       → own_goal
      - Yellow Card / VAR - (Yellow) Card Upgrade      → yellow
      - Red Card    / VAR - (Red) Card Upgrade         → red
      - Substitution                                   → sub_in + sub_out

    En un autogol ESPN sigue poniendo team_id = equipo BENEFICIARIO. El
    matching en `build_details` se hace por nombre de jugador, así el
    autogol se coloca en la alineación del autor (el equipo opuesto)."""
    play = item.get("play") or {}
    play_type = ((play.get("type") or {}).get("text") or "").strip()
    play_type_lc = play_type.lower()

    clock_str = (item.get("time") or {}).get("displayValue") or ""
    minute, extra = parse_clock(clock_str)
    if minute is None:
        return []

    team_id = (play.get("team") or {}).get("id")
    participants = play.get("participants") or []
    p1 = ((participants[0].get("athlete") or {}).get("displayName") or ""
          if len(participants) >= 1 else "")
    p2 = ((participants[1].get("athlete") or {}).get("displayName") or ""
          if len(participants) >= 2 else "")
    text_lc = (item.get("text") or "").lower()

    out: list[tuple[str, str, dict]] = []

    def make_event(kind: str) -> dict:
        ev = {"type": kind, "minute": minute}
        if extra:
            ev["extraTime"] = extra
        return ev

    # Autogol — comprobar primero porque puede solaparse con "goal"
    if "own goal" in play_type_lc or "own goal" in text_lc:
        if p1:
            out.append((team_id, p1, make_event("own_goal")))
        return out

    # Penalti convertido
    if "penalty - scored" in play_type_lc:
        if p1:
            out.append((team_id, p1, make_event("penalty")))
        return out

    # Gol (con sus variantes: Goal, Goal - Header, Goal - Volley, etc.)
    if play_type_lc.startswith("goal"):
        if p1:
            out.append((team_id, p1, make_event("goal")))
        return out

    # Amarilla (directa o por upgrade de VAR)
    if "yellow card" in play_type_lc:
        if p1:
            out.append((team_id, p1, make_event("yellow")))
        return out

    # Roja (directa o por upgrade de VAR)
    if "red card" in play_type_lc:
        if p1:
            out.append((team_id, p1, make_event("red")))
        return out

    # Sustitución: ESPN pone p1 como el que ENTRA y p2 como el que SALE.
    if "substitution" in play_type_lc:
        if p1:
            out.append((team_id, p1, make_event("sub_in")))
        if p2:
            out.append((team_id, p2, make_event("sub_out")))
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

    # Indexa eventos por NOMBRE de jugador (no por team_id) porque los
    # autogoles vienen con team_id = beneficiario y queremos colocarlos
    # en la alineación del autor (equipo opuesto).
    # Usamos `commentary` (no `keyEvents`) porque keyEvents lista sólo
    # algunos goles "destacados" y nos perdemos varios por partido.
    events_per_player: dict[str, list[dict]] = {}
    for item in summary.get("commentary") or []:
        for _team_id, player_name, event_dict in map_commentary_item(item):
            events_per_player.setdefault(player_name, []).append(event_dict)

    # Deduplica por (tipo, minuto, extraTime) — un mismo evento puede
    # aparecer dos veces en commentary (p. ej. comentario + scoringPlay).
    for name, evs in events_per_player.items():
        seen: set[tuple] = set()
        unique: list[dict] = []
        for e in evs:
            key = (e["type"], e["minute"], e.get("extraTime"))
            if key in seen:
                continue
            seen.add(key)
            unique.append(e)
        events_per_player[name] = unique

    def build_team(roster_team: dict) -> dict:
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
            evs = events_per_player.get(name, [])
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

            # Usar el campo `completed` en lugar del nombre exacto del estado:
            # en fase de grupos el estado es STATUS_FULL_TIME, pero en
            # eliminatorias puede ser STATUS_FULL_TIME_AET (prórroga) o
            # STATUS_FINAL_PEN (penaltis). `completed=True` cubre todos los casos.
            status_type = (event.get("status") or {}).get("type") or {}
            if not status_type.get("completed", False):
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
            # Refetch si falta cualquiera de: result correcto, details o venue.
            # Con FORCE_REFRESH=true se ignora esta condición y se recarga todo.
            already = (not FORCE_REFRESH
                       and game.get("done")
                       and game.get("result") == result
                       and game.get("details")
                       and game.get("stadium")
                       and game.get("venueCity"))
            if already:
                continue

            try:
                summary = espn_get("/summary", {"event": event_id})
            except requests.HTTPError as exc:
                print(f"    fallo summary {event_id}: {exc}",
                      file=sys.stderr)
                continue

            details = build_details(summary)
            stadium, city = extract_venue(summary)

            game["done"] = True
            game["result"] = result
            if details:
                game["details"] = details
            if stadium:
                game["stadium"] = stadium
            if city:
                game["venueCity"] = city
            updated += 1
            print(f"  ✅ {madrid_date}  {home_team} {result} {away_team}  "
                  f"({stadium or '?'} – {city or '?'})")

    if updated == 0:
        print("Sin cambios. No se reescribe el JSON.")
        return 0

    save_snapshot(snapshot)
    print(f"✅ Total partidos actualizados: {updated} → {JSON_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
