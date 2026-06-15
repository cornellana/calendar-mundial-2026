//
//  Models.swift
//  CalendarMundial
//
//  Modelos de dominio del calendario del Mundial 2026.
//

import SwiftUI

// MARK: - TVChannel

/// Canal por el que se retransmite un partido en España.
enum TVChannel: String, Codable {
    /// La 1 (TVE) + DAZN: emisión gratuita en abierto.
    case both = "BOTH"
    /// Solo DAZN: emisión de pago.
    case dazn = "DAZN"

    /// Etiqueta legible del canal mostrada en la UI.
    var label: String {
        switch self {
        case .both: return "La 1 + DAZN"
        case .dazn: return "DAZN"
        }
    }

    /// Color del punto indicador junto al badge del canal.
    var dotColor: Color {
        switch self {
        case .both: return Color(hex: 0x2196F3)
        case .dazn: return Color(hex: 0xC8A84B)
        }
    }

    /// Fondo del badge de canal.
    var badgeBackground: Color {
        switch self {
        case .both: return Color(hex: 0x0D2A4A)
        case .dazn: return Color(hex: 0x1A1500)
        }
    }

    /// Borde del badge de canal.
    var badgeBorder: Color {
        switch self {
        case .both: return Color(hex: 0x1E4A7A)
        case .dazn: return Color(hex: 0x3A3000)
        }
    }
}

// MARK: - Phase

/// Fase del torneo a la que pertenece un partido.
///
/// El `rawValue` se usa tanto en JSON remoto como en la visualización del badge,
/// por eso conviene no cambiarlo aunque la chip muestre un texto distinto.
enum Phase: String, Codable, CaseIterable, Identifiable {
    case grupos = "Grupos"
    case dieciseisavos = "1/16"
    case octavos = "1/8"
    case cuartos = "Cuartos"
    case semis = "Semis"
    case final = "Final"

    var id: String { rawValue }

    /// Fondo del badge de fase mostrado a la derecha de cada cabecera de día.
    var badgeBackground: Color {
        switch self {
        case .grupos: return Color(hex: 0xE3F0FB)
        case .dieciseisavos: return Color(hex: 0xEDE8FB)
        case .octavos: return Color(hex: 0xFCE8FB)
        case .cuartos: return Color(hex: 0xFCE8E8)
        case .semis: return Color(hex: 0xFDF0E0)
        case .final: return Color(hex: 0xFDF8E0)
        }
    }

    /// Color del texto del badge de fase.
    var badgeText: Color {
        switch self {
        case .grupos: return Color(hex: 0x1A3A5C)
        case .dieciseisavos: return Color(hex: 0x2D1B69)
        case .octavos: return Color(hex: 0x4A1942)
        case .cuartos: return Color(hex: 0x6B2020)
        case .semis: return Color(hex: 0x6B3A10)
        case .final: return Color(hex: 0x5A4A00)
        }
    }
}

// MARK: - PhaseFilter

/// Filtro activo aplicado al listado de partidos.
///
/// Combina fases del torneo, grupos concretos (A–L) o ningún filtro.
/// Sólo puede estar activo uno cada vez.
enum PhaseFilter: Hashable {
    /// Sin filtro: se muestran todos los partidos.
    case all
    /// Filtro por fase del torneo (grupos, octavos, etc.).
    case phase(Phase)
    /// Filtro por letra de grupo (de "A" a "L").
    case group(String)
    /// Filtro por selección/país concreto.
    case country(String)
    /// Filtro por estadio concreto.
    case stadium(String)

    /// Etiqueta legible para mostrar en la barra de filtro activo.
    var label: String {
        switch self {
        case .all: return "Todos"
        case .phase(let p): return p.rawValue
        case .group(let g): return "Grupo \(g)"
        case .country(let c): return c
        case .stadium(let s): return s
        }
    }
}

// MARK: - GroupStanding

/// Fila de la clasificación de un grupo: estadísticas acumuladas de un equipo.
struct GroupStanding: Identifiable, Hashable {
    var id: String { country }
    /// Nombre del país tal como aparece en el calendario (puede incluir flag emoji).
    let country: String
    /// Partidos jugados.
    var played: Int = 0
    /// Partidos ganados.
    var won: Int = 0
    /// Partidos empatados.
    var drawn: Int = 0
    /// Partidos perdidos.
    var lost: Int = 0
    /// Goles a favor.
    var goalsFor: Int = 0
    /// Goles en contra.
    var goalsAgainst: Int = 0
    /// Diferencia de goles (GF - GC).
    var goalDifference: Int { goalsFor - goalsAgainst }
    /// Puntos (3 por victoria, 1 por empate).
    var points: Int { won * 3 + drawn }
}

// MARK: - TeamSide

/// Identifica si un dato hace referencia al equipo local o al visitante.
enum TeamSide: String, Codable, Hashable {
    case home
    case away
}

// MARK: - MatchEventType

/// Tipo de evento que puede ocurrir durante un partido.
enum MatchEventType: String, Codable, Hashable {
    /// Gol en jugada normal.
    case goal
    /// Gol de penalti.
    case penalty
    /// Gol en propia puerta.
    case ownGoal = "own_goal"
    /// Tarjeta amarilla.
    case yellow
    /// Tarjeta roja directa.
    case red
    /// Entrada al campo (suplente que entra al partido).
    case subIn = "sub_in"
    /// Salida del campo (jugador sustituido).
    case subOut = "sub_out"
}

// MARK: - MatchEvent

/// Evento puntual durante un partido (gol o tarjeta) con su minuto.
///
/// Los eventos se asocian a `LineupPlayer` para poder pintarlos junto al jugador
/// en la alineación. Admiten *tiempo añadido* para representar fielmente goles
/// en prolongación de los 45' o 90' (p. ej. "45+5'" se modela como
/// `minute: 45, extraTime: 5`).
struct MatchEvent: Codable, Hashable {

    /// Tipo de evento (gol, tarjeta, etc.).
    let type: MatchEventType

    /// Minuto regular del partido (1–120).
    let minute: Int

    /// Minutos adicionales sobre el tiempo regular. `nil` cuando el evento
    /// ocurre dentro del minuto reglamentario.
    let extraTime: Int?

    /// Inicializador completo.
    /// - Parameters:
    ///   - type: Tipo de evento.
    ///   - minute: Minuto regular.
    ///   - extraTime: Tiempo añadido opcional.
    init(type: MatchEventType, minute: Int, extraTime: Int? = nil) {
        self.type = type
        self.minute = minute
        self.extraTime = extraTime
    }

    enum CodingKeys: String, CodingKey {
        case type, minute, extraTime
    }

    /// Decodificación tolerante: `extraTime` se trata como opcional para
    /// preservar compatibilidad con cachés/JSON antiguos sin el campo.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try c.decode(MatchEventType.self, forKey: .type)
        self.minute = try c.decode(Int.self, forKey: .minute)
        self.extraTime = try c.decodeIfPresent(Int.self, forKey: .extraTime)
    }

    /// Crea un evento de gol.
    /// - Parameters:
    ///   - minute: Minuto regular.
    ///   - extra: Tiempo añadido opcional.
    static func goal(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .goal, minute: minute, extraTime: extra)
    }

    /// Crea un evento de gol de penalti.
    static func penalty(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .penalty, minute: minute, extraTime: extra)
    }

    /// Crea un evento de gol en propia puerta.
    static func ownGoal(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .ownGoal, minute: minute, extraTime: extra)
    }

    /// Crea un evento de tarjeta amarilla.
    static func yellow(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .yellow, minute: minute, extraTime: extra)
    }

    /// Crea un evento de tarjeta roja directa.
    static func red(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .red, minute: minute, extraTime: extra)
    }

    /// Crea un evento de entrada al campo.
    /// - Parameters:
    ///   - minute: Minuto en el que el jugador entró desde el banquillo.
    ///   - extra: Tiempo añadido opcional.
    static func subIn(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .subIn, minute: minute, extraTime: extra)
    }

    /// Crea un evento de salida del campo (sustitución del jugador).
    /// - Parameters:
    ///   - minute: Minuto en el que el jugador fue sustituido.
    ///   - extra: Tiempo añadido opcional.
    static func subOut(_ minute: Int, extra: Int? = nil) -> MatchEvent {
        .init(type: .subOut, minute: minute, extraTime: extra)
    }

    /// Texto del minuto formateado para la UI (p. ej. "31'", "45+5'").
    var displayMinute: String {
        if let extraTime {
            return "\(minute)+\(extraTime)'"
        }
        return "\(minute)'"
    }
}

// MARK: - LineupPlayer

/// Jugador concreto de la alineación de un equipo con los eventos del partido.
struct LineupPlayer: Codable, Identifiable, Hashable {
    /// Dorsal del jugador.
    let number: Int
    /// Nombre del jugador (nombre propio, no se localiza).
    let name: String
    /// Posición abreviada en español: "POR", "DEF", "MED", "DEL".
    let position: String
    /// `true` si arrancó como titular; `false` si entró desde el banquillo.
    let isStarter: Bool
    /// Eventos del jugador durante el partido (vacío si no participó en ninguno).
    let events: [MatchEvent]

    /// Identificador estable combinando dorsal y nombre.
    var id: String { "\(number)|\(name)" }

    /// Inicializador conveniente con `events` por defecto vacío.
    init(number: Int,
         name: String,
         position: String,
         isStarter: Bool,
         events: [MatchEvent] = []) {
        self.number = number
        self.name = name
        self.position = position
        self.isStarter = isStarter
        self.events = events
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case number, name, position, isStarter, events
    }

    /// Decodificador manual: el campo `events` es opcional en el JSON remoto
    /// (los jugadores sin eventos pueden omitirlo).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.number = try c.decode(Int.self, forKey: .number)
        self.name = try c.decode(String.self, forKey: .name)
        self.position = try c.decode(String.self, forKey: .position)
        self.isStarter = try c.decode(Bool.self, forKey: .isStarter)
        self.events = try c.decodeIfPresent([MatchEvent].self, forKey: .events) ?? []
    }

    // MARK: Factorías

    /// Construye un jugador titular.
    static func starter(_ n: Int,
                        _ name: String,
                        _ pos: String,
                        _ events: [MatchEvent] = []) -> LineupPlayer {
        LineupPlayer(number: n, name: name, position: pos, isStarter: true, events: events)
    }

    /// Construye un jugador suplente.
    static func sub(_ n: Int,
                    _ name: String,
                    _ pos: String,
                    _ events: [MatchEvent] = []) -> LineupPlayer {
        LineupPlayer(number: n, name: name, position: pos, isStarter: false, events: events)
    }
}

// MARK: - TeamLineup

/// Alineación completa de un equipo en un partido concreto.
struct TeamLineup: Codable, Hashable {
    /// Formación táctica desplegada (por ejemplo "4-3-3").
    let formation: String
    /// Jugadores que participaron en el partido (titulares + suplentes utilizados).
    let players: [LineupPlayer]

    /// Subconjunto de titulares ordenados según se introdujeron.
    var starters: [LineupPlayer] { players.filter { $0.isStarter } }
    /// Subconjunto de suplentes que entraron al campo.
    var substitutes: [LineupPlayer] { players.filter { !$0.isStarter } }
}

// MARK: - MatchDetails

/// Detalles completos disponibles para un partido ya jugado.
struct MatchDetails: Codable, Hashable {
    let homeLineup: TeamLineup
    let awayLineup: TeamLineup
}

// MARK: - Match

/// Representa un partido del Mundial 2026 con sus metadatos y, opcionalmente,
/// el detalle de alineaciones y eventos cuando ya se ha jugado.
struct Match: Identifiable, Codable {

    // MARK: Propiedades

    /// Identificador en memoria (no se serializa: cada decodificación genera uno nuevo).
    let id: UUID
    /// Hora local de Madrid en formato `HH:mm`.
    let time: String
    /// Nombre del equipo local. Puede llevar prefijo emoji (p. ej. "🇪🇸 España").
    let home: String
    /// Nombre del equipo visitante. Vacío para partidos placeholder ("Cuartos 1").
    let away: String
    /// Etiqueta del grupo o fase a la que pertenece el partido: "A"–"L", "1/16",
    /// "CF", "SF", "3P" o "FINAL".
    let group: String
    /// Canal de televisión por el que se retransmite.
    let tv: TVChannel
    /// `true` cuando el partido se ha disputado y hay resultado oficial.
    let done: Bool
    /// Resultado final en formato "G-G" si el partido está finalizado.
    let result: String?
    /// `true` si participa la selección española (para destacar el partido).
    let esp: Bool
    /// Alineaciones y eventos del partido, presentes sólo cuando se ha jugado.
    let details: MatchDetails?
    /// Nombre del estadio donde se disputa el partido (p. ej. "Estadio Azteca").
    let stadium: String?
    /// Ciudad de la sede, opcionalmente con país ("Inglewood, EE.UU.").
    let venueCity: String?

    // MARK: Inicializador

    init(time: String,
         home: String,
         away: String,
         group: String,
         tv: TVChannel,
         done: Bool,
         result: String? = nil,
         esp: Bool = false,
         details: MatchDetails? = nil,
         stadium: String? = nil,
         venueCity: String? = nil) {
        self.id = UUID()
        self.time = time
        self.home = home
        self.away = away
        self.group = group
        self.tv = tv
        self.done = done
        self.result = result
        self.esp = esp
        self.details = details
        self.stadium = stadium
        self.venueCity = venueCity
    }

    // MARK: Codable

    enum CodingKeys: String, CodingKey {
        case time, home, away, group, tv, done, result, esp, details, stadium, venueCity
    }

    init(from decoder: Decoder) throws {
        // Cada decodificación crea un id nuevo: las identidades se mantienen vivas
        // únicamente durante la sesión y no se persisten entre actualizaciones remotas.
        self.id = UUID()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.time = try c.decode(String.self, forKey: .time)
        self.home = try c.decode(String.self, forKey: .home)
        self.away = try c.decode(String.self, forKey: .away)
        self.group = try c.decode(String.self, forKey: .group)
        self.tv = try c.decode(TVChannel.self, forKey: .tv)
        self.done = try c.decode(Bool.self, forKey: .done)
        self.result = try c.decodeIfPresent(String.self, forKey: .result)
        self.esp = try c.decodeIfPresent(Bool.self, forKey: .esp) ?? false
        self.details = try c.decodeIfPresent(MatchDetails.self, forKey: .details)
        self.stadium = try c.decodeIfPresent(String.self, forKey: .stadium)
        self.venueCity = try c.decodeIfPresent(String.self, forKey: .venueCity)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(time, forKey: .time)
        try c.encode(home, forKey: .home)
        try c.encode(away, forKey: .away)
        try c.encode(group, forKey: .group)
        try c.encode(tv, forKey: .tv)
        try c.encode(done, forKey: .done)
        try c.encodeIfPresent(result, forKey: .result)
        try c.encode(esp, forKey: .esp)
        try c.encodeIfPresent(details, forKey: .details)
        try c.encodeIfPresent(stadium, forKey: .stadium)
        try c.encodeIfPresent(venueCity, forKey: .venueCity)
    }

    // MARK: Helpers de presentación

    /// `true` si este partido es la gran final.
    var isFinal: Bool { group == "FINAL" }

    /// Fase real del partido derivada del campo `group`.
    ///
    /// Permite filtrar a nivel de partido: aunque un día esté marcado como
    /// `phase: .grupos`, puede contener el play-in 1/16 del 28 de junio cuyo
    /// `group` es "1/16".
    var phase: Phase {
        switch group {
        case "1/16": return .dieciseisavos
        case "1/8": return .octavos
        case "CF": return .cuartos
        case "SF": return .semis
        case "3P", "FINAL": return .final
        default: return .grupos
        }
    }

    /// `true` cuando conviene mostrar "Grupo X" debajo del nombre del partido
    /// (sólo para grupos A–L, no para fases eliminatorias).
    var showsGroupLabel: Bool {
        guard result == nil, !group.isEmpty else { return false }
        if group.count > 2 { return false }
        return group != "CF" && group != "SF" && group != "3P"
    }

    /// `true` cuando los dos equipos están ya confirmados.
    /// Si es `false`, el partido es un placeholder de bracket pendiente
    /// (p. ej. "1º Grupo A").
    var hasConfirmedTeams: Bool {
        let placeholders = ["1º", "2º", "3º", "Gan.", "Cuartos", "Semifinal", "3er"]
        if placeholders.contains(where: { home.contains($0) }) { return false }
        if !away.isEmpty, placeholders.contains(where: { away.contains($0) }) { return false }
        return true
    }
}

// MARK: - MatchDay

/// Conjunto de partidos disputados en una misma fecha.
struct MatchDay: Identifiable, Codable {
    /// Identificador estable basado en la fecha.
    var id: String { date }
    /// Fecha en formato ISO `yyyy-MM-dd`.
    let date: String
    /// Fase predominante del día (usada para el badge de la cabecera).
    let phase: Phase
    /// Partidos disputados ese día, en orden cronológico.
    let games: [Match]
}

// MARK: - MatchSnapshot

/// Envoltorio del JSON descargado por el `MatchStore` desde el endpoint remoto.
struct MatchSnapshot: Codable {
    /// Marca de tiempo de la última actualización publicada.
    let lastUpdated: Date?
    /// Lista completa de jornadas del Mundial.
    let matchDays: [MatchDay]
}

// MARK: - SelectedMatch

/// Item identificable para presentar la hoja de detalle a través de `.sheet(item:)`.
struct SelectedMatch: Identifiable {
    let match: Match
    let date: String
    let phase: Phase
    var id: UUID { match.id }
}

// MARK: - Color hex

extension Color {
    /// Crea un `Color` a partir de un literal RGB sin canal alfa.
    /// - Parameter hex: Valor `0xRRGGBB` (por ejemplo `0xC8A84B`).
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8) & 0xFF) / 255.0
        let b = Double(hex & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
