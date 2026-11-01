import SwiftUI

// MARK: - Game Header (In-Game HUD)
// Consistent top bar across all games: back, title, score, timer.

struct GameHeaderView: View {
    let title: String
    let accentColor: Color
    let score: Int
    let timeRemaining: Double?
    let lives: Int?
    let onExit: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        HStack(alignment: .center, spacing: Spacing.md) {
            // Back button
            Button(action: {
                HapticsManager.shared.selection()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(CheerUpColors.mutedSilver)
                    .frame(width: 36, height: 36)
                    .background(CheerUpColors.blueGrey.opacity(0.5))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Exit to arcade")

            Spacer()

            // Timer (if applicable)
            if let time = timeRemaining {
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 11))
                    Text(String(format: "%.1f", max(time, 0)))
                        .font(CheerUpFont.gameLabel)
                        .monospacedDigit()
                }
                .foregroundStyle(time < 5 ? Color.red : CheerUpColors.mutedSilver)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(CheerUpColors.blueGrey.opacity(0.4))
                .clipShape(Capsule())
                .accessibilityLabel("Time remaining: \(String(format: "%.0f", max(time, 0))) seconds")
            }

            // Lives (if applicable)
            if let lives {
                HStack(spacing: 5) {
                    ForEach(0..<3, id: \.self) { i in
                        PixelHeartView(isFilled: i < lives, size: 16)
                    }
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .background(CheerUpColors.blueGrey.opacity(0.4))
                .clipShape(Capsule())
                .accessibilityLabel("\(lives) lives remaining")
            }

            // Score
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(accentColor)
                Text("\(score)")
                    .font(CheerUpFont.gameLabel)
                    .monospacedDigit()
                    .foregroundStyle(CheerUpColors.lightGrey)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(CheerUpColors.blueGrey.opacity(0.4))
            .clipShape(Capsule())
            .accessibilityLabel("Score: \(score)")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
    }
}
