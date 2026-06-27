//
//  MatchesData.swift
//  CalendarMundial
//
//  Datos integrados del Mundial 2026. Sirven de semilla cuando no hay caché
//  ni JSON remoto disponible. El `MatchStore` sustituye estos datos por la
//  versión remota en cuanto se publica una nueva.
//

import Foundation

// MARK: - MundialData

/// Fuente de datos estática con el calendario completo del Mundial 2026.
enum MundialData {

    /// Fecha de inicio del torneo (jornada inaugural).
    static let startDate = "2026-06-11"

    /// Fecha de la gran final.
    static let endDate = "2026-07-19"

    /// Letras de los 12 grupos del torneo, en orden alfabético.
    static let groupLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L"]

    /// Países anfitriones del Mundial (México, Canadá, EE.UU.) que aparecen
    /// como sede en los partidos publicados. Se usa para el filtro "País":
    /// "filtrar por Canadá" muestra todos los partidos disputados en estadios
    /// canadienses, no los de la selección de Canadá.
    static func allCountries(in matchDays: [MatchDay]) -> [String] {
        var set = Set<String>()
        for day in matchDays {
            for match in day.games {
                if let host = match.hostCountry, !host.isEmpty {
                    set.insert(host)
                }
            }
        }
        return set.sorted()
    }

    /// Estadios distintos extraídos del calendario, ordenados alfabéticamente.
    /// Sólo se incluyen los que ESPN ha publicado (por norma, los de partidos
    /// ya disputados; los futuros se irán añadiendo).
    static func allStadiums(in matchDays: [MatchDay]) -> [String] {
        var set = Set<String>()
        for day in matchDays {
            for match in day.games {
                if let stadium = match.stadium, !stadium.isEmpty {
                    set.insert(stadium)
                }
            }
        }
        return set.sorted()
    }

    /// Calcula la clasificación de un grupo a partir de los partidos disputados.
    /// - Parameters:
    ///   - letter: Letra del grupo ("A", "B", …).
    ///   - matchDays: Calendario completo (se procesan sólo los partidos
    ///                con `group == letter` y equipos confirmados).
    /// - Returns: Filas ordenadas según criterios FIFA: puntos, diferencia de
    ///            goles, goles a favor, nombre.
    static func standings(forGroup letter: String, in matchDays: [MatchDay]) -> [GroupStanding] {
        var rows: [String: GroupStanding] = [:]

        for day in matchDays {
            for match in day.games where match.group == letter && match.hasConfirmedTeams {
                // Asegura que ambos equipos figuren aunque no hayan jugado todavía.
                if rows[match.home] == nil {
                    rows[match.home] = GroupStanding(country: match.home)
                }
                if !match.away.isEmpty, rows[match.away] == nil {
                    rows[match.away] = GroupStanding(country: match.away)
                }

                guard let result = match.result,
                      !match.away.isEmpty else { continue }
                let parts = result.split(separator: "-").compactMap { Int($0) }
                guard parts.count == 2 else { continue }
                let homeGoals = parts[0]
                let awayGoals = parts[1]

                var home = rows[match.home] ?? GroupStanding(country: match.home)
                var away = rows[match.away] ?? GroupStanding(country: match.away)

                home.played += 1
                away.played += 1
                home.goalsFor += homeGoals
                home.goalsAgainst += awayGoals
                away.goalsFor += awayGoals
                away.goalsAgainst += homeGoals

                if homeGoals > awayGoals {
                    home.won += 1
                    away.lost += 1
                } else if homeGoals < awayGoals {
                    home.lost += 1
                    away.won += 1
                } else {
                    home.drawn += 1
                    away.drawn += 1
                }

                rows[match.home] = home
                rows[match.away] = away
            }
        }

        return rows.values.sorted { a, b in
            if a.points != b.points { return a.points > b.points }
            if a.goalDifference != b.goalDifference { return a.goalDifference > b.goalDifference }
            if a.goalsFor != b.goalsFor { return a.goalsFor > b.goalsFor }
            return stripEmoji(a.country).lowercased() < stripEmoji(b.country).lowercased()
        }
    }

    /// Elimina caracteres no alfanuméricos al principio del nombre (banderas emoji)
    /// para ordenar correctamente "🇪🇸 España" como "España".
    private static func stripEmoji(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces)
            .drop(while: { !$0.isLetter })
            .trimmingCharacters(in: .whitespaces)
    }

    /// Fecha actual en zona horaria Europe/Madrid (formato ISO `yyyy-MM-dd`).
    ///
    /// Se usa para detectar la jornada del día actual en el listado. Se
    /// calcula sobre el huso de Madrid porque la app está pensada para
    /// usuarios en España y los horarios son europeos.
    static var todayString: String {
        let madridZone = TimeZone(identifier: "Europe/Madrid") ?? .gmt
        return Date().formatted(
            Date.ISO8601FormatStyle(timeZone: madridZone)
                .year()
                .month()
                .day()
        )
    }

    static let matchDays: [MatchDay] = [
        MatchDay(date: "2026-06-11", phase: .grupos, games: [
            Match(time: "21:00", home: "México", away: "Sudáfrica", group: "A", tv: .both, done: true, result: "2-0",
                  details: MatchDetailsData.mexicoVsSouthAfrica)
        ]),
        MatchDay(date: "2026-06-12", phase: .grupos, games: [
            Match(time: "04:00", home: "Corea del Sur", away: "Rep. Checa", group: "A", tv: .dazn, done: true, result: "2-1",
                  details: MatchDetailsData.koreaVsCzechia),
            Match(time: "21:00", home: "Canadá", away: "Bosnia Herz.", group: "B", tv: .both, done: true, result: "1-1",
                  details: MatchDetailsData.canadaVsBosnia)
        ]),
        MatchDay(date: "2026-06-13", phase: .grupos, games: [
            Match(time: "03:00", home: "EE.UU.", away: "Paraguay", group: "D", tv: .dazn, done: true, result: "4-1",
                  details: MatchDetailsData.usaVsParaguay),
            Match(time: "21:00", home: "Qatar", away: "Suiza", group: "B", tv: .dazn, done: true, result: "1-1",
                  details: MatchDetailsData.qatarVsSwitzerland)
        ]),
        MatchDay(date: "2026-06-14", phase: .grupos, games: [
            Match(time: "00:00", home: "Brasil", away: "Marruecos", group: "C", tv: .both, done: true, result: "1-1",
                  details: MatchDetailsData.brazilVsMorocco),
            Match(time: "03:00", home: "Haití", away: "Escocia", group: "C", tv: .dazn, done: true, result: "0-1",
                  details: MatchDetailsData.scotlandVsHaiti),
            Match(time: "06:00", home: "Australia", away: "Turquía", group: "D", tv: .dazn, done: true, result: "2-0",
                  details: MatchDetailsData.australiaVsTurkey),
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
            Match(time: "21:00", home: "Sudáfrica", away: "Canadá", group: "1/16", tv: .both, done: false,
                  stadium: "SoFi Stadium", venueCity: "Los Ángeles, EE.UU.")
        ]),
        MatchDay(date: "2026-06-29", phase: .dieciseisavos, games: [
            Match(time: "19:00", home: "Brasil", away: "Japón", group: "1/16", tv: .both, done: false,
                  stadium: "NRG Stadium", venueCity: "Houston, EE.UU."),
            Match(time: "22:30", home: "Alemania", away: "Paraguay", group: "1/16", tv: .both, done: false,
                  stadium: "Gillette Stadium", venueCity: "Foxborough, EE.UU.")
        ]),
        MatchDay(date: "2026-06-30", phase: .dieciseisavos, games: [
            Match(time: "03:00", home: "Países Bajos", away: "Marruecos", group: "1/16", tv: .dazn, done: false,
                  stadium: "Estadio Monterrey", venueCity: "Monterrey, México"),
            Match(time: "19:00", home: "C. de Marfil", away: "Noruega", group: "1/16", tv: .dazn, done: false,
                  stadium: "AT&T Stadium", venueCity: "Arlington, EE.UU."),
            Match(time: "23:00", home: "Francia", away: "Suecia", group: "1/16", tv: .dazn, done: false,
                  stadium: "MetLife Stadium", venueCity: "East Rutherford, EE.UU.")
        ]),
        MatchDay(date: "2026-07-01", phase: .dieciseisavos, games: [
            Match(time: "03:00", home: "México", away: "3er Mejor", group: "1/16", tv: .dazn, done: false,
                  stadium: "Estadio Azteca", venueCity: "Ciudad de México, México"),
            Match(time: "18:00", home: "1º Grupo L", away: "3er Mejor", group: "1/16", tv: .both, done: false,
                  stadium: "Mercedes-Benz Stadium", venueCity: "Atlanta, EE.UU."),
            Match(time: "22:00", home: "Bélgica", away: "3er Mejor", group: "1/16", tv: .both, done: false,
                  stadium: "Lumen Field", venueCity: "Seattle, EE.UU.")
        ]),
        MatchDay(date: "2026-07-02", phase: .dieciseisavos, games: [
            Match(time: "02:00", home: "EE.UU.", away: "Bosnia Herz.", group: "1/16", tv: .dazn, done: false,
                  stadium: "Levi's Stadium", venueCity: "San Francisco, EE.UU."),
            Match(time: "21:00", home: "🇪🇸 España", away: "2º Grupo J", group: "1/16", tv: .both, done: false, esp: true,
                  stadium: "SoFi Stadium", venueCity: "Los Ángeles, EE.UU.")
        ]),
        MatchDay(date: "2026-07-03", phase: .dieciseisavos, games: [
            Match(time: "00:00", home: "Argentina", away: "Cabo Verde", group: "1/16", tv: .dazn, done: false,
                  stadium: "Hard Rock Stadium", venueCity: "Miami, EE.UU."),
            Match(time: "01:00", home: "2º Grupo K", away: "2º Grupo L", group: "1/16", tv: .dazn, done: false,
                  stadium: "BMO Field", venueCity: "Toronto, Canadá"),
            Match(time: "03:30", home: "1º Grupo K", away: "3er Mejor", group: "1/16", tv: .dazn, done: false,
                  stadium: "Arrowhead Stadium", venueCity: "Kansas City, EE.UU."),
            Match(time: "05:00", home: "Suiza", away: "3er Mejor", group: "1/16", tv: .dazn, done: false,
                  stadium: "BC Place", venueCity: "Vancouver, Canadá"),
            Match(time: "20:00", home: "Australia", away: "Egipto", group: "1/16", tv: .dazn, done: false,
                  stadium: "AT&T Stadium", venueCity: "Arlington, EE.UU.")
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
}

// MARK: - DateFormat

/// Utilidades para formatear las fechas ISO de las jornadas a una representación
/// abreviada y *localizada*.
///
/// Usa `Date.FormatStyle` (no `DateFormatter` manual) para respetar el locale
/// activo del sistema: en español muestra "sáb 14 jun", en inglés "Sat, Jun 14".
enum DateFormat {

    /// Convierte una cadena ISO `yyyy-MM-dd` en una representación legible y
    /// localizada con día de la semana abreviado, día y mes.
    /// - Parameter dateStr: Fecha en formato `yyyy-MM-dd`.
    /// - Returns: Texto localizado o la propia cadena si el parseo falla.
    static func displayDate(from dateStr: String) -> String {
        let parts = dateStr.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return dateStr }

        var components = DateComponents()
        components.year = parts[0]
        components.month = parts[1]
        components.day = parts[2]

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else { return dateStr }

        // FormatStyle respeta el locale del usuario sin tablas hardcodeadas.
        return date.formatted(
            .dateTime
                .weekday(.abbreviated)
                .day()
                .month(.abbreviated)
        )
    }
}
