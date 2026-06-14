//
// export_snapshot.swift
// CalendarMundial
//
// Exporta el snapshot completo del calendario del Mundial 2026 como JSON,
// listo para servir desde la URL remota configurada en MatchStore.remoteURL.
//
// Uso:
//   swift scripts/export_snapshot.swift [ruta_salida]
//
// Por defecto escribe en data/mundial2026.json (relativo al directorio actual).
//
// Este archivo es la "fuente de verdad" para regenerar el JSON tras cada
// actualización de resultados; mantén su contenido alineado con
// CalendarMundial/CalendarMundial/MatchesData.swift y MatchDetailsData.swift.
//

import Foundation

// MARK: - Tipos slim Codable (sin SwiftUI)

enum TVChannel: String, Codable {
    case both = "BOTH"
    case dazn = "DAZN"
}

enum Phase: String, Codable {
    case grupos = "Grupos"
    case dieciseisavos = "1/16"
    case octavos = "1/8"
    case cuartos = "Cuartos"
    case semis = "Semis"
    case final = "Final"
}

enum MatchEventType: String, Codable {
    case goal
    case penalty
    case ownGoal = "own_goal"
    case yellow
    case red
    case subIn = "sub_in"
    case subOut = "sub_out"
}

struct MatchEvent: Codable {
    let type: MatchEventType
    let minute: Int
    let extraTime: Int?

    init(type: MatchEventType, minute: Int, extraTime: Int? = nil) {
        self.type = type
        self.minute = minute
        self.extraTime = extraTime
    }

    enum CodingKeys: String, CodingKey { case type, minute, extraTime }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encode(minute, forKey: .minute)
        try c.encodeIfPresent(extraTime, forKey: .extraTime)
    }

    static func goal(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .goal, minute: m, extraTime: extra) }
    static func penalty(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .penalty, minute: m, extraTime: extra) }
    static func ownGoal(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .ownGoal, minute: m, extraTime: extra) }
    static func yellow(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .yellow, minute: m, extraTime: extra) }
    static func red(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .red, minute: m, extraTime: extra) }
    static func subIn(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .subIn, minute: m, extraTime: extra) }
    static func subOut(_ m: Int, extra: Int? = nil) -> MatchEvent { .init(type: .subOut, minute: m, extraTime: extra) }
}

struct LineupPlayer: Codable {
    let number: Int
    let name: String
    let position: String
    let isStarter: Bool
    let events: [MatchEvent]

    static func starter(_ n: Int, _ name: String, _ pos: String, _ events: [MatchEvent] = []) -> LineupPlayer {
        LineupPlayer(number: n, name: name, position: pos, isStarter: true, events: events)
    }
    static func sub(_ n: Int, _ name: String, _ pos: String, _ events: [MatchEvent] = []) -> LineupPlayer {
        LineupPlayer(number: n, name: name, position: pos, isStarter: false, events: events)
    }
}

struct TeamLineup: Codable {
    let formation: String
    let players: [LineupPlayer]
}

struct MatchDetails: Codable {
    let homeLineup: TeamLineup
    let awayLineup: TeamLineup
}

struct Match: Codable {
    let time: String
    let home: String
    let away: String
    let group: String
    let tv: TVChannel
    let done: Bool
    let result: String?
    let esp: Bool
    let details: MatchDetails?

    init(time: String, home: String, away: String, group: String, tv: TVChannel,
         done: Bool, result: String? = nil, esp: Bool = false, details: MatchDetails? = nil) {
        self.time = time
        self.home = home
        self.away = away
        self.group = group
        self.tv = tv
        self.done = done
        self.result = result
        self.esp = esp
        self.details = details
    }

    enum CodingKeys: String, CodingKey {
        case time, home, away, group, tv, done, result, esp, details
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
    }
}

struct MatchDay: Codable {
    let date: String
    let phase: Phase
    let games: [Match]
}

struct MatchSnapshot: Codable {
    let lastUpdated: Date?
    let matchDays: [MatchDay]
}

// MARK: - Detalles de los 5 partidos jugados

let mexicoVsSouthAfrica = MatchDetails(
    homeLineup: TeamLineup(formation: "4-1-2-3", players: [
        .starter(1, "Raúl Rangel", "POR"),
        .starter(3, "César Montes", "DEF", [.red(90, extra: 2)]),
        .starter(5, "Johan Vásquez", "DEF"),
        .starter(15, "Israel Reyes", "DEF"),
        .starter(23, "Jesús Gallardo", "DEF"),
        .starter(14, "Erik Lira", "MED"),
        .starter(16, "Álvaro Fidalgo", "MED"),
        .starter(8, "Brian Gutiérrez", "MED", [.yellow(22)]),
        .starter(11, "Roberto Alvarado", "DEL"),
        .starter(9, "Raúl Jiménez", "DEL", [.goal(67)]),
        .starter(7, "Julián Quiñones", "DEL", [.goal(9), .subOut(79)]),
        .sub(25, "Alexis Vega", "DEL", [.subIn(79)]),
        .sub(13, "Memo Ochoa", "POR"),
        .sub(12, "Carlos Acevedo", "POR"),
        .sub(2, "Jorge Sánchez", "DEF"),
        .sub(6, "Luis Romo", "MED"),
        .sub(17, "Mateo Chávez", "DEF"),
        .sub(18, "César Huerta", "DEL"),
        .sub(4, "Edson Álvarez", "MED"),
        .sub(19, "Luis Chávez", "MED"),
        .sub(20, "Obed Vargas", "MED"),
        .sub(10, "Orbelín Pineda", "MED"),
        .sub(21, "Armando González", "DEL"),
        .sub(24, "Guillermo Martínez", "DEL"),
        .sub(22, "Santiago Giménez", "DEL")
    ]),
    awayLineup: TeamLineup(formation: "5-3-2", players: [
        .starter(1, "Ronwen Williams", "POR"),
        .starter(4, "Aubrey Modiba", "DEF"),
        .starter(5, "Mbekezeli Mbokazi", "DEF"),
        .starter(6, "Nkosinathi Sibisi", "DEF"),
        .starter(19, "Khuliso Mudau", "DEF"),
        .starter(3, "Ime Okon", "DEF"),
        .starter(8, "Teboho Mokoena", "MED", [.yellow(16)]),
        .starter(14, "Sphephelo Sithole", "MED", [.red(50)]),
        .starter(15, "Jayden Adams", "MED"),
        .starter(10, "Lyle Foster", "DEL"),
        .starter(9, "Iqraam Rayners", "DEL"),
        .sub(11, "Themba Zwane", "MED", [.subIn(70), .red(84)]),
        .sub(13, "Evidence Makgopa", "DEL", [.subIn(76)]),
        .sub(18, "Oswin Appollis", "DEL", [.subIn(77)]),
        .sub(7, "Percy Tau", "DEL"),
        .sub(2, "Mihlali Mayambela", "DEL"),
        .sub(21, "Bongokuhle Hlongwane", "DEL"),
        .sub(22, "Bafana Mbatha", "MED"),
        .sub(24, "Patrick Maswanganyi", "MED"),
        .sub(20, "Thabang Matuludi", "DEF"),
        .sub(23, "Innocent Maela", "DEF"),
        .sub(16, "Ricardo Goss", "POR"),
        .sub(12, "Sage Stephens", "POR")
    ])
)

let koreaVsCzechia = MatchDetails(
    homeLineup: TeamLineup(formation: "3-4-2-1", players: [
        .starter(21, "Kim Sung-gyu", "POR"),
        .starter(20, "Lee Han-beom", "DEF"),
        .starter(4, "Kim Min-jae", "DEF"),
        .starter(17, "Lee Gi-hyuk", "DEF", [.yellow(85)]),
        .starter(2, "Seol Young-woo", "MED"),
        .starter(6, "Hwang In-beom", "MED", [.goal(67)]),
        .starter(15, "Paik Seung-ho", "MED"),
        .starter(22, "Lee Tae-seok", "MED", [.subOut(70)]),
        .starter(10, "Lee Kang-in", "MED"),
        .starter(11, "Lee Jae-sung", "MED"),
        .starter(7, "Son Heung-min", "DEL"),
        .sub(18, "Oh Hyeon-gyu", "DEL", [.subIn(63), .goal(80)]),
        .sub(14, "Eom Ji-sung", "MED", [.subIn(70)]),
        .sub(16, "Park Jin-seop", "MED", [.subIn(75)]),
        .sub(8, "Kim Jin-gyu", "MED"),
        .sub(3, "Kim Jin-su", "DEF"),
        .sub(5, "Kim Young-gwon", "DEF"),
        .sub(9, "Cho Gue-sung", "DEL"),
        .sub(13, "Hong Hyun-suk", "MED"),
        .sub(19, "Bae Jun-ho", "DEL"),
        .sub(23, "Joo Min-kyu", "DEL"),
        .sub(1, "Jo Hyeon-woo", "POR"),
        .sub(12, "Cho Hyun-woo", "POR")
    ]),
    awayLineup: TeamLineup(formation: "3-4-2-1", players: [
        .starter(1, "Matěj Kovář", "POR"),
        .starter(5, "Štěpán Chaloupek", "DEF"),
        .starter(21, "Robin Hranáč", "DEF"),
        .starter(15, "Ladislav Krejčí", "DEF", [.goal(59)]),
        .starter(4, "Vladimír Coufal", "MED"),
        .starter(6, "Tomáš Souček", "MED"),
        .starter(8, "Alexandr Sojka", "MED", [.subOut(70)]),
        .starter(14, "Jaroslav Zelený", "MED"),
        .starter(18, "Lukáš Provod", "MED", [.subOut(78)]),
        .starter(17, "Pavel Šulc", "MED"),
        .starter(11, "Patrik Schick", "DEL", [.subOut(85)]),
        .sub(9, "Mojmír Chytil", "DEL", [.subIn(70)]),
        .sub(10, "Michal Sadílek", "MED", [.subIn(78)]),
        .sub(23, "Tomáš Chorý", "DEL", [.subIn(85)]),
        .sub(20, "Ondřej Lingr", "MED"),
        .sub(19, "Václav Černý", "DEL"),
        .sub(7, "Antonín Barák", "MED"),
        .sub(13, "David Doudera", "DEF"),
        .sub(22, "Adam Hložek", "DEL"),
        .sub(2, "David Jurásek", "DEF"),
        .sub(3, "Filip Panák", "DEF"),
        .sub(12, "Jindřich Staněk", "POR"),
        .sub(16, "Vítězslav Jaroš", "POR")
    ])
)

let canadaVsBosnia = MatchDetails(
    homeLineup: TeamLineup(formation: "4-4-2", players: [
        .starter(16, "Maxime Crépeau", "POR"),
        .starter(2, "Alistair Johnston", "DEF"),
        .starter(4, "Luc De Fougerolles", "DEF"),
        .starter(12, "Derek Cornelius", "DEF"),
        .starter(22, "Richie Laryea", "DEF"),
        .starter(11, "Tajon Buchanan", "MED"),
        .starter(6, "Ismaël Koné", "MED"),
        .starter(7, "Stephen Eustáquio", "MED"),
        .starter(10, "Liam Millar", "MED", [.subOut(76)]),
        .starter(20, "Jonathan David", "DEL"),
        .starter(9, "Tani Oluwaseyi", "DEL"),
        .sub(17, "Cyle Larin", "DEL", [.subIn(76), .goal(78)]),
        .sub(18, "Promise David", "DEL", [.subIn(76)]),
        .sub(19, "Alphonso Davies", "MED"),
        .sub(14, "Ali Ahmed", "MED"),
        .sub(8, "Mathieu Choinière", "MED"),
        .sub(13, "Jacob Shaffelburg", "DEL"),
        .sub(15, "Moïse Bombito", "DEF"),
        .sub(3, "Joel Waterman", "DEF"),
        .sub(5, "Alfie Jones", "DEF"),
        .sub(21, "Jonathan Osorio", "MED"),
        .sub(23, "Niko Sigur", "DEF"),
        .sub(26, "Nathan Saliba", "MED"),
        .sub(25, "Jayden Nelson", "DEL"),
        .sub(1, "Dayne St. Clair", "POR"),
        .sub(24, "Owen Goodman", "POR")
    ]),
    awayLineup: TeamLineup(formation: "4-2-3-1", players: [
        .starter(1, "Nikola Vasilj", "POR"),
        .starter(13, "Amar Dedić", "DEF"),
        .starter(4, "Nikola Katić", "DEF"),
        .starter(5, "Tarik Muharemović", "DEF"),
        .starter(14, "Sead Kolašinac", "DEF"),
        .starter(7, "Esmir Bajraktarević", "MED"),
        .starter(8, "Ivan Bašić", "MED"),
        .starter(10, "Benjamin Tahirović", "MED"),
        .starter(11, "Amar Memić", "MED"),
        .starter(18, "Ermedin Demirović", "DEL"),
        .starter(19, "Jovo Lukić", "DEL", [.goal(21)]),
        .sub(9, "Edin Džeko", "DEL"),
        .sub(15, "Haris Tabaković", "DEL"),
        .sub(3, "Nihad Mujakić", "DEF"),
        .sub(2, "Dennis Hadžikadunić", "DEF"),
        .sub(16, "Armin Gigović", "MED"),
        .sub(17, "Samed Bazdar", "DEL"),
        .sub(6, "Ivan Šunjić", "MED"),
        .sub(20, "Amir Hadžiahmetović", "MED"),
        .sub(21, "Dženis Burnić", "MED"),
        .sub(22, "Kerim Alajbegović", "MED"),
        .sub(23, "Stjepan Radeljić", "DEF"),
        .sub(25, "Arjan Malić", "MED"),
        .sub(26, "Ermin Mahmić", "DEL"),
        .sub(12, "Mladen Jurkas", "POR"),
        .sub(24, "Martin Zlomislić", "POR")
    ])
)

let usaVsParaguay = MatchDetails(
    homeLineup: TeamLineup(formation: "3-4-2-1", players: [
        .starter(24, "Matt Freese", "POR"),
        .starter(16, "Alex Freeman", "DEF"),
        .starter(13, "Tim Ream", "DEF"),
        .starter(3, "Chris Richards", "DEF"),
        .starter(2, "Sergiño Dest", "MED", [.subOut(71)]),
        .starter(4, "Tyler Adams", "MED"),
        .starter(17, "Malik Tillman", "MED", [.subOut(81)]),
        .starter(5, "Antonee Robinson", "MED"),
        .starter(8, "Weston McKennie", "MED", [.yellow(42)]),
        .starter(10, "Christian Pulisic", "DEL", [.subOut(45)]),
        .starter(20, "Folarin Balogun", "DEL", [.goal(31), .goal(45, extra: 5), .subOut(71)]),
        .sub(14, "Sebastian Berhalter", "MED", [.subIn(45)]),
        .sub(21, "Tim Weah", "DEL", [.subIn(71)]),
        .sub(9, "Ricardo Pepi", "DEL", [.subIn(71)]),
        .sub(7, "Gio Reyna", "DEL", [.subIn(81), .goal(90, extra: 8)]),
        .sub(1, "Matt Turner", "POR"),
        .sub(25, "Chris Brady", "POR"),
        .sub(6, "Auston Trusty", "DEF"),
        .sub(11, "Brenden Aaronson", "DEL"),
        .sub(12, "Miles Robinson", "DEF"),
        .sub(15, "Cristian Roldan", "MED"),
        .sub(18, "Max Arfsten", "DEF"),
        .sub(19, "Haji Wright", "DEL"),
        .sub(22, "Mark McKenzie", "DEF"),
        .sub(23, "Joe Scally", "DEF"),
        .sub(26, "Alex Zendejas", "DEL")
    ]),
    awayLineup: TeamLineup(formation: "4-3-3", players: [
        .starter(12, "Orlando Gill", "POR"),
        .starter(4, "Juan Cáceres", "DEF", [.subOut(78)]),
        .starter(15, "Gustavo Gómez", "DEF"),
        .starter(3, "Omar Alderete", "DEF"),
        .starter(6, "Junior Alonso", "DEF"),
        .starter(8, "Diego Gómez", "MED", [.subOut(78)]),
        .starter(14, "Andrés Cubas", "MED"),
        .starter(16, "Damián Bobadilla", "MED", [.ownGoal(7), .subOut(45)]),
        .starter(10, "Miguel Almirón", "MED", [.subOut(78)]),
        .starter(9, "Antonio Sanabria", "DEL", [.subOut(61)]),
        .starter(19, "Julio Enciso", "DEL"),
        .sub(18, "Maurício", "DEL", [.subIn(45), .goal(73)]),
        .sub(11, "Alex Arce", "DEL", [.subIn(61), .yellow(75)]),
        .sub(22, "Gustavo Velázquez", "DEF", [.subIn(78)]),
        .sub(7, "Ramón Sosa", "DEL", [.subIn(78)]),
        .sub(17, "Alejandro Romero", "MED", [.subIn(78)]),
        .sub(1, "Gabriel Fernández", "POR"),
        .sub(23, "Anthony Silva", "POR"),
        .sub(5, "Fabián Balbuena", "DEF"),
        .sub(13, "Juan Canale", "DEF"),
        .sub(20, "Braian Ojeda", "MED"),
        .sub(21, "Gerardo Ávalos", "DEL")
    ])
)

let brazilVsMorocco = MatchDetails(
    homeLineup: TeamLineup(formation: "4-3-3", players: [
        .starter(1, "Alisson", "POR"),
        .starter(13, "Roger Ibañez", "DEF", [.subOut(46)]),
        .starter(4, "Marquinhos", "DEF"),
        .starter(15, "Gabriel Magalhães", "DEF"),
        .starter(6, "Douglas Santos", "DEF"),
        .starter(5, "Casemiro", "MED", [.subOut(46)]),
        .starter(8, "Bruno Guimarães", "MED"),
        .starter(10, "Lucas Paquetá", "MED"),
        .starter(7, "Vinicius Júnior", "DEL", [.goal(72)]),
        .starter(11, "Raphinha", "DEL"),
        .starter(9, "Igor Thiago", "DEL"),
        .sub(17, "Fabinho", "MED", [.subIn(46)]),
        .sub(2, "Danilo", "DEF", [.subIn(46)]),
        .sub(18, "Neymar", "DEL"),
        .sub(16, "Léo Pereira", "DEF"),
        .sub(23, "Ederson", "POR"),
        .sub(12, "Bento", "POR"),
        .sub(14, "Endrick", "DEL"),
        .sub(19, "Andreas Pereira", "MED"),
        .sub(20, "João Gomes", "MED"),
        .sub(21, "Vítor Roque", "DEL"),
        .sub(22, "Yan Couto", "DEF"),
        .sub(24, "Wendell", "DEF"),
        .sub(25, "Léo Ortiz", "DEF"),
        .sub(26, "Savinho", "DEL")
    ]),
    awayLineup: TeamLineup(formation: "4-3-3", players: [
        .starter(1, "Yassine Bono", "POR"),
        .starter(2, "Achraf Hakimi", "DEF"),
        .starter(6, "Romain Saïss", "DEF"),
        .starter(5, "Nayef Aguerd", "DEF"),
        .starter(3, "Noussair Mazraoui", "DEF"),
        .starter(4, "Sofyan Amrabat", "MED"),
        .starter(8, "Azzedine Ounahi", "MED"),
        .starter(21, "Brahim Díaz", "MED"),
        .starter(11, "Ismael Saibari", "MED", [.goal(21)]),
        .starter(19, "Youssef En-Nesyri", "DEL"),
        .starter(7, "Hakim Ziyech", "DEL"),
        .sub(9, "Ayoub El Kaabi", "DEL"),
        .sub(10, "Bilal El Khannouss", "MED"),
        .sub(12, "Munir El Kajoui", "POR"),
        .sub(13, "Eliesse Ben Seghir", "DEL"),
        .sub(14, "Amine Adli", "DEL"),
        .sub(15, "Adam Masina", "DEF"),
        .sub(16, "Achraf Dari", "DEF"),
        .sub(17, "Hamza Igamane", "DEL"),
        .sub(18, "Bilal Nadir", "MED"),
        .sub(20, "Achraf El Bouchiouy", "MED"),
        .sub(22, "Mehdi Benatia", "DEF"),
        .sub(23, "Ahmed Reda Tagnaouti", "POR")
    ])
)

let scotlandVsHaiti = MatchDetails(
    homeLineup: TeamLineup(formation: "4-2-3-1", players: [
        .starter(1, "Angus Gunn", "POR"),
        .starter(2, "Aaron Hickey", "DEF"),
        .starter(5, "Grant Hanley", "DEF"),
        .starter(4, "Jack Hendry", "DEF"),
        .starter(3, "Andrew Robertson", "DEF"),
        .starter(6, "Billy Gilmour", "MED"),
        .starter(8, "Callum McGregor", "MED"),
        .starter(17, "John McGinn", "MED", [.goal(28)]),
        .starter(11, "Scott McTominay", "MED"),
        .starter(7, "Ben Doak", "DEL"),
        .starter(9, "Che Adams", "DEL"),
        .sub(14, "Ryan Christie", "MED"),
        .sub(10, "Tommy Conway", "DEL"),
        .sub(15, "Lewis Ferguson", "MED"),
        .sub(16, "Lewis Morgan", "DEL"),
        .sub(18, "George Hirst", "DEL"),
        .sub(19, "James Forrest", "DEL"),
        .sub(20, "Ryan Gauld", "MED"),
        .sub(12, "Cieran Slicker", "POR"),
        .sub(13, "Robby McCrorie", "POR"),
        .sub(21, "Anthony Ralston", "DEF"),
        .sub(22, "Max Johnston", "DEF"),
        .sub(23, "Scott McKenna", "DEF"),
        .sub(24, "Kieran Tierney", "DEF"),
        .sub(25, "Liam Cooper", "DEF"),
        .sub(26, "Ross McCrorie", "MED")
    ]),
    awayLineup: TeamLineup(formation: "4-4-2", players: [
        .starter(1, "Johny Placide", "POR"),
        .starter(2, "Ricardo Adé", "DEF"),
        .starter(4, "Thomas Delcroix", "DEF"),
        .starter(3, "Garven Metusala", "DEF"),
        .starter(5, "Carlens Arcus", "DEF"),
        .starter(8, "Jean Bellegarde", "MED"),
        .starter(7, "Danley Jean Jacques", "MED"),
        .starter(10, "Deedson Louicius", "MED", [.subOut(61)]),
        .starter(11, "Frantzdy Pierrot", "DEL"),
        .starter(9, "Jean-Eudes Aholou", "MED"),
        .starter(20, "Jean-Ricner Bellegarde", "DEL"),
        .sub(17, "Donovan Providence", "MED", [.subIn(61)]),
        .sub(13, "Alexandre Pierre", "MED"),
        .sub(15, "Markhus Lacroix", "DEF"),
        .sub(16, "Jean-Kevin Duverne", "DEF"),
        .sub(18, "Wilguens Paugain", "MED"),
        .sub(19, "Carl Sainte", "DEL"),
        .sub(21, "Dominique Simon", "DEL"),
        .sub(22, "Woodensky Pierre", "DEL"),
        .sub(23, "Derrick Etienne", "DEL"),
        .sub(14, "Duckens Nazon", "DEL"),
        .sub(25, "Lenny Joseph", "DEL"),
        .sub(26, "Yassin Fortune", "DEL"),
        .sub(12, "Josue Duverger", "POR"),
        .sub(24, "Keeto Thermoncy", "POR")
    ])
)

let australiaVsTurkey = MatchDetails(
    homeLineup: TeamLineup(formation: "5-4-1", players: [
        .starter(1, "Joe Gauci", "POR"),
        .starter(15, "Jason Geria", "DEF"),
        .starter(5, "Harry Souttar", "DEF"),
        .starter(6, "Cameron Burgess", "DEF"),
        .starter(4, "Alessandro Circati", "DEF"),
        .starter(3, "Jordan Bos", "DEF", [.subOut(75)]),
        .starter(7, "Nestory Irankunda", "MED", [.goal(27)]),
        .starter(8, "Aiden O'Neill", "MED"),
        .starter(10, "Connor Metcalfe", "MED", [.goal(70)]),
        .starter(11, "Jacob Italiano", "MED"),
        .starter(9, "Paul Okon-Engstler", "DEL", [.subOut(84)]),
        .sub(2, "Aziz Behich", "DEF", [.subIn(75)]),
        .sub(14, "Jackson Irvine", "MED", [.subIn(84)]),
        .sub(13, "Nishan Velupillay", "DEL"),
        .sub(16, "Riley McGree", "MED"),
        .sub(17, "Hayden Matthews", "DEF"),
        .sub(18, "Mohamed Toure", "DEL"),
        .sub(19, "Adam Taggart", "DEL"),
        .sub(20, "Lewis Miller", "DEF"),
        .sub(21, "Anthony Caceres", "MED"),
        .sub(22, "Daniel Arzani", "DEL"),
        .sub(23, "Patrick Yazbek", "MED"),
        .sub(12, "Maty Ryan", "POR"),
        .sub(24, "Steven Hall", "POR")
    ]),
    awayLineup: TeamLineup(formation: "4-2-3-1", players: [
        .starter(1, "Uğurcan Çakır", "POR"),
        .starter(2, "Zeki Çelik", "DEF"),
        .starter(4, "Abdülkerim Bardakçı", "DEF"),
        .starter(5, "Merih Demiral", "DEF"),
        .starter(3, "Ferdi Kadıoğlu", "DEF"),
        .starter(6, "İsmail Yüksek", "MED"),
        .starter(8, "Orkun Kökçü", "MED"),
        .starter(10, "Hakan Çalhanoğlu", "MED"),
        .starter(11, "Arda Güler", "MED"),
        .starter(7, "Kerem Aktürkoğlu", "DEL", [.subOut(85)]),
        .starter(9, "Burak Yılmaz", "DEL", [.subOut(46)]),
        .sub(20, "Kenan Yıldız", "DEL", [.subIn(46)]),
        .sub(21, "Doğukan Gül", "MED", [.subIn(85)]),
        .sub(13, "Hakan Kadıoğlu", "DEF"),
        .sub(14, "Salih Özcan", "MED"),
        .sub(15, "Çağlar Söyüncü", "DEF"),
        .sub(16, "Yusuf Yazıcı", "MED"),
        .sub(17, "Cenk Tosun", "DEL"),
        .sub(18, "Halil Dervişoğlu", "DEL"),
        .sub(19, "Eren Elmalı", "DEF"),
        .sub(22, "Çağlar Şahan", "MED"),
        .sub(23, "Berke Özer", "POR"),
        .sub(24, "Erkin Aydın", "DEL"),
        .sub(25, "Mert Günok", "POR")
    ])
)

let qatarVsSwitzerland = MatchDetails(
    homeLineup: TeamLineup(formation: "4-3-3", players: [
        .starter(22, "Mahmud Abunada", "POR"),
        .starter(13, "Ayoub Al Oui", "DEF"),
        .starter(2, "Pedro Miguel", "DEF"),
        .starter(16, "Boualem Khoukhi", "DEF", [.goal(90, extra: 4)]),
        .starter(3, "Homam El-Amin", "DEF"),
        .starter(14, "Issa Laye", "MED"),
        .starter(6, "Assim Madibo", "MED"),
        .starter(8, "Jassem Gaber", "MED"),
        .starter(7, "Edmílson Junior", "DEL"),
        .starter(19, "Yusuf Abdurisag", "DEL"),
        .starter(11, "Akram Afif", "DEL"),
        .sub(10, "Hassan Al-Haydos", "MED"),
        .sub(9, "Almoez Ali", "DEL"),
        .sub(18, "Abdulaziz Hatem", "MED"),
        .sub(23, "Mohammed Muntari", "DEL"),
        .sub(20, "Karim Boudiaf", "MED"),
        .sub(15, "Lucas Mendes", "DEF"),
        .sub(17, "Tahsin Mohammed", "MED"),
        .sub(4, "Sultan Al Brake", "DEF"),
        .sub(5, "Ahmed Fathy", "DEF"),
        .sub(24, "Al Hashmi Al Hussain", "MED"),
        .sub(25, "Ahmed Al Ganehi", "DEL"),
        .sub(26, "Mohammad Al Mannai", "DEL"),
        .sub(12, "Ahmed Alaa", "MED"),
        .sub(1, "Meshaal Barsham", "POR"),
        .sub(21, "Salah Zakaria", "POR")
    ]),
    awayLineup: TeamLineup(formation: "4-3-3", players: [
        .starter(1, "Gregor Kobel", "POR"),
        .starter(2, "Denis Zakaria", "DEF"),
        .starter(4, "Nico Elvedi", "DEF"),
        .starter(5, "Manuel Akanji", "DEF"),
        .starter(13, "Ricardo Rodríguez", "DEF"),
        .starter(14, "Michel Aebischer", "MED"),
        .starter(10, "Granit Xhaka", "MED"),
        .starter(15, "Remo Freuler", "MED"),
        .starter(20, "Dan Ndoye", "DEL"),
        .starter(7, "Breel Embolo", "DEL", [.penalty(17)]),
        .starter(17, "Rubén Vargas", "DEL"),
        .sub(16, "Ardon Jashari", "MED"),
        .sub(9, "Noah Okafor", "DEL"),
        .sub(18, "Cédric Itten", "DEL"),
        .sub(11, "Zeki Amdouni", "DEL"),
        .sub(19, "Fabian Rieder", "MED"),
        .sub(3, "Silvan Widmer", "DEF"),
        .sub(6, "Miro Muheim", "DEF"),
        .sub(22, "Eray Cömert", "DEF"),
        .sub(8, "Christian Fassnacht", "MED"),
        .sub(23, "Aurèle Amenda", "DEF"),
        .sub(24, "Djibril Sow", "MED"),
        .sub(25, "Luca Jaquez", "DEF"),
        .sub(26, "Johan Manzambi", "MED"),
        .sub(12, "Yvon Mvogo", "POR"),
        .sub(21, "Marvin Keller", "POR")
    ])
)

// MARK: - Calendario completo (36 jornadas)

let matchDays: [MatchDay] = [
    MatchDay(date: "2026-06-11", phase: .grupos, games: [
        Match(time: "21:00", home: "México", away: "Sudáfrica", group: "A", tv: .both, done: true, result: "2-0", details: mexicoVsSouthAfrica)
    ]),
    MatchDay(date: "2026-06-12", phase: .grupos, games: [
        Match(time: "04:00", home: "Corea del Sur", away: "Rep. Checa", group: "A", tv: .dazn, done: true, result: "2-1", details: koreaVsCzechia),
        Match(time: "21:00", home: "Canadá", away: "Bosnia Herz.", group: "B", tv: .both, done: true, result: "1-1", details: canadaVsBosnia)
    ]),
    MatchDay(date: "2026-06-13", phase: .grupos, games: [
        Match(time: "03:00", home: "EE.UU.", away: "Paraguay", group: "D", tv: .dazn, done: true, result: "4-1", details: usaVsParaguay),
        Match(time: "21:00", home: "Qatar", away: "Suiza", group: "B", tv: .dazn, done: true, result: "1-1", details: qatarVsSwitzerland)
    ]),
    MatchDay(date: "2026-06-14", phase: .grupos, games: [
        Match(time: "00:00", home: "Brasil", away: "Marruecos", group: "C", tv: .both, done: true, result: "1-1", details: brazilVsMorocco),
        Match(time: "03:00", home: "Haití", away: "Escocia", group: "C", tv: .dazn, done: true, result: "0-1", details: scotlandVsHaiti),
        Match(time: "06:00", home: "Australia", away: "Turquía", group: "D", tv: .dazn, done: true, result: "2-0", details: australiaVsTurkey),
        Match(time: "19:00", home: "Alemania", away: "Curaçao", group: "E", tv: .both, done: false),
        Match(time: "22:00", home: "Países Bajos", away: "Japón", group: "F", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-15", phase: .grupos, games: [
        Match(time: "01:00", home: "C. de Marfil", away: "Ecuador", group: "E", tv: .dazn, done: false),
        Match(time: "04:00", home: "Suecia", away: "Túnez", group: "F", tv: .dazn, done: false),
        Match(time: "18:00", home: "🇪🇸 España", away: "Cabo Verde", group: "H", tv: .both, done: false, esp: true),
        Match(time: "21:00", home: "Bélgica", away: "Egipto", group: "G", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-16", phase: .grupos, games: [
        Match(time: "00:00", home: "Arabia Saudí", away: "Uruguay", group: "H", tv: .dazn, done: false),
        Match(time: "03:00", home: "Irán", away: "Nueva Zelanda", group: "G", tv: .dazn, done: false),
        Match(time: "21:00", home: "Francia", away: "Senegal", group: "I", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-17", phase: .grupos, games: [
        Match(time: "00:00", home: "Irak", away: "Noruega", group: "I", tv: .dazn, done: false),
        Match(time: "03:00", home: "Argentina", away: "Argelia", group: "J", tv: .dazn, done: false),
        Match(time: "06:00", home: "Austria", away: "Jordania", group: "J", tv: .dazn, done: false),
        Match(time: "19:00", home: "Portugal", away: "R.D. Congo", group: "K", tv: .dazn, done: false),
        Match(time: "22:00", home: "Inglaterra", away: "Croacia", group: "L", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-18", phase: .grupos, games: [
        Match(time: "01:00", home: "Ghana", away: "Panamá", group: "L", tv: .dazn, done: false),
        Match(time: "04:00", home: "Uzbekistán", away: "Colombia", group: "K", tv: .dazn, done: false),
        Match(time: "18:00", home: "Rep. Checa", away: "Sudáfrica", group: "A", tv: .dazn, done: false),
        Match(time: "21:00", home: "Suiza", away: "Bosnia Herz.", group: "B", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-19", phase: .grupos, games: [
        Match(time: "00:00", home: "Canadá", away: "Qatar", group: "B", tv: .dazn, done: false),
        Match(time: "03:00", home: "México", away: "Corea del Sur", group: "A", tv: .dazn, done: false),
        Match(time: "21:00", home: "EE.UU.", away: "Australia", group: "D", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-20", phase: .grupos, games: [
        Match(time: "00:00", home: "Escocia", away: "Marruecos", group: "C", tv: .dazn, done: false),
        Match(time: "02:30", home: "Brasil", away: "Haití", group: "C", tv: .dazn, done: false),
        Match(time: "05:00", home: "Turquía", away: "Paraguay", group: "D", tv: .dazn, done: false),
        Match(time: "19:00", home: "Países Bajos", away: "Suecia", group: "F", tv: .both, done: false),
        Match(time: "22:00", home: "Alemania", away: "C. de Marfil", group: "E", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-21", phase: .grupos, games: [
        Match(time: "02:00", home: "Ecuador", away: "Curaçao", group: "E", tv: .dazn, done: false),
        Match(time: "06:00", home: "Túnez", away: "Japón", group: "F", tv: .dazn, done: false),
        Match(time: "18:00", home: "🇪🇸 España", away: "Arabia Saudí", group: "H", tv: .both, done: false, esp: true),
        Match(time: "21:00", home: "Bélgica", away: "Irán", group: "G", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-22", phase: .grupos, games: [
        Match(time: "00:00", home: "Uruguay", away: "Cabo Verde", group: "H", tv: .dazn, done: false),
        Match(time: "03:00", home: "Nueva Zelanda", away: "Egipto", group: "G", tv: .dazn, done: false),
        Match(time: "19:00", home: "Argentina", away: "Austria", group: "J", tv: .both, done: false),
        Match(time: "23:00", home: "Francia", away: "Irak", group: "I", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-23", phase: .grupos, games: [
        Match(time: "02:00", home: "Noruega", away: "Senegal", group: "I", tv: .dazn, done: false),
        Match(time: "05:00", home: "Jordania", away: "Argelia", group: "J", tv: .dazn, done: false),
        Match(time: "19:00", home: "Portugal", away: "Uzbekistán", group: "K", tv: .dazn, done: false),
        Match(time: "22:00", home: "Inglaterra", away: "Ghana", group: "L", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-24", phase: .grupos, games: [
        Match(time: "01:00", home: "Panamá", away: "Croacia", group: "L", tv: .dazn, done: false),
        Match(time: "04:00", home: "Colombia", away: "R.D. Congo", group: "K", tv: .dazn, done: false),
        Match(time: "21:00", home: "Suiza", away: "Canadá", group: "B", tv: .dazn, done: false),
        Match(time: "21:00", home: "Bosnia Herz.", away: "Qatar", group: "B", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-25", phase: .grupos, games: [
        Match(time: "00:00", home: "Escocia", away: "Brasil", group: "C", tv: .both, done: false),
        Match(time: "00:00", home: "Marruecos", away: "Haití", group: "C", tv: .dazn, done: false),
        Match(time: "03:00", home: "Sudáfrica", away: "Corea del Sur", group: "A", tv: .dazn, done: false),
        Match(time: "03:00", home: "Rep. Checa", away: "México", group: "A", tv: .dazn, done: false),
        Match(time: "22:00", home: "Ecuador", away: "Alemania", group: "E", tv: .both, done: false),
        Match(time: "22:00", home: "Curaçao", away: "C. de Marfil", group: "E", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-26", phase: .grupos, games: [
        Match(time: "01:00", home: "Túnez", away: "Países Bajos", group: "F", tv: .dazn, done: false),
        Match(time: "01:00", home: "Japón", away: "Suecia", group: "F", tv: .dazn, done: false),
        Match(time: "04:00", home: "Turquía", away: "EE.UU.", group: "D", tv: .dazn, done: false),
        Match(time: "04:00", home: "Paraguay", away: "Australia", group: "D", tv: .dazn, done: false),
        Match(time: "21:00", home: "Senegal", away: "Irak", group: "I", tv: .dazn, done: false),
        Match(time: "21:00", home: "Noruega", away: "Francia", group: "I", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-27", phase: .grupos, games: [
        Match(time: "02:00", home: "Uruguay", away: "🇪🇸 España", group: "H", tv: .both, done: false, esp: true),
        Match(time: "02:00", home: "Cabo Verde", away: "Arabia Saudí", group: "H", tv: .dazn, done: false),
        Match(time: "05:00", home: "Nueva Zelanda", away: "Bélgica", group: "G", tv: .dazn, done: false),
        Match(time: "05:00", home: "Egipto", away: "Irán", group: "G", tv: .dazn, done: false),
        Match(time: "23:00", home: "Panamá", away: "Inglaterra", group: "L", tv: .dazn, done: false),
        Match(time: "23:00", home: "Croacia", away: "Ghana", group: "L", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-06-28", phase: .grupos, games: [
        Match(time: "01:30", home: "R.D. Congo", away: "Uzbekistán", group: "K", tv: .dazn, done: false),
        Match(time: "01:30", home: "Colombia", away: "Portugal", group: "K", tv: .both, done: false),
        Match(time: "04:00", home: "Jordania", away: "Argentina", group: "J", tv: .dazn, done: false),
        Match(time: "04:00", home: "Argelia", away: "Austria", group: "J", tv: .dazn, done: false),
        Match(time: "21:00", home: "2º Grupo A", away: "2º Grupo B", group: "1/16", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-29", phase: .dieciseisavos, games: [
        Match(time: "19:00", home: "1º Grupo C", away: "2º Grupo F", group: "1/16", tv: .both, done: false),
        Match(time: "22:30", home: "1º Grupo E", away: "3º Mejor", group: "1/16", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-06-30", phase: .dieciseisavos, games: [
        Match(time: "03:00", home: "1º Grupo F", away: "2º Grupo C", group: "1/16", tv: .dazn, done: false),
        Match(time: "19:00", home: "2º Grupo E", away: "2º Grupo I", group: "1/16", tv: .dazn, done: false),
        Match(time: "23:00", home: "1º Grupo I", away: "3º Mejor", group: "1/16", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-01", phase: .dieciseisavos, games: [
        Match(time: "03:00", home: "1º Grupo A", away: "3º Mejor", group: "1/16", tv: .dazn, done: false),
        Match(time: "18:00", home: "1º Grupo L", away: "3º Mejor", group: "1/16", tv: .both, done: false),
        Match(time: "22:00", home: "1º Grupo G", away: "3º Mejor", group: "1/16", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-02", phase: .dieciseisavos, games: [
        Match(time: "02:00", home: "1º Grupo D", away: "3º Mejor", group: "1/16", tv: .dazn, done: false),
        Match(time: "21:00", home: "1º Grupo H", away: "2º Grupo J", group: "1/16", tv: .both, done: false, esp: true)
    ]),
    MatchDay(date: "2026-07-03", phase: .dieciseisavos, games: [
        Match(time: "00:00", home: "1º Grupo J", away: "2º Grupo H", group: "1/16", tv: .dazn, done: false),
        Match(time: "01:00", home: "2º Grupo K", away: "2º Grupo L", group: "1/16", tv: .dazn, done: false),
        Match(time: "03:30", home: "1º Grupo K", away: "3º Mejor", group: "1/16", tv: .dazn, done: false),
        Match(time: "05:00", home: "1º Grupo B", away: "3º Mejor", group: "1/16", tv: .dazn, done: false),
        Match(time: "20:00", home: "2º Grupo D", away: "2º Grupo G", group: "1/16", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-04", phase: .octavos, games: [
        Match(time: "19:00", home: "Gan. P73", away: "Gan. P75", group: "1/8", tv: .both, done: false),
        Match(time: "23:00", home: "Gan. P74", away: "Gan. P77", group: "1/8", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-05", phase: .octavos, games: [
        Match(time: "22:00", home: "Gan. P76", away: "Gan. P78", group: "1/8", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-06", phase: .octavos, games: [
        Match(time: "02:00", home: "Gan. P79", away: "Gan. P80", group: "1/8", tv: .both, done: false, esp: true),
        Match(time: "21:00", home: "Gan. P83", away: "Gan. P84", group: "1/8", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-07", phase: .octavos, games: [
        Match(time: "01:00", home: "Gan. P81", away: "Gan. P82", group: "1/8", tv: .dazn, done: false),
        Match(time: "18:00", home: "Gan. P86", away: "Gan. P88", group: "1/8", tv: .both, done: false, esp: true),
        Match(time: "22:00", home: "Gan. P85", away: "Gan. P87", group: "1/8", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-09", phase: .cuartos, games: [
        Match(time: "22:00", home: "Cuartos 1", away: "", group: "CF", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-10", phase: .cuartos, games: [
        Match(time: "21:00", home: "Cuartos 2", away: "", group: "CF", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-11", phase: .cuartos, games: [
        Match(time: "22:00", home: "Cuartos 3", away: "", group: "CF", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-12", phase: .cuartos, games: [
        Match(time: "22:00", home: "Cuartos 4", away: "", group: "CF", tv: .dazn, done: false)
    ]),
    MatchDay(date: "2026-07-14", phase: .semis, games: [
        Match(time: "21:00", home: "Semifinal 1", away: "", group: "SF", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-15", phase: .semis, games: [
        Match(time: "21:00", home: "Semifinal 2", away: "", group: "SF", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-18", phase: .final, games: [
        Match(time: "22:00", home: "3er y 4º Puesto", away: "", group: "3P", tv: .both, done: false)
    ]),
    MatchDay(date: "2026-07-19", phase: .final, games: [
        Match(time: "21:00", home: "🏆 FINAL", away: "MetLife Stadium, Nueva Jersey", group: "FINAL", tv: .both, done: false)
    ])
]

// MARK: - Encode + write

let snapshot = MatchSnapshot(lastUpdated: Date(), matchDays: matchDays)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
encoder.dateEncodingStrategy = .iso8601

let data: Data
do {
    data = try encoder.encode(snapshot)
} catch {
    fputs("Error codificando JSON: \(error)\n", stderr)
    exit(1)
}

let outputPath: String
if CommandLine.arguments.count > 1 {
    outputPath = CommandLine.arguments[1]
} else {
    let cwd = FileManager.default.currentDirectoryPath
    outputPath = "\(cwd)/data/mundial2026.json"
}

let outputURL = URL(fileURLWithPath: outputPath)

do {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try data.write(to: outputURL)
} catch {
    fputs("Error escribiendo \(outputPath): \(error)\n", stderr)
    exit(1)
}

let totalGames = matchDays.reduce(0) { $0 + $1.games.count }
print("✅ Snapshot exportado a \(outputPath)")
print("   \(matchDays.count) jornadas · \(totalGames) partidos · \(data.count) bytes")
