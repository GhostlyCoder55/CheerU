import SwiftUI

// MARK: - Game Card View (Vertical Arcade Presentation)
// Beautiful poster-style card used in the vertical arcade layout.

struct GameCardView: View {
    let game: GameIdentifier
    let highScore: Int
    let gradientColors: [Color]
    var cardHeight: CGFloat = 114
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
                HStack(spacing: cardHeight < 118 ? Spacing.md : Spacing.lg) {
                    // Custom Game Icon Artwork Badge
                    let iconBoxSize: CGFloat = cardHeight < 118 ? 74 : 84
                    let iconArtSize: CGFloat = cardHeight < 118 ? 60 : 70
                    ZStack {
                        RoundedRectangle(cornerRadius: cardHeight < 118 ? 18 : 22, style: .continuous)
                            .fill(Color.black.opacity(0.22))
                            .overlay(
                                RoundedRectangle(cornerRadius: cardHeight < 118 ? 18 : 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        GameIconArt(game: game, size: iconArtSize)
                    }
                    .frame(width: iconBoxSize, height: iconBoxSize)

                    // Text Info
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.title)
                            .font(cardHeight < 108 ? CheerUpFont.headline : CheerUpFont.title2)
                            .foregroundStyle(.white)

                        Text(game.subtitle)
                            .font(CheerUpFont.caption)
                            .foregroundStyle(.white.opacity(0.82))

                        Spacer(minLength: 0)

                        // Badge: Interactive Exhibit or High Score
                        if !game.isGame {
                            HStack(spacing: 4) {
                                Image(systemName: game.symbol)
                                    .font(.system(size: 10))
                                Text(LanguageManager.shared.tr("Interactive Exhibit", "Expo Interactive", "Expo Interactiva"))
                                    .font(CheerUpFont.caption2)
                            }
                            .foregroundStyle(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.25))
                            .clipShape(Capsule())
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.white.opacity(0.55))
                        .padding(.trailing, Spacing.xs)
                }
                .padding(cardHeight < 118 ? 12 : Spacing.cardPadding)
            }
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous))
            .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PressableButtonStyle())
        .accessibilityLabel("\(game.title). \(game.subtitle)")
    }
}
