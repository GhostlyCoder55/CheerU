import SwiftUI

// MARK: - Game Card View (Vertical Arcade Presentation)
// Beautiful poster-style card used in the vertical arcade layout.

struct GameCardView: View {
    let game: GameIdentifier
    let highScore: Int
    let gradientColors: [Color]
    let onSelect: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.shared.selection()
            onSelect()
        }) {
            ZStack(alignment: .leading) {
                // Background gradient
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )

                // Content
                HStack(spacing: Spacing.lg) {
                    // Custom Game Icon Artwork Badge
                    ZStack {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        GameIconArt(game: game, size: 70)
                    }
                    .frame(width: 84, height: 84)

                    // Text Info
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.title)
                            .font(CheerUpFont.title2)
                            .foregroundStyle(.white)

                        Text(game.subtitle)
                            .font(CheerUpFont.caption)
                            .foregroundStyle(.white.opacity(0.82))

                        Spacer()

                        // Badge: Interactive Exhibit or High Score
                        if !game.isGame {
                            HStack(spacing: 4) {
                                Image(systemName: game.symbol)
                                    .font(.system(size: 10))
                                Text(LanguageManager.shared.tr("Interactive Exhibit", "Expo Interactive", "Expo Interactiva"))
                                    .font(CheerUpFont.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                        } else if highScore > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 10))
                                Text("\(LanguageManager.shared.tr("Best", "Record", "Récord")): \(highScore)")
                                    .font(CheerUpFont.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.trailing, Spacing.xs)
                }
                .padding(Spacing.cardPadding)
            }
            .frame(height: 125)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous))
            .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 14, x: 0, y: 7)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(game.title). \(game.subtitle)")
    }
}
