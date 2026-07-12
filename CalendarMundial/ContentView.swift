//
//  ContentView.swift
//  CalendarMundial
//
//  Pantalla principal: cabecera con filtros, leyenda y listado de jornadas.
//  Toda la composición es SwiftUI sin Combine; el estado dinámico vive en
//  `MatchStore` (Observation framework).
//

import SwiftUI

// MARK: - ContentView

/// Vista raíz que muestra el calendario completo del Mundial 2026 con
/// filtros por fase y por grupo, búsqueda por equipo y detalle por partido.
struct ContentView: View {
    @State private var store = MatchStore()
    @State private var search: String = ""
    @State private var activePhase: PhaseFilter = .all
    @State private var selectedMatch: SelectedMatch?
    @State private var sheetDetent: PresentationDetent = .medium
    @State private var showingScorers = false
    @Environment(\.scenePhase) private var scenePhase

    private var today: String { MundialData.todayString }

    /// Primer día con partidos a partir de hoy (o el último si el torneo ya terminó).
    private var scrollTargetDate: String? {
        filteredDays.first { $0.date >= today }?.date ?? filteredDays.last?.date
    }

    private var filteredDays: [MatchDay] {
        store.matchDays.compactMap { day in
            let phaseFiltered: [Match]
            switch activePhase {
            case .all:
                phaseFiltered = day.games
            case .phase(let p):
                phaseFiltered = day.games.filter { $0.phase == p }
            case .group(let letter):
                phaseFiltered = day.games.filter { $0.group == letter }
            case .country(let host):
                phaseFiltered = day.games.filter { $0.hostCountry == host }
            case .stadium(let name):
                phaseFiltered = day.games.filter { $0.stadium == name }
            }

            let finalGames = search.isEmpty ? phaseFiltered : phaseFiltered.filter { game in
                game.home.localizedCaseInsensitiveContains(search) ||
                game.away.localizedCaseInsensitiveContains(search)
            }

            guard !finalGames.isEmpty else { return nil }
            return MatchDay(date: day.date, phase: day.phase, games: finalGames)
        }
    }

    /// Clasificación del grupo cuando hay un filtro `.group` activo.
    private var groupStandings: (letter: String, rows: [GroupStanding])? {
        guard case .group(let letter) = activePhase else { return nil }
        let rows = MundialData.standings(forGroup: letter, in: store.matchDays)
        return rows.isEmpty ? nil : (letter, rows)
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x0A0F1E).ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(
                    search: $search,
                    activePhase: $activePhase,
                    showingScorers: $showingScorers,
                    isRefreshing: store.isRefreshing,
                    lastUpdated: store.lastUpdated,
                    countries: MundialData.allCountries(in: store.matchDays),
                    stadiums: MundialData.allStadiums(in: store.matchDays)
                )

                ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        if let standings = groupStandings {
                            GroupStandingsView(
                                groupLetter: standings.letter,
                                rows: standings.rows
                            )
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        }

                        LegendView()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        if filteredDays.isEmpty {
                            VStack(spacing: 14) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 28))
                                    .foregroundColor(Color(hex: 0x4A6A8A))
                                Text("No se encontraron partidos")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(hex: 0x8CA8CC))
                                if activePhase != .all || !search.isEmpty {
                                    Button {
                                        activePhase = .all
                                        search = ""
                                    } label: {
                                        Text("Limpiar filtros")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(Color(hex: 0x0A0F1E))
                                            .padding(.horizontal, 18)
                                            .padding(.vertical, 9)
                                            .background(Color(hex: 0xC8A84B))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 60)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(filteredDays) { day in
                                    DaySectionView(
                                        day: day,
                                        today: today,
                                        isScrollTarget: day.date == scrollTargetDate
                                    ) { match in
                                        sheetDetent = match.details != nil ? .large : .medium
                                        selectedMatch = SelectedMatch(
                                            match: match,
                                            date: day.date,
                                            phase: day.phase
                                        )
                                    }
                                    .id(day.id)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                        }
                    }
                }
                .refreshable {
                    await store.refresh()
                }
                .task(id: scenePhase) {
                    guard scenePhase == .active else { return }
                    await store.refresh()
                    guard let target = scrollTargetDate else { return }
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
                .onChange(of: activePhase) { _, newPhase in
                    guard newPhase == .all, let target = scrollTargetDate else { return }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
                .onChange(of: showingScorers) { _, isShowing in
                    guard !isShowing, let target = scrollTargetDate else { return }
                    Task {
                        try? await Task.sleep(nanoseconds: 150_000_000)
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(target, anchor: .top)
                        }
                    }
                }
                } // ScrollViewReader
            }
        }
        .preferredColorScheme(.dark)
        .sheet(item: $selectedMatch) { item in
            MatchDetailSheet(match: item.match, dateString: item.date, phase: item.phase)
                .presentationDetents([.medium, .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingScorers) {
            TopScorersSheet(scorers: MundialData.topScorers(in: store.matchDays))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - HeaderView

/// Cabecera fija con título, buscador, chips de filtro y barra de filtro activo.
private struct HeaderView: View {
    @Binding var search: String
    @Binding var activePhase: PhaseFilter
    @Binding var showingScorers: Bool
    let isRefreshing: Bool
    let lastUpdated: Date?
    let countries: [String]
    let stadiums: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0xC8A84B), Color(hex: 0xF0D070)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    Text("⚽").font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("COPA MUNDIAL FIFA")
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(2)
                            .foregroundColor(Color(hex: 0xC8A84B))
                        if isRefreshing {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(Color(hex: 0xC8A84B))
                        }
                    }
                    Text("Mundial 2026")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Color(hex: 0xF0F4FF))
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("HORARIOS ESPAÑA")
                        .font(.system(size: 11))
                        .tracking(1)
                        .foregroundColor(Color(hex: 0x8CA8CC))
                    Text(rightSubtitle)
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x8CA8CC))
                }
            }

            SearchField(text: $search)

            VStack(alignment: .leading, spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        PhaseChip(label: "Todos", active: activePhase == .all) {
                            activePhase = .all
                        }
                        ForEach(Phase.allCases) { phase in
                            PhaseChip(label: phaseChipLabel(phase), active: activePhase == .phase(phase)) {
                                activePhase = .phase(phase)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(MundialData.groupLetters, id: \.self) { letter in
                            PhaseChip(label: "Grupo \(letter)", active: activePhase == .group(letter)) {
                                if search.trimmingCharacters(in: .whitespaces).uppercased() == letter {
                                    search = ""
                                }
                                activePhase = .group(letter)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                HStack(spacing: 8) {
                    countryMenu
                    stadiumMenu
                    scorersButton
                    Spacer()
                }
            }

            if activePhase != .all || !search.isEmpty {
                activeFilterBanner
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x0A0F1E), Color(hex: 0x0D1F3C), Color(hex: 0x0A0F1E)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(
            Rectangle()
                .fill(Color(hex: 0x1E3A5F))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func phaseChipLabel(_ phase: Phase) -> String {
        switch phase {
        case .grupos: return "Fase Grupos"
        default: return phase.rawValue
        }
    }

    private var rightSubtitle: String {
        if let lastUpdated {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Act. \(formatter.string(from: lastUpdated))"
        }
        return "11 Jun – 19 Jul 2026"
    }

    private var scorersButton: some View {
        Button {
            showingScorers = true
        } label: {
            menuChipLabel(systemImage: "soccerball", title: "Goleadores")
        }
    }

    private var countryMenu: some View {
        Menu {
            Button("Sin filtro de país") { activePhase = .all }
            Divider()
            ForEach(countries, id: \.self) { country in
                Button(country) { activePhase = .country(country) }
            }
        } label: {
            menuChipLabel(systemImage: "flag.fill", title: currentCountryLabel)
        }
    }

    private var stadiumMenu: some View {
        Menu {
            if stadiums.isEmpty {
                Text("Aún no hay estadios publicados")
            } else {
                Button("Sin filtro de estadio") { activePhase = .all }
                Divider()
                ForEach(stadiums, id: \.self) { stadium in
                    Button(stadium) { activePhase = .stadium(stadium) }
                }
            }
        } label: {
            menuChipLabel(systemImage: "building.2.fill", title: currentStadiumLabel)
        }
    }

    private var currentCountryLabel: String {
        if case .country(let c) = activePhase { return c }
        return "País"
    }

    private var currentStadiumLabel: String {
        if case .stadium(let s) = activePhase { return s }
        return "Estadio"
    }

    private func menuChipLabel(systemImage: String, title: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: systemImage)
                .font(.system(size: 10))
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(Color(hex: 0xE0EAFF))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .frame(minHeight: 34)
        .background(Color(hex: 0x0D1F3C))
        .overlay(
            RoundedRectangle(cornerRadius: 17)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 17))
    }

    private var phaseFilterCapsule: some View {
        Group {
            if activePhase != .all {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 11))
                    Text(activePhase.label)
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: 0x0A0F1E))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0xC8A84B))
                .clipShape(Capsule())
            }
        }
    }

    private var searchCapsule: some View {
        Group {
            if !search.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 11))
                    Text("\u{201C}\(search)\u{201D}")
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                }
                .foregroundColor(Color(hex: 0xE0EAFF))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(hex: 0x1E3A5F))
                .clipShape(Capsule())
            }
        }
    }

    private var activeFilterBanner: some View {
        HStack(spacing: 6) {
            phaseFilterCapsule
            searchCapsule
            Spacer(minLength: 4)
            Button {
                activePhase = .all
                search = ""
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Limpiar")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(Color(hex: 0xE0EAFF))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(hex: 0x0D1F3C))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - SearchField

/// Campo de texto estilizado para buscar equipos por nombre.
private struct SearchField: View {
    @Binding var text: String

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text("Buscar equipo...")
                    .foregroundColor(Color(hex: 0x6A8AAA))
                    .font(.system(size: 14))
                    .padding(.leading, 14)
            }
            TextField("", text: $text)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: 0xF0F4FF))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
        }
        .background(Color(hex: 0x0D1A2E))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - PhaseChip

/// Chip pill para filtros de fase y grupo.
///
/// El `minWidth`/`minHeight` y el `contentShape` garantizan un *tap target*
/// cómodo (≥ 44×36) aun cuando la etiqueta sea una sola letra.
private struct PhaseChip: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 13, weight: active ? .bold : .semibold))
                .foregroundColor(active ? Color(hex: 0x0A0F1E) : Color(hex: 0xE0EAFF))
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .frame(minWidth: 44, minHeight: 36)
                .background(active ? Color(hex: 0xC8A84B) : Color(hex: 0x0D1F3C))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(active ? Color.clear : Color(hex: 0x1E3A5F), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .contentShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - LegendView

/// Leyenda con la convención de colores de los canales y el partido de España.
private struct LegendView: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: Color(hex: 0x2196F3), text: "La 1 + DAZN (gratis)")
            legendItem(color: Color(hex: 0xC8A84B), text: "Solo DAZN (pago)")
            HStack(spacing: 6) {
                Text("🇪🇸").font(.system(size: 13))
                Text("Partido de España")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: 0x8CA8CC))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x8CA8CC))
        }
    }
}

// MARK: - DaySectionView

/// Bloque de un día con su cabecera (fecha y badge de fase) y las filas de
/// partidos correspondientes.
private struct DaySectionView: View {
    let day: MatchDay
    let today: String
    /// `true` cuando este día es el destino del scroll automático (el más próximo a hoy).
    let isScrollTarget: Bool
    let onSelect: (Match) -> Void

    private var isToday: Bool { day.date == today }
    private var isPast: Bool { day.date < today }
    // Destacado en dorado: exactamente hoy o, si no hay partido hoy, el próximo día con partido.
    private var isHighlighted: Bool { isToday || isScrollTarget }

    var body: some View {
        VStack(spacing: 4) {
            dayHeader

            ForEach(day.games) { game in
                Button { onSelect(game) } label: {
                    MatchRow(match: game, isToday: isHighlighted, isPast: isPast)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dayHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                if isHighlighted {
                    Text("📍").font(.system(size: 13))
                }
                Text(DateFormat.displayDate(from: day.date))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isHighlighted ? Color(hex: 0xC8A84B) : isPast ? Color(hex: 0x4A6080) : Color(hex: 0xE0EAFF))
                if isToday {
                    Text("HOY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8A84B))
                        .padding(.leading, 2)
                } else if isScrollTarget {
                    Text("PRÓXIMO")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8A84B))
                        .padding(.leading, 2)
                }
            }

            Rectangle()
                .fill(isHighlighted ? Color(hex: 0xC8A84B).opacity(0.13) : Color(hex: 0x1E3A5F))
                .frame(height: 1)

            Text(day.phase.rawValue.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.8)
                .foregroundColor(day.phase.badgeText)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(day.phase.badgeBackground)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .padding(.vertical, 6)
    }
}

// MARK: - MatchRow

/// Fila individual de un partido en el listado, con hora, equipos, badge de
/// canal y chevron para indicar que es navegable a la hoja de detalle.
private struct MatchRow: View {
    let match: Match
    let isToday: Bool
    let isPast: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(match.time)
                .font(.system(size: 12, weight: .bold).monospacedDigit())
                .foregroundColor(Color(hex: 0xC8A84B))
                .frame(minWidth: 42, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(teamsText)
                    .font(.system(size: match.isFinal ? 15 : 13,
                                  weight: match.isFinal ? .heavy : match.esp ? .bold : .medium))
                    .foregroundColor(teamsColor)
                    .lineLimit(1)
                    .truncationMode(.tail)

                if let result = match.result {
                    Text("Resultado: \(result)")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: 0x6A8AAA))
                } else if match.showsGroupLabel {
                    Text("Grupo \(match.group)")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: 0x4A6A8A))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            tvBadge

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color(hex: 0x4A6A8A))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(rowBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(rowBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .opacity(isPast ? 0.65 : 1)
        .contentShape(Rectangle())
    }

    private var teamsText: String {
        match.away.isEmpty ? match.home : "\(match.home) vs \(match.away)"
    }

    private var teamsColor: Color {
        if match.isFinal { return Color(hex: 0xF0D070) }
        if match.esp { return Color(hex: 0x90E890) }
        return Color(hex: 0xE0EAFF)
    }

    private var rowBackground: some View {
        Group {
            if match.isFinal {
                LinearGradient(colors: [Color(hex: 0x1A1200), Color(hex: 0x2A2000)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            } else if match.esp {
                LinearGradient(colors: [Color(hex: 0x0D1F0D), Color(hex: 0x0F280F)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            } else if isPast {
                Color(hex: 0x0B1422)
            } else if isToday {
                Color(hex: 0x0C1830)
            } else {
                Color(hex: 0x0D1A2E)
            }
        }
    }

    private var rowBorder: Color {
        if match.isFinal { return Color(hex: 0xC8A84B).opacity(0.33) }
        if match.esp { return Color(hex: 0x2A8A2A).opacity(0.33) }
        if isToday { return Color(hex: 0x1E3A5F) }
        return Color(hex: 0x12243A)
    }

    private var tvBadge: some View {
        HStack(spacing: 5) {
            Circle().fill(match.tv.dotColor).frame(width: 7, height: 7)
            Text(match.tv.label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(match.tv.dotColor)
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(match.tv.badgeBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(match.tv.badgeBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 5))
    }
}

// MARK: - GroupStandingsView

/// Tabla compacta con la clasificación de un grupo: PJ, PG, PE, PP, GF, GC, DG, Pts.
private struct GroupStandingsView: View {
    let groupLetter: String
    let rows: [GroupStanding]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(hex: 0xC8A84B))
                    .frame(width: 3, height: 14)
                Text("CLASIFICACIÓN GRUPO \(groupLetter)")
                    .font(.system(size: 12, weight: .heavy))
                    .tracking(1.5)
                    .foregroundColor(Color(hex: 0xC8A84B))
            }

            // Cabecera
            standingsRow(
                team: "Equipo",
                pj: "PJ", pg: "PG", pe: "PE", pp: "PP",
                gf: "GF", gc: "GC", dg: "DG", pts: "Pts",
                isHeader: true
            )

            Rectangle()
                .fill(Color(hex: 0x1E3A5F))
                .frame(height: 1)

            ForEach(Array(rows.enumerated()), id: \.element.id) { idx, row in
                standingsRow(
                    team: row.country,
                    pj: "\(row.played)",
                    pg: "\(row.won)",
                    pe: "\(row.drawn)",
                    pp: "\(row.lost)",
                    gf: "\(row.goalsFor)",
                    gc: "\(row.goalsAgainst)",
                    dg: row.goalDifference >= 0 ? "+\(row.goalDifference)" : "\(row.goalDifference)",
                    pts: "\(row.points)",
                    isHeader: false,
                    position: idx + 1
                )
                if idx < rows.count - 1 {
                    Rectangle()
                        .fill(Color(hex: 0x12243A))
                        .frame(height: 1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(Color(hex: 0x0D1A2E))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func standingsRow(team: String,
                              pj: String, pg: String, pe: String, pp: String,
                              gf: String, gc: String, dg: String, pts: String,
                              isHeader: Bool,
                              position: Int? = nil) -> some View {
        HStack(spacing: 4) {
            Text(position.map { "\($0)" } ?? "")
                .frame(width: 14, alignment: .trailing)
                .foregroundColor(Color(hex: 0xC8A84B))
            Text(team)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Group {
                Text(pj).frame(width: 22, alignment: .trailing)
                Text(pg).frame(width: 22, alignment: .trailing)
                Text(pe).frame(width: 22, alignment: .trailing)
                Text(pp).frame(width: 22, alignment: .trailing)
                Text(gf).frame(width: 22, alignment: .trailing)
                Text(gc).frame(width: 22, alignment: .trailing)
                Text(dg).frame(width: 28, alignment: .trailing)
            }
            Text(pts)
                .frame(width: 28, alignment: .trailing)
                .fontWeight(isHeader ? .bold : .heavy)
                .foregroundColor(isHeader ? Color(hex: 0x8CA8CC) : Color(hex: 0xC8A84B))
        }
        .font(.system(size: isHeader ? 10 : 12,
                      weight: isHeader ? .bold : .semibold).monospacedDigit())
        .foregroundColor(isHeader ? Color(hex: 0x8CA8CC) : Color(hex: 0xE0EAFF))
        .padding(.vertical, isHeader ? 0 : 4)
    }
}

#Preview {
    ContentView()
}
