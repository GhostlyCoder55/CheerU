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
    var onWatchAdContinue: (() -> Void)? = nil

    @State private var scoreRevealed = false
    @State private var displayedScore: Int = 0
    @State private var isNewHighScore = false
    @State private var adStatusMessage: String? = nil
    @State private var adManager = RewardedAdManager.shared

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
                    Text(LanguageManager.shared.tr("FINAL SCORE", "SCORE FINAL", "PUNTUACIÓN"))
                        .font(CheerUpFont.caption)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                        .tracking(2)

                    Text("\(displayedScore)")
                        .font(CheerUpFont.scoreDisplay)
                        .foregroundStyle(accentColor)
                        .contentTransition(.numericText())

                    if isNewHighScore {
                        Label(LanguageManager.shared.tr("NEW BEST!", "NOUVEAU RECORD !", "¡NUEVO RÉCORD!"), systemImage: "star.fill")
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
                    Text("\(LanguageManager.shared.tr("Best", "Record", "Récord")): \(max(score, highScore))")
                        .font(CheerUpFont.callout)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                }

                // Action Buttons
                VStack(spacing: Spacing.md) {
                    if let onWatchAdContinue {
                        watchVideoButton(onContinue: onWatchAdContinue)

                        if let adStatusMessage {
                            Text(adStatusMessage)
                                .font(CheerUpFont.caption)
                                .foregroundStyle(CheerUpColors.mutedSilver)
                                .multilineTextAlignment(.center)
                        }
                    }

                    CheerUpPrimaryButton(LanguageManager.shared.tr("Play Again", "Rejouer", "Jugar de nuevo"), icon: "arrow.clockwise", action: onReplay)
                    CheerUpSecondaryButton(LanguageManager.shared.tr("Arcade", "Arcade", "Arcade"), icon: "square.grid.2x2.fill", action: onExit)
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
            if onWatchAdContinue != nil {
                adManager.preloadIfNeeded()
            }

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

    @ViewBuilder
    private func watchVideoButton(onContinue: @escaping () -> Void) -> some View {
        Button {
            HapticsManager.shared.selection()
            adStatusMessage = nil
            adManager.presentRewardedAd(
                onRewardEarned: {
                    onContinue()
                },
                onDismissedWithoutReward: {
                    if case .failed = adManager.state {
                        adStatusMessage = LanguageManager.shared.tr(
                            "Video unavailable right now. You can still play again!",
                            "Vidéo indisponible pour le moment. Tu peux rejouer !",
                            "Video no disponible ahora. ¡Aún puedes volver a jugar!"
                        )
                    } else {
                        adStatusMessage = LanguageManager.shared.tr(
                            "Watch the full video to earn an extra try.",
                            "Regarde la vidéo en entier pour gagner un essai.",
                            "Mira el video completo para ganar otro intento."
                        )
                    }
                }
            )
        } label: {
            HStack(spacing: Spacing.sm) {
                if adManager.state == .loading || adManager.state == .presenting {
                    ProgressView()
                        .tint(CheerUpColors.deepNavy)
                } else {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 16, weight: .bold))
                }
                Text(LanguageManager.shared.tr(
                    "Watch Video – Continue",
                    "Voir une vidéo – Continuer",
                    "Ver vídeo – Continuar"
                ))
                .font(CheerUpFont.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            .foregroundStyle(CheerUpColors.deepNavy)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [accentColor, accentColor.opacity(0.85)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius, style: .continuous))
        }
        .buttonStyle(PressableButtonStyle())
        .disabled(adManager.state.isBusy)
    }
}
