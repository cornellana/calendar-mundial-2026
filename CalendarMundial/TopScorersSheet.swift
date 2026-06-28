//
//  TopScorersSheet.swift
//  CalendarMundial
//
//  Hoja con la clasificación de goleadores del Mundial 2026,
//  ordenada de mayor a menor número de goles.
//

import SwiftUI

// MARK: - TopScorersSheet

struct TopScorersSheet: View {
    let scorers: [TopScorer]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(hex: 0x0A0F1E).ignoresSafeArea()

            VStack(spacing: 0) {
                sheetHeader
                    .overlay(
                        Rectangle()
                            .fill(Color(hex: 0x1E3A5F))
                            .frame(height: 1),
                        alignment: .bottom
                    )

                if scorers.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(Array(scorers.enumerated()), id: \.element.id) { index, scorer in
                                ScorerRow(position: index + 1, scorer: scorer)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: Subvistas privadas

    private var sheetHeader: some View {
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
                Text("COPA MUNDIAL FIFA 2026")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2)
                    .foregroundColor(Color(hex: 0xC8A84B))
                Text("Goleadores")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color(hex: 0xF0F4FF))
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(Color(hex: 0x4A6A8A))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color(hex: 0x0A0F1E), Color(hex: 0x0D1F3C), Color(hex: 0x0A0F1E)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "soccerball")
                .font(.system(size: 40))
                .foregroundColor(Color(hex: 0x4A6A8A))
            Text("Aún no hay goles registrados")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: 0x8CA8CC))
            Text("Los goleadores aparecerán aquí\na medida que se jueguen los partidos.")
                .font(.system(size: 12))
                .foregroundColor(Color(hex: 0x4A6A8A))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 60)
    }
}

// MARK: - ScorerRow

private struct ScorerRow: View {
    let position: Int
    let scorer: TopScorer

    private var positionColor: Color {
        switch position {
        case 1: return Color(hex: 0xF0D070)
        case 2: return Color(hex: 0xC0C0C0)
        case 3: return Color(hex: 0xCD7F32)
        default: return Color(hex: 0x4A6A8A)
        }
    }

    private var teamName: String {
        scorer.team
            .trimmingCharacters(in: .whitespaces)
            .drop(while: { !$0.isLetter })
            .trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(position)")
                .font(.system(size: 13, weight: .heavy).monospacedDigit())
                .foregroundColor(positionColor)
                .frame(width: 22, alignment: .trailing)

            VStack(alignment: .leading, spacing: 2) {
                Text(scorer.player)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: 0xF0F4FF))
                    .lineLimit(1)
                Text(teamName)
                    .font(.system(size: 11))
                    .foregroundColor(Color(hex: 0x8CA8CC))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if scorer.penalties > 0 {
                Text("\(scorer.penalties) pen.")
                    .font(.system(size: 10))
                    .foregroundColor(Color(hex: 0x4A6A8A))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(hex: 0x0D1F3C))
                    .clipShape(Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(scorer.goals)")
                    .font(.system(size: 22, weight: .heavy).monospacedDigit())
                    .foregroundColor(position <= 3 ? positionColor : Color(hex: 0xC8A84B))
                Text("⚽")
                    .font(.system(size: 14))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(position == 1
            ? LinearGradient(colors: [Color(hex: 0x1A1500), Color(hex: 0x2A2000)],
                             startPoint: .leading, endPoint: .trailing)
            : LinearGradient(colors: [Color(hex: 0x0D1A2E), Color(hex: 0x0D1A2E)],
                             startPoint: .leading, endPoint: .trailing))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(position == 1
                    ? Color(hex: 0xC8A84B).opacity(0.35)
                    : Color(hex: 0x12243A),
                    lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    TopScorersSheet(scorers: [
        TopScorer(player: "Vinicius Jr.", team: "🇧🇷 Brasil", goals: 4, penalties: 1),
        TopScorer(player: "Kylian Mbappé", team: "Francia", goals: 3, penalties: 0),
        TopScorer(player: "Harry Kane", team: "Inglaterra", goals: 3, penalties: 2),
        TopScorer(player: "Lamine Yamal", team: "🇪🇸 España", goals: 2, penalties: 0),
    ])
}
