//
//  ContentView.swift
//  CalendarMundial
//

import SwiftUI

struct ContentView: View {
    @State private var store = MatchStore()
    @State private var search: String = ""
    @State private var activePhase: PhaseFilter = .all
    @State private var selectedMatch: SelectedMatch?

    private let today = MundialData.todayString

    private var filteredDays: [MatchDay] {
        store.matchDays.filter { day in
            let phaseOk: Bool
            switch activePhase {
            case .all:
                phaseOk = true
            case .phase(let p):
                phaseOk = day.phase == p || day.games.contains { $0.group == p.rawValue }
            }
            let searchOk = search.isEmpty || day.games.contains { game in
                game.home.localizedCaseInsensitiveContains(search) ||
                game.away.localizedCaseInsensitiveContains(search)
            }
            return phaseOk && searchOk
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color(hex: 0x0A0F1E).ignoresSafeArea()

            VStack(spacing: 0) {
                HeaderView(
                    search: $search,
                    activePhase: $activePhase,
                    isRefreshing: store.isRefreshing,
                    lastUpdated: store.lastUpdated
                )

                ScrollView {
                    VStack(spacing: 0) {
                        LegendView()
                            .padding(.horizontal, 20)
                            .padding(.top, 12)

                        if filteredDays.isEmpty {
                            Text("No se encontraron partidos")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: 0x4A6A8A))
                                .padding(.vertical, 60)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(filteredDays) { day in
                                    DaySectionView(day: day, today: today) { match in
                                        selectedMatch = SelectedMatch(
                                            match: match,
                                            date: day.date,
                                            phase: day.phase
                                        )
                                    }
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
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await store.refresh()
        }
        .sheet(item: $selectedMatch) { item in
            MatchDetailSheet(match: item.match, dateString: item.date, phase: item.phase)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

private struct HeaderView: View {
    @Binding var search: String
    @Binding var activePhase: PhaseFilter
    let isRefreshing: Bool
    let lastUpdated: Date?

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

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    PhaseChip(label: "Todos", active: activePhase == .all) {
                        activePhase = .all
                    }
                    ForEach(Phase.allCases) { phase in
                        PhaseChip(label: phase.rawValue, active: activePhase == .phase(phase)) {
                            activePhase = .phase(phase)
                        }
                    }
                }
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

    private var rightSubtitle: String {
        if let lastUpdated {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            formatter.dateStyle = .none
            return "Act. \(formatter.string(from: lastUpdated))"
        }
        return "11 Jun – 19 Jul 2026"
    }
}

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

private struct PhaseChip: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: active ? .bold : .regular))
                .foregroundColor(active ? Color(hex: 0x0A0F1E) : Color(hex: 0x8CA8CC))
                .padding(.horizontal, 13)
                .padding(.vertical, 5)
                .background(active ? Color(hex: 0xC8A84B) : Color(hex: 0x0D1F3C))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(active ? Color.clear : Color(hex: 0x1E3A5F), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

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

private struct DaySectionView: View {
    let day: MatchDay
    let today: String
    let onSelect: (Match) -> Void

    private var isToday: Bool { day.date == today }
    private var isPast: Bool { day.date < today }

    var body: some View {
        VStack(spacing: 4) {
            dayHeader

            ForEach(day.games) { game in
                Button { onSelect(game) } label: {
                    MatchRow(match: game, isToday: isToday, isPast: isPast)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dayHeader: some View {
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                if isToday {
                    Text("📍").font(.system(size: 13))
                }
                Text(DateFormat.displayDate(from: day.date))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isToday ? Color(hex: 0xC8A84B) : isPast ? Color(hex: 0x4A6080) : Color(hex: 0xE0EAFF))
                if isToday {
                    Text("HOY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: 0xC8A84B))
                        .padding(.leading, 2)
                }
            }

            Rectangle()
                .fill(isToday ? Color(hex: 0xC8A84B).opacity(0.13) : Color(hex: 0x1E3A5F))
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

#Preview {
    ContentView()
}
