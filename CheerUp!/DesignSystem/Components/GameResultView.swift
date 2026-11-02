import SwiftUI

// MARK: - Game Result View (Game Over Screen)
// Shared across games with consistent styling and Kenney victory/loss audio feedback.

struct GameResultView: View {
    let gameTitle: String
    let score: Int
    let highScore: Int
    let accentColor: Color
    let onReplay: () -> Void
    let onExit: () -> Void

    @State private var scoreRevealed = false
    @State private var displayedScore: Int = 0
    @State private var isNewHighScore = false

    var body: some View {
        ZStack {
            // Dimmed backdrop
            Color.black.opacity(0.65)
                .ignoresSafeArea()
                .onTapGesture {}

            VStack(spacing: Spacing.xl) {
                // Title
                Text(gameTitle)
                    .font(CheerUpFont.title2)
                    .foregroundStyle(CheerUpColors.lightGrey)

                // Score Section
                VStack(spacing: Spacing.sm) {
                    Text(LanguageManager.shared.tr("FINAL SCORE", "SCORE FINAL"))
                        .font(CheerUpFont.caption)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                        .tracking(2)

                    Text("\(displayedScore)")
                        .font(CheerUpFont.scoreDisplay)
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())

                    if isNewHighScore {
                        Label(LanguageManager.shared.tr("NEW BEST!", "NOUVEAU RECORD !"), systemImage: "star.fill")
                            .font(CheerUpFont.caption)
                            .foregroundStyle(.yellow)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.xs)
                            .background(Color.yellow.opacity(0.15))
                            .clipShape(Capsule())
                            .popIn()
                    }
                }

                // Best Score
                HStack {
                    Image(systemName: "trophy.fill")
                        .foregroundStyle(CheerUpColors.mutedSilver)
                        .font(.system(size: 14))
                    Text("\(LanguageManager.shared.tr("Best", "Record")): \(max(score, highScore))")
                        .font(CheerUpFont.callout)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                }

                // Action Buttons
                VStack(spacing: Spacing.md) {
                    CheerUpPrimaryButton(LanguageManager.shared.tr("Play Again", "Rejouer"), icon: "arrow.clockwise", action: onReplay)
                    CheerUpSecondaryButton(LanguageManager.shared.tr("Arcade", "Arcade"), icon: "square.grid.2x2.fill", action: onExit)
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                    .fill(CheerUpColors.darkBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                            .stroke(CheerUpColors.blueGrey.opacity(0.5), lineWidth: 1)
                    )
            )
            .popIn()
        }
        .onAppear {
            isNewHighScore = score > highScore

            let steps = min(score, 30)
            guard steps > 0 else {
                displayedScore = score
                scoreRevealed = true
                if isNewHighScore {
                    HapticsManager.shared.success()
                }
                return
            }
            for i in 0...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.02) {
                    withAnimation(.easeOut(duration: 0.1)) {
                        displayedScore = Int(Double(score) * Double(i) / Double(steps))
                    }
                    if i == steps {
                        displayedScore = score
                        scoreRevealed = true
                        if isNewHighScore {
                            HapticsManager.shared.success()
                        }
                    }
                }
            }
        }
    }
}
