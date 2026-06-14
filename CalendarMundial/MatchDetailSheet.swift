//
//  MatchDetailSheet.swift
//  CalendarMundial
//
//  Hoja modal con el detalle de un partido: equipos, resultado, info y
//  alineaciones con eventos por jugador (goles y tarjetas con minuto).
//

import SwiftUI

// MARK: - MatchDetailSheet

/// Vista presentada en `.sheet` que detalla un partido seleccionado.
///
/// Adapta su contenido:
/// - Para partidos jugados muestra resultado en grande y alineaciones con eventos.
/// - Para próximos partidos confirmados muestra hora y equipos.
/// - Para placeholders del bracket avisa de que los equipos están por definir.
struct MatchDetailSheet: View {
    let match: Match
    let dateString: String
    let phase: Phase

    @Environment(\.dismiss) private var dismiss
    @State private var selectedTeam: TeamSide = .home

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: 0x0A0F1E).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    phaseBadge
                        .padding(.top, 30)

                    teamsHero

                    if let result = match.result {
                        resultDisplay(result: result)
                    } else if match.hasConfirmedTeams && !match.away.isEmpty {
                        upcomingLabel
                    } else if !match.hasConfirmedTeams {
                        placeholderLabel
                    }

                    infoBlock

                    if match.esp {
                        spainNote
                    }

                    if let details = match.details {
                        lineupsSection(details: details)
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: 0xF0F4FF), Color(hex: 0x1E3A5F))
            }
            .padding(.top, 14)
            .padding(.trailing, 18)
        }
        .preferredColorScheme(.dark)
    }

    private var phaseBadge: some View {
        Text(phase.rawValue.uppercased())
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(phase.badgeText)
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(phase.badgeBackground)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var teamsHero: some View {
        if match.away.isEmpty {
            Text(match.home)
                .font(.system(size: 26, weight: .heavy))
                .foregroundColor(match.isFinal ? Color(hex: 0xF0D070) : Color(hex: 0xE0EAFF))
                .multilineTextAlignment(.center)
                .padding(.vertical, 20)
        } else {
            HStack(spacing: 12) {
                teamBox(name: match.home)
                Text(match.result == nil ? "vs" : "—")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color(hex: 0x8CA8CC))
                teamBox(name: match.away)
            }
            .padding(.vertical, 8)
        }
    }

    private func teamBox(name: String) -> some View {
        VStack(spacing: 8) {
            Text(name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(match.esp ? Color(hex: 0x90E890) : Color(hex: 0xE0EAFF))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, minHeight: 70)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(Color(hex: 0x0D1A2E))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func resultDisplay(result: String) -> some View {
        VStack(spacing: 6) {
            Text("RESULTADO FINAL")
                .font(.system(size: 10, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(Color(hex: 0x8CA8CC))
            Text(formattedResult(result))
                .font(.system(size: 44, weight: .heavy).monospacedDigit())
                .foregroundColor(Color(hex: 0xC8A84B))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color(hex: 0x0D1A2E))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: 0xC8A84B).opacity(0.4), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var upcomingLabel: some View {
        Text("PRÓXIMO PARTIDO")
            .font(.system(size: 11, weight: .bold))
            .tracking(1.5)
            .foregroundColor(Color(hex: 0xC8A84B))
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color(hex: 0xC8A84B).opacity(0.12))
            .clipShape(Capsule())
    }

    private var placeholderLabel: some View {
        VStack(spacing: 6) {
            Text("EQUIPOS POR DEFINIR")
                .font(.system(size: 11, weight: .bold))
                .tracking(1.5)
                .foregroundColor(Color(hex: 0x8CA8CC))
            Text("Los contrincantes se confirmarán al finalizar las fases previas.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x6A8AAA))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(Color(hex: 0x0D1A2E))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var infoBlock: some View {
        VStack(spacing: 1) {
            InfoRow(label: "Fecha", value: DateFormat.displayDate(from: dateString))
            InfoRow(label: "Hora (España)", value: match.time)
            if !match.group.isEmpty {
                InfoRow(label: groupLabel, value: match.group)
            }
            if let stadium = match.stadium, !stadium.isEmpty {
                InfoRow(label: "Estadio", value: stadium)
            }
            if let city = match.venueCity, !city.isEmpty {
                InfoRow(label: "Ciudad", value: city)
            }
            InfoRow(label: "Televisión",
                    value: match.tv.label,
                    valueColor: match.tv.dotColor)
            InfoRow(label: "Estado",
                    value: match.done ? "Finalizado" : "Pendiente",
                    valueColor: match.done ? Color(hex: 0x90E890) : Color(hex: 0xC8A84B))
        }
        .background(Color(hex: 0x12243A))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
    }

    private var spainNote: some View {
        HStack(spacing: 10) {
            Text("🇪🇸").font(.system(size: 22))
            Text("Partido de la selección española")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color(hex: 0x90E890))
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(hex: 0x0F280F))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x2A8A2A).opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func lineupsSection(details: MatchDetails) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Rectangle()
                    .fill(Color(hex: 0xC8A84B))
                    .frame(width: 3, height: 14)
                Text("ALINEACIONES")
                    .font(.system(size: 13, weight: .heavy))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xC8A84B))
            }
            .padding(.top, 8)

            Picker("Equipo", selection: $selectedTeam) {
                Text(match.home).tag(TeamSide.home)
                Text(match.away).tag(TeamSide.away)
            }
            .pickerStyle(.segmented)

            let lineup = selectedTeam == .home ? details.homeLineup : details.awayLineup
            let starters = lineup.starters
            let subs = lineup.substitutes

            HStack {
                Text("Formación")
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x8CA8CC))
                Spacer()
                Text(lineup.formation)
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundColor(Color(hex: 0xC8A84B))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(hex: 0x0D1A2E))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
            )

            if !starters.isEmpty {
                sectionSubheader("ONCE INICIAL")
                playerList(players: starters)
            }

            if !subs.isEmpty {
                sectionSubheader("SUPLENTES")
                playerList(players: subs)
            }
        }
    }

    private func sectionSubheader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .bold))
            .tracking(1.5)
            .foregroundColor(Color(hex: 0x8CA8CC))
            .padding(.top, 4)
    }

    private func playerList(players: [LineupPlayer]) -> some View {
        VStack(spacing: 1) {
            ForEach(players) { player in
                PlayerRow(player: player)
            }
        }
        .background(Color(hex: 0x12243A))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(hex: 0x1E3A5F), lineWidth: 1)
        )
    }

    private var groupLabel: String {
        match.group.count == 1 ? "Grupo" : "Fase"
    }

    private func formattedResult(_ result: String) -> String {
        result.replacingOccurrences(of: "-", with: " - ")
    }
}

// MARK: - InfoRow

/// Fila clave/valor para el bloque informativo del partido.
private struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = Color(hex: 0xE0EAFF)

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: 0x8CA8CC))
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(valueColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(hex: 0x0D1A2E))
    }
}

// MARK: - PlayerRow

/// Fila de un jugador en la alineación: dorsal, nombre, posición y los
/// eventos del partido (goles y tarjetas con minuto).
private struct PlayerRow: View {
    let player: LineupPlayer

    var body: some View {
        HStack(spacing: 12) {
            Text("\(player.number)")
                .font(.system(size: 12, weight: .heavy).monospacedDigit())
                .foregroundColor(Color(hex: 0x0A0F1E))
                .frame(width: 26, height: 26)
                .background(
                    LinearGradient(
                        colors: [Color(hex: 0xC8A84B), Color(hex: 0xF0D070)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(hex: 0xE0EAFF))
                    .lineLimit(1)
                Text(player.position)
                    .font(.system(size: 9, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(Color(hex: 0x8CA8CC))
            }

            Spacer(minLength: 4)

            if !player.events.isEmpty {
                HStack(spacing: 8) {
                    ForEach(player.events, id: \.self) { event in
                        EventBadge(event: event)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(hex: 0x0D1A2E))
    }
}

// MARK: - EventBadge

/// Icono + minuto que representa un evento concreto de un jugador.
private struct EventBadge: View {
    let event: MatchEvent

    var body: some View {
        HStack(spacing: 3) {
            icon
            Text(event.displayMinute)
                .font(.system(size: 10, weight: .semibold).monospacedDigit())
                .foregroundColor(Color(hex: 0xE0EAFF))
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch event.type {
        case .goal:
            Text("⚽").font(.system(size: 13))
        case .penalty:
            HStack(spacing: 2) {
                Text("⚽").font(.system(size: 13))
                Text("(P)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: 0x8CA8CC))
            }
        case .ownGoal:
            HStack(spacing: 2) {
                Text("⚽").font(.system(size: 13))
                Text("(AG)")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(Color(hex: 0xE65555))
            }
        case .yellow:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 1.0, green: 0.85, blue: 0.0))
                .frame(width: 9, height: 13)
        case .red:
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0.86, green: 0.16, blue: 0.16))
                .frame(width: 9, height: 13)
        case .subIn:
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.30, green: 0.78, blue: 0.40))
        case .subOut:
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 0.90, green: 0.40, blue: 0.40))
        }
    }
}

#Preview("Jugado con detalles") {
    MatchDetailSheet(
        match: Match(time: "21:00", home: "México", away: "Sudáfrica",
                     group: "A", tv: .both, done: true, result: "2-0",
                     details: MatchDetailsData.mexicoVsSouthAfrica),
        dateString: "2026-06-11",
        phase: .grupos
    )
}

#Preview("Próximo España") {
    MatchDetailSheet(
        match: Match(time: "18:00", home: "🇪🇸 España", away: "Cabo Verde",
                     group: "H", tv: .both, done: false, esp: true),
        dateString: "2026-06-15",
        phase: .grupos
    )
}

#Preview("Placeholder") {
    MatchDetailSheet(
        match: Match(time: "22:00", home: "Cuartos 1", away: "",
                     group: "CF", tv: .both, done: false),
        dateString: "2026-07-09",
        phase: .cuartos
    )
}
