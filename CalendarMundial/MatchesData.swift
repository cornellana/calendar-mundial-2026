//
//  MatchesData.swift
//  CalendarMundial
//

import Foundation

enum MundialData {
    static let startDate = "2026-06-11"
    static let endDate = "2026-07-19"

    static var todayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Madrid")
        return formatter.string(from: Date())
    }

    static let matchDays: [MatchDay] = [
        MatchDay(date: "2026-06-11", phase: .grupos, games: [
            Match(time: "21:00", home: "México", away: "Sudáfrica", group: "A", tv: .both, done: true, result: "2-0")
        ]),
        MatchDay(date: "2026-06-12", phase: .grupos, games: [
            Match(time: "04:00", home: "Corea del Sur", away: "Rep. Checa", group: "A", tv: .dazn, done: true, result: "2-1"),
            Match(time: "21:00", home: "Canadá", away: "Bosnia Herz.", group: "B", tv: .both, done: true, result: "1-0")
        ]),
        MatchDay(date: "2026-06-13", phase: .grupos, games: [
            Match(time: "03:00", home: "EE.UU.", away: "Paraguay", group: "D", tv: .dazn, done: true, result: "1-0"),
            Match(time: "21:00", home: "Qatar", away: "Suiza", group: "B", tv: .dazn, done: true, result: "0-3")
        ]),
        MatchDay(date: "2026-06-14", phase: .grupos, games: [
            Match(time: "00:00", home: "Brasil", away: "Marruecos", group: "C", tv: .both, done: false),
            Match(time: "03:00", home: "Haití", away: "Escocia", group: "C", tv: .dazn, done: false),
            Match(time: "06:00", home: "Australia", away: "Turquía", group: "D", tv: .dazn, done: false),
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
}

enum DateFormat {
    private static let daysES = ["Dom", "Lun", "Mar", "Mié", "Jue", "Vie", "Sáb"]
    private static let monthsES = ["Ene", "Feb", "Mar", "Abr", "May", "Jun", "Jul", "Ago", "Sep", "Oct", "Nov", "Dic"]

    static func displayDate(from dateStr: String) -> String {
        let parts = dateStr.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return dateStr }
        let year = parts[0]
        let month = parts[1]
        let day = parts[2]

        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day

        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components) else { return dateStr }

        let weekdayIndex = calendar.component(.weekday, from: date) - 1
        let dayName = daysES[weekdayIndex]
        let monthName = monthsES[month - 1]
        return "\(dayName) \(day) \(monthName)"
    }
}
