# Blueprint: App de Seguimiento de La Liga Española 2026-27

Este documento transfiere el conocimiento técnico y arquitectónico adquirido al construir **CalendarMundial** (app del Mundial 2026) para aplicarlo directamente en la nueva app de La Liga. Está escrito para ser usado como contexto de partida en una conversación nueva con Claude.

---

## 1. Resumen del proyecto de referencia

**CalendarMundial** es una app iOS/SwiftUI que muestra el calendario completo del Mundial FIFA 2026, con resultados actualizados automáticamente cada 15 minutos desde la API pública de ESPN a través de un GitHub Actions cron job. Los datos se sirven desde un JSON en GitHub raw, sin backend propio.

- **Repo**: `https://github.com/cornellana/calendar-mundial-2026`
- **Team ID de firma**: `TJ6V4QM3GB` (Francisco Cornellana Castells)
- **Generación de proyecto**: XcodeGen (`project.yml`)
- **Target**: iOS 17.0+, iPhone + iPad

---

## 2. Arquitectura general (reutilizar íntegramente)

```
LaLigaApp/
├── project.yml                        ← XcodeGen spec
├── .github/workflows/update-liga.yml  ← cron ESPN → JSON commit
├── scripts/update_liga.py             ← script Python de actualización
├── data/laliga2627.json               ← JSON servido por GitHub raw
└── LaLigaApp/                         ← fuentes Swift del target
    ├── LaLigaApp.swift
    ├── ContentView.swift
    ├── Models.swift
    ├── MatchStore.swift
    ├── MatchesData.swift
    ├── MatchDetailsData.swift
    ├── MatchDetailSheet.swift
    ├── TopScorersSheet.swift
    ├── StandingsSheet.swift           ← nuevo: tabla completa de clasificación
    ├── Assets.xcassets/
    └── Localizable.xcstrings
```

### Flujo de datos

```
ESPN API pública → GitHub Actions (cada 15 min) → data/laliga2627.json
                                                         ↓ GitHub raw URL
                                               MatchStore.refresh() en la app
                                                         ↓
                                               UserDefaults (caché)
                                                         ↓
                                               @Observable → SwiftUI re-render
```

---

## 3. Modelos de datos (adaptar desde CalendarMundial)

### 3.1 Modelos que se reutilizan sin cambios

```swift
// Copiar directamente desde CalendarMundial/Models.swift:
// - MatchEvent, MatchEventType  (goles, tarjetas, sustituciones con minuto + extraTime)
// - LineupPlayer                (dorsal, nombre, posición, isStarter, eventos)
// - TeamLineup                  (formation + players)
// - MatchDetails                (homeLineup + awayLineup)
// - GroupStanding               (estadísticas por equipo: PJ/PG/PE/PP/GF/GC)
// - TopScorer                   (player, team, goals, penalties)
// - MatchSnapshot               (lastUpdated + matchDays — wrapper del JSON remoto)
// - SelectedMatch               (Identifiable para .sheet(item:))
// - Color.init(hex:)            (extensión 0xRRGGBB)
```

### 3.2 TVChannel — adaptar canales de La Liga

La Liga tiene una distribución de derechos diferente al Mundial. Actualizar `TVChannel`:

```swift
enum TVChannel: String, Codable {
    case dazn = "DAZN"           // mayoría de partidos (pay)
    case movistar = "MOVISTAR"   // Movistar+ Liga de Campeones / LaLiga TV
    case gol = "GOL"             // canal gratuito (1 partido/jornada)
    case tve = "TVE"             // TVE (finales o partidos especiales)
}
```

> **Nota**: En 2025-26 DAZN retiene la mayoría de partidos; Movistar+ tiene LaLiga TV Bar. Verificar el estado real de los derechos para 2026-27 antes de codificarlo.

### 3.3 Phase → Jornada (cambio estructural importante)

En La Liga no hay "fases", hay **jornadas** (38 en total). Reemplazar `Phase` por:

```swift
/// Jornada de La Liga (1–38) o especiales (aplazados, Copa).
enum Jornada: Codable, CaseIterable, Identifiable, Hashable {
    case regular(Int)   // 1–38
    case postponed      // aplazado (fechas pendientes de asignar)

    var id: String { label }

    var label: String {
        switch self {
        case .regular(let n): return "J\(n)"
        case .postponed: return "Aplazado"
        }
    }

    // Para el badge de cabecera de día
    var displayLabel: String {
        switch self {
        case .regular(let n): return "Jornada \(n)"
        case .postponed: return "Aplazado"
        }
    }
}
```

> Si quieres mantener compatibilidad con el `Phase.rawValue` en JSON, usa `regular` con rawValue `"J1"`, `"J2"`, etc.

### 3.4 Match — adaptar campos

```swift
struct Match: Identifiable, Codable {
    let id: UUID
    let time: String          // "HH:mm" horario Madrid
    let home: String          // nombre equipo local
    let away: String          // nombre equipo visitante
    let jornada: Int          // número de jornada (1–38)
    let tv: TVChannel
    let done: Bool
    let result: String?       // "G-G" si terminado
    let details: MatchDetails?
    let stadium: String?
    let venueCity: String?
    // Quitar: group, esp (no aplican en liga)
    // Añadir opcional:
    let matchweek: Int        // alias de jornada, útil para filtros
}
```

### 3.5 MatchDay — mismo concepto, diferente agrupación

```swift
struct MatchDay: Identifiable, Codable {
    var id: String { date }
    let date: String      // "yyyy-MM-dd"
    let jornada: Int      // jornada predominante del día
    let games: [Match]
}
```

### 3.6 Nuevo: Standing completo (tabla de clasificación entera)

A diferencia del Mundial (donde solo importa el grupo activo), en La Liga la tabla completa de los 20 equipos es central:

```swift
struct LeagueStanding: Identifiable, Hashable {
    var id: String { team }
    let position: Int
    let team: String
    var played: Int = 0
    var won: Int = 0
    var drawn: Int = 0
    var lost: Int = 0
    var goalsFor: Int = 0
    var goalsAgainst: Int = 0
    var goalDifference: Int { goalsFor - goalsAgainst }
    var points: Int { won * 3 + drawn }
    // Para colorear zonas:
    var zone: StandingZone { ... }
}

enum StandingZone {
    case championsLeague   // top 4 → verde
    case europaLeague      // 5–6 → azul claro
    case conferenceLeague  // 7 → azul muy claro
    case mid               // 8–17 → neutral
    case relegation        // 18–20 → rojo
}
```

---

## 4. MatchStore (reutilizar casi íntegramente)

El patrón es idéntico: carga en cascada (caché → seed → remoto), `@Observable`, `@MainActor`, cache-buster en la URL. Solo cambiar:

```swift
static let remoteURL: URL? = URL(
    string: "https://raw.githubusercontent.com/cornellana/laliga-app-2627/refs/heads/main/data/laliga2627.json"
)
private static let cacheKey = "laliga2627_cache_v1"
```

**Lección crítica aprendida**: el `UserDefaults` guarda el `MatchSnapshot` completo serializado como `Data`. La clave de caché incluye la versión (`_v1`) para poder invalidarla limpiamente si el esquema cambia.

**Lección de cache-buster**: siempre añadir `?t=<timestamp>` a la URL y usar `.reloadIgnoringLocalAndRemoteCacheData`. GitHub raw tiene hasta 5 min de caché CDN — sin esto la app puede mostrar datos viejos.

---

## 5. ContentView — patrones SwiftUI probados

### 5.1 Scroll automático a la jornada de hoy

```swift
// Dentro de ScrollViewReader { proxy in
.task(id: scenePhase) {
    guard scenePhase == .active else { return }
    await store.refresh()
    guard let target = scrollTargetDate else { return }
    try? await Task.sleep(nanoseconds: 350_000_000)
    withAnimation(.easeInOut(duration: 0.5)) {
        proxy.scrollTo(target, anchor: .top)
    }
}
// Al quitar un filtro (volver a "Todos"), también hacer scroll:
.onChange(of: activeJornada) { _, newVal in
    guard newVal == .all, let target = scrollTargetDate else { return }
    Task {
        try? await Task.sleep(nanoseconds: 150_000_000)
        withAnimation(.easeInOut(duration: 0.5)) {
            proxy.scrollTo(target, anchor: .top)
        }
    }
}
// Al cerrar cualquier sheet, también scroll:
.onChange(of: showingStandings) { _, isShowing in
    guard !isShowing, let target = scrollTargetDate else { return }
    Task {
        try? await Task.sleep(nanoseconds: 150_000_000)
        withAnimation { proxy.scrollTo(target, anchor: .top) }
    }
}
```

> **Por qué el sleep**: SwiftUI necesita que el layout se complete antes de que `scrollTo` tenga efecto. 150-350ms es el rango empírico que funciona; menos y a veces no scrollea.

### 5.2 Pull-to-refresh

```swift
ScrollView { ... }
    .refreshable { await store.refresh() }
```

### 5.3 Estado de filtros

Para La Liga, el filtro principal es por jornada. Usar un enum similar a `PhaseFilter`:

```swift
enum JornadaFilter: Hashable {
    case all
    case jornada(Int)       // 1–38
    case team(String)       // filtrar por equipo
    case stadium(String)    // filtrar por estadio
}
```

### 5.4 Sheet de detalle de partido

Patrón `.sheet(item:)` con `SelectedMatch: Identifiable`:
- Si el partido tiene `details` → `.presentationDetents([.medium, .large])` abriendo en `.large`
- Si no tiene details (pendiente) → `.medium`
- Siempre `.presentationDragIndicator(.visible)`

---

## 6. ESPN API para La Liga

### Endpoint principal

```
https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/scoreboard
```

Parámetros:
- `?dates=YYYYMMDD` — partidos de una fecha concreta
- `?week=N&season=2026&seasontype=2` — jornada N (experimentar, no siempre funciona)

### Endpoint de detalle de partido

```
https://site.api.espn.com/apis/site/v2/sports/soccer/esp.1/summary?event=<eventId>
```

### Estructura de respuesta (igual que Mundial)

```json
{
  "events": [
    {
      "id": "...",
      "date": "2026-08-16T19:00Z",
      "status": {
        "type": {
          "name": "STATUS_FULL_TIME",
          "completed": true        ← USAR ESTE CAMPO, no el name
        }
      },
      "competitions": [{
        "competitors": [
          { "homeAway": "home", "team": { "displayName": "Real Madrid" }, "score": "2" },
          { "homeAway": "away", "team": { "displayName": "Barcelona" }, "score": "1" }
        ],
        "venue": {
          "fullName": "Santiago Bernabéu",
          "address": { "city": "Madrid" }
        }
      }]
    }
  ]
}
```

### Lección crítica aprendida con el script

**NUNCA** usar `status.type.name == "STATUS_FULL_TIME"` para detectar partidos finalizados. En La Liga también habrá partidos con prórroga o penaltis (Copa del Rey, si decides incluirla). Usar siempre:

```python
status_type = (event.get("status") or {}).get("type") or {}
if not status_type.get("completed", False):
    continue  # partido no finalizado, saltar
```

### Mapa de nombres ESPN → español (ampliar para La Liga)

```python
TEAM_NAME_MAP = {
    "Real Madrid": "Real Madrid",
    "Barcelona": "FC Barcelona",
    "Atlético de Madrid": "Atlético",
    "Athletic Club": "Athletic",
    "Real Sociedad": "R. Sociedad",
    "Real Betis": "Betis",
    "Villarreal": "Villarreal",
    "Valencia": "Valencia",
    "Sevilla": "Sevilla",
    "Osasuna": "Osasuna",
    "Girona": "Girona",
    "Getafe": "Getafe",
    "Celta de Vigo": "Celta",
    "Rayo Vallecano": "Rayo",
    "Mallorca": "Mallorca",
    "Las Palmas": "Las Palmas",
    "Alavés": "Alavés",
    "Leganés": "Leganés",
    # Añadir los 3 ascendidos de 2ª para 2026-27
}
```

> Los nombres ESPN en inglés son casi siempre en español para La Liga. Verificar antes de codificar el mapa completo.

---

## 7. Script de actualización Python (update_liga.py)

### Diferencias respecto al script del Mundial

| Aspecto | Mundial 2026 | La Liga 2026-27 |
|---------|-------------|-----------------|
| Duración | 1 mes | 10 meses |
| Partidos | ~104 en total | 380 en total |
| API endpoint | `fifa.world` | `esp.1` |
| Estructura JSON | matchDays con phase | matchDays con jornada |
| Horario | mayoría en UTC tarde | viernes–domingo, variado |
| FORCE_REFRESH | útil en bugs puntales | necesario al inicio de temporada |

### Estructura del JSON de salida

```json
{
  "lastUpdated": "2026-10-12T18:30:00Z",
  "season": "2026-27",
  "matchDays": [
    {
      "date": "2026-08-16",
      "jornada": 1,
      "games": [
        {
          "time": "21:00",
          "home": "Real Madrid",
          "away": "Mallorca",
          "jornada": 1,
          "tv": "DAZN",
          "done": true,
          "result": "3-0",
          "stadium": "Santiago Bernabéu",
          "venueCity": "Madrid",
          "esp": false,
          "details": { ... }
        }
      ]
    }
  ]
}
```

### Lógica de keys para actualización incremental

```python
def madrid_date_from_utc(utc_str):
    """Convierte timestamp ESPN UTC a fecha Madrid (CEST = UTC+2, CET = UTC+1)."""
    from datetime import datetime, timezone, timedelta
    dt = datetime.fromisoformat(utc_str.replace("Z", "+00:00"))
    # Aproximación: junio-oct CEST (+2), nov-mar CET (+1)
    offset = 2 if dt.month in range(3, 11) else 1
    madrid = dt + timedelta(hours=offset)
    return madrid.strftime("%Y-%m-%d"), madrid.strftime("%H:%M")

# Key de partido = "YYYY-MM-DD|HomeTeam|AwayTeam"
# El script busca en el JSON existente por esta key antes de actualizar.
```

### Variable de entorno FORCE_REFRESH

```yaml
# En el workflow:
env:
  FORCE_REFRESH: ${{ github.event.inputs.force_refresh }}
```

```python
# En el script:
FORCE_REFRESH = os.environ.get("FORCE_REFRESH", "false").lower() == "true"
```

Si `FORCE_REFRESH=true`, reprocesar todos los partidos `completed=True` aunque ya tengan `done=true` en el JSON. Útil cuando se corrige un bug del script de parsing.

Para ejecutarlo manualmente:
```bash
gh workflow run update-liga.yml --field force_refresh=true
```

---

## 8. GitHub Actions workflow

```yaml
name: Actualizar datos de La Liga

on:
  schedule:
    - cron: "*/15 * * * *"   # cada 15 min durante la temporada
  workflow_dispatch:
    inputs:
      force_refresh:
        description: 'Forzar reproceso de todos los partidos finalizados'
        type: boolean
        default: false

permissions:
  contents: write

jobs:
  update:
    runs-on: ubuntu-latest
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install --quiet requests
      - name: Actualizar JSON desde ESPN
        env:
          FORCE_REFRESH: ${{ github.event.inputs.force_refresh }}
        run: python scripts/update_liga.py
      - name: Commit + push si hay cambios
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add data/laliga2627.json
          if git diff --cached --quiet; then
            echo "Sin cambios."
          else
            git commit -m "chore: actualización automática LaLiga $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
            git push
          fi
```

> **Lección aprendida**: el cron de GitHub Actions puede retrasarse hasta 10-15 min en horas pico. El cron de 15 min garantiza que en 30 min como máximo la app tiene los datos del partido recién terminado. Es gratuito.

---

## 9. MatchStore — manejo de conflictos git con el bot

Cuando el cron commitea y tú también tienes cambios locales (muy frecuente al actualizar el seed data):

```bash
git pull --rebase origin main
# Si hay conflicto en data/laliga2627.json:
git checkout --theirs data/laliga2627.json   # el remoto (bot) siempre gana en datos
git add data/laliga2627.json
git rebase --continue
```

---

## 10. Seed data (MatchesData.swift)

En CalendarMundial el seed data era estático (lo rellenamos a mano al principio del torneo). Para La Liga:

- El seed puede ser solo la **estructura de jornadas vacía** (38 jornadas, sin equipos ni horas, solo la fecha aproximada de cada jornada).
- Alternatively, pre-rellenarlo con los primeros 10-15 partidos de la temporada una vez que la LFP publique el calendario oficial (normalmente en junio).
- El JSON remoto sobrescribe todo; el seed es solo para el primer arranque sin conexión.

```swift
enum LigaData {
    static let startDate = "2026-08-15"   // aproximado, ajustar
    static let endDate   = "2027-05-30"   // última jornada aprox.
    static let teams = [                  // los 20 equipos (actualizar con ascensos)
        "Real Madrid", "FC Barcelona", "Atlético", "Athletic",
        "R. Sociedad", "Betis", "Villarreal", "Valencia",
        "Sevilla", "Osasuna", "Girona", "Getafe",
        "Celta", "Rayo", "Mallorca", "Las Palmas",
        "Alavés", "Leganés", /* 2 ascendidos TBD */
    ]
    static let matchDays: [MatchDay] = [ /* seed vacío o parcial */ ]
}
```

---

## 11. Nuevas features respecto al Mundial

La Liga justifica features que el Mundial no necesitaba:

### 11.1 Tabla de clasificación completa (StandingsSheet)

En CalendarMundial solo mostrábamos la clasificación del grupo activo. Para La Liga, la tabla completa de los 20 equipos es la feature más importante. Crear `StandingsSheet`:

- Columnas: Pos | Equipo | PJ | PG | PE | PP | GF | GC | DG | Pts
- Color de zona: verde (top 4 = Champions), azul (5-6 = Europa), gris (mid), rojo (18-20 = descenso)
- Colores de fila para el equipo líder (oro) y el último (rojo intenso)
- Calcular con la misma lógica de `MundialData.standings()` pero sobre todos los partidos

### 11.2 Filtro por equipo (equipoFilter)

En el Mundial era útil buscar por nombre. En La Liga tiene más sentido un **selector de equipo** fijo (los 20 de la liga) en lugar de un buscador libre. Combinar ambas opciones.

### 11.3 Goleadores (TopScorersSheet)

El código de `TopScorersSheet` y `MundialData.topScorers()` se reutiliza prácticamente sin cambios. Solo actualizar los textos ("Copa Mundial FIFA 2026" → "La Liga 2026-27").

### 11.4 Racha y forma del equipo

Feature opcional: al filtrar por equipo, mostrar los últimos 5 resultados (V/E/D) como chips coloreados. Se calcula desde `matchDays` filtrando partidos `done=true` del equipo.

---

## 12. Paleta de colores sugerida para La Liga

CalendarMundial usa azul marino oscuro (`0x0A0F1E`) y dorado (`0xC8A84B`). Para La Liga, la identidad es roja/naranja:

```swift
// Fondo principal
Color(hex: 0x0F0A0A)   // negro rojizo

// Acento principal (LaLiga orange)
Color(hex: 0xE8460B)   // naranja LaLiga oficial

// Acento secundario
Color(hex: 0xFFFFFF)   // blanco

// Texto secundario
Color(hex: 0x8A7A7A)   // gris cálido
```

> O mantener el esquema oscuro de CalendarMundial y usar el naranja LaLiga solo para el acento.

---

## 13. XcodeGen project.yml base

```yaml
name: LaLigaApp
options:
  bundleIdPrefix: com.cornellana
  deploymentTarget:
    iOS: "17.0"
  knownRegions: [en, es, ca]
  developmentLanguage: en
targets:
  LaLigaApp:
    type: application
    platform: iOS
    sources: [LaLigaApp]
    settings:
      base:
        GENERATE_INFOPLIST_FILE: YES
        INFOPLIST_KEY_UILaunchScreen_Generation: YES
        SWIFT_VERSION: "5.9"
        TARGETED_DEVICE_FAMILY: "1,2"
        CURRENT_PROJECT_VERSION: 1
        MARKETING_VERSION: 1.0
        DEVELOPMENT_TEAM: TJ6V4QM3GB
        ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon
```

---

## 14. Checklist de arranque del proyecto

- [ ] Crear repo GitHub: `gh repo create cornellana/laliga-app-2627 --public --source=. --remote=origin --push`
- [ ] Copiar y adaptar `project.yml`
- [ ] `xcodegen generate`
- [ ] Copiar Models.swift, MatchStore.swift, ContentView.swift desde CalendarMundial y adaptar
- [ ] Crear `scripts/update_liga.py` basándose en `update_mundial.py` (cambiar endpoint a `esp.1`)
- [ ] Crear `data/laliga2627.json` con estructura vacía inicial
- [ ] Crear `.github/workflows/update-liga.yml`
- [ ] Añadir `.gitignore` estándar (`.DS_Store`, `xcuserdata/`, `DerivedData/`, etc.)
- [ ] Generar icono con `scripts/render_icon.swift` (CoreGraphics, sin NSGraphicsContext)
- [ ] Verificar `xcodebuild build` → `** BUILD SUCCEEDED **`
- [ ] Activar el workflow de GitHub Actions y verificar el primer run

---

## 15. Lecciones aprendidas (las más valiosas)

1. **`completed` booleano, no `status.type.name`**: el nombre varía entre `STATUS_FULL_TIME`, `STATUS_FULL_TIME_AET`, `STATUS_FINAL_PEN`. El campo `completed: Bool` es siempre fiable.

2. **Cache-buster en URL**: `?t=<timestamp>` en cada request al JSON remoto. Sin esto, iOS (o el CDN de GitHub) puede servir versión con hasta 5 min de retraso.

3. **Sleep antes de `scrollTo`**: SwiftUI necesita 150-350ms para que el layout esté listo tras un cambio de estado antes de ejecutar `proxy.scrollTo()`.

4. **`.onChange` para restaurar scroll**: no solo al activar la app (`.task(id: scenePhase)`) sino también al quitar filtros y al cerrar sheets (`.onChange(of: showingSheet)`).

5. **`UserDefaults` para caché, no FileManager**: más simple, suficiente para ~500KB de JSON. Usar clave versionada (`_v1`) para poder invalidar sin migración.

6. **Conflictos git con el bot**: siempre `git pull --rebase` antes de push. Para `data/*.json`, el remoto (bot) siempre gana: `git checkout --theirs`.

7. **`@Observable` en lugar de `ObservableObject`**: más limpio, sin `@Published`, sin Combine. El MatchStore con `@Observable` + `@State private var store = MatchStore()` en ContentView funciona perfectamente.

8. **`decodeIfPresent` en todos los campos opcionales**: el JSON remoto puede no incluir ciertos campos en partidos pendientes. Siempre codificar de forma defensiva.

9. **El icono con CoreGraphics puro**: usar `CGContext` directamente, nunca `NSGraphicsContext`. En línea de comandos (scripts), `NSGraphicsContext` produce PNG negro.

10. **`FORCE_REFRESH` como workflow dispatch input**: sin esto, si el script tiene un bug y hay que reprocesar 80+ partidos históricos, no hay manera fácil. Añadirlo desde el principio.
