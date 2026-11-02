import SwiftUI

// MARK: - Game Introduction View
// Pre-game introduction displaying game artwork, description, and details.

struct GameIntroView: View {
    let game: GameIdentifier
    let gradientColors: [Color]
    let onPlay: () -> Void
    let onBack: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            // Background: Dark Slate Gradient Palette (#253745 -> #11212D -> #06141B)
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xxxl) {
                Spacer()

                // Custom Game Art Icon Badge
                ZStack {
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.2), lineWidth: 2)
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: gradientColors.first?.opacity(0.4) ?? .clear, radius: 24, x: 0, y: 10)

                    GameIconArt(game: game, size: 84)
                }
                .scaleEffect(appeared ? 1.0 : 0.6)
                .opacity(appeared ? 1 : 0)

                // Text
                VStack(spacing: Spacing.md) {
                    Text(game.title)
                        .font(CheerUpFont.largeTitle)
                        .foregroundStyle(CheerUpColors.lightGrey)

                    Text(game.shortDescription)
                        .font(CheerUpFont.body)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 300)

                    // High score (for games with scoring)
                    if game.isGame {
                        let hs = ScoreManager.shared.highScore(for: game)
                        if hs > 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 13))
                                Text("\(LanguageManager.shared.tr("Best", "Record")): \(hs)")
                                    .font(CheerUpFont.callout)
                            }
                            .foregroundStyle(Color.yellow.opacity(0.9))
                            .padding(.top, Spacing.sm)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

                Spacer()

                // Action Buttons
                VStack(spacing: Spacing.md) {
                    CheerUpPrimaryButton(
                        !game.isGame ? LanguageManager.shared.tr("Open Exhibit", "Ouvrir") : LanguageManager.shared.tr("Play", "Jouer"),
                        icon: !game.isGame ? "slider.horizontal.3" : "play.fill",
                        action: onPlay
                    )
                    CheerUpSecondaryButton(LanguageManager.shared.tr("Back", "Retour"), icon: "chevron.left", action: onBack)
                }
                .padding(.horizontal, Spacing.xl)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 30)

                Spacer()
                    .frame(height: Spacing.xxxl)
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }
}
