import SwiftUI
import SpriteKit

// MARK: - RUSH View Model
// Bridges the SpriteKit RushScene with SwiftUI HUD, MiniCheerUp! top-left mascot commentary,
// active power-up indicators, pause/resume handling, and GameResultView summary.

@Observable
@MainActor
final class RushViewModel: RushSceneDelegate {
    var score: Int = 0
    var highScore: Int = 0
    var activeEffects: [ActiveRushEffect] = []

    var isPaused: Bool = false
    var isGameOver: Bool = false
    var isNewBest: Bool = false

    // MiniCheerUp! Mascot & Speech Bubble State
    var mascotMood: MascotMood = .happy
    var speechText: String = LanguageManager.shared.tr(
        "Drag with one finger to dodge meteors!",
        "Glissez d'un doigt pour esquiver les météores !",
        "¡Desliza con un dedo para esquivar meteoros!"
    )

    // Surprise Event / Near-Miss Banner Pill
    var bannerText: String? = nil
    var bannerColor: Color = Color(hex: 0xFF2E93)
    private var bannerGeneration: Int = 0

    let scene: RushScene

    init() {
        self.highScore = ScoreManager.shared.highScore(for: .rush)
        self.scene = RushScene(size: CGSize(width: 393, height: 852))
        self.scene.gameDelegate = self
    }

    func startGame() {
        isPaused = false
        isGameOver = false
        isNewBest = false
        bannerText = nil
        mascotMood = .happy
        speechText = LanguageManager.shared.tr(
            "Survive! Every 3 seconds is 1 point!",
            "Survivez ! Chaque 3 secondes vaut 1 point !",
            "¡Sobrevive! ¡Cada 3 segundos es 1 punto!"
        )
        highScore = ScoreManager.shared.highScore(for: .rush)
        scene.startNewGame()
        RushAudioController.shared.startBackgroundMusic()
    }

    func pauseGame() {
        guard !isGameOver, !isPaused, !scene.isCrashing else { return }
        isPaused = true
        scene.isGamePaused = true
        RushAudioController.shared.pauseBackgroundMusic()
    }

    func resumeGame() {
        guard isPaused else { return }
        isPaused = false
        scene.isGamePaused = false
        RushAudioController.shared.startBackgroundMusic()
    }

    func stopAudioOnExit() {
        scene.cancelPendingCrash()
        RushAudioController.shared.stopBackgroundMusic()
    }

    // MARK: - RushSceneDelegate

    nonisolated func sceneDidUpdateState(
        score: Int,
        activeEffects: [ActiveRushEffect]
    ) {
        Task { @MainActor in
            if self.score != score {
                self.score = score
                if score > self.highScore {
                    self.highScore = score
                    ScoreManager.shared.updateHighScore(for: .rush, score: score)
                }
            }
            self.activeEffects = activeEffects
        }
    }

    nonisolated func sceneDidTriggerNearMiss(streak: Int) {
        Task { @MainActor in
            self.mascotMood = streak >= 3 ? .party : .wow
            if streak >= 3 {
                self.speechText = LanguageManager.shared.tr(
                    "Incredible flying! \(streak) close dodges in a row!",
                    "Vol incroyable ! \(streak) esquives serrées de suite !",
                    "¡Vuelo increíble! ¡\(streak) esquivas seguidas!"
                )
            } else {
                self.speechText = LanguageManager.shared.tr(
                    "Whoa, close call! Keep surviving!",
                    "Waouh, c'était juste ! Continuez de survivre !",
                    "¡Guau, por poco! ¡Sigue sobreviviendo!"
                )
            }
        }
    }

    nonisolated func sceneDidCollectPowerUp(_ type: RushPowerUpType) {
        Task { @MainActor in
            switch type {
            case .shield:
                self.mascotMood = .happy
                self.speechText = LanguageManager.shared.tr(
                    "Shield Orb collected! Blocks 1 meteor hit!",
                    "Orbe Bouclier ! Bloque 1 impact de météore !",
                    "¡Orbe Escudo! ¡Bloquea 1 impacto!"
                )
            case .slowTime:
                self.mascotMood = .sus
                self.speechText = LanguageManager.shared.tr(
                    "Slow Orb collected! Meteors slowed down!",
                    "Orbe Ralenti ! Météores ralentis !",
                    "¡Orbe Lento! ¡Meteoros más lentos!"
                )
            }
        }
    }

    nonisolated func sceneDidAbsorbHitWithShield() {
        Task { @MainActor in
            self.mascotMood = .wow
            self.speechText = LanguageManager.shared.tr(
                "Phew! Your Shield shattered that meteor!",
                "Ouf ! Le bouclier a pulvérisé ce météore !",
                "¡Uf! ¡Tu escudo destruyó ese meteoro!"
            )
            self.showBanner(
                LanguageManager.shared.tr("SHIELD SAVED YOU!", "SAUVÉ PAR LE BOUCLIER !", "¡SALVADO POR EL ESCUDO!"),
                color: Color(hex: 0x22D3EE)
            )
        }
    }

    nonisolated func sceneDidAnnounceSpecialEvent(_ kind: RushSpecialEventKind, isWarning: Bool) {
        Task { @MainActor in
            if isWarning {
                self.mascotMood = .dizzy
                self.speechText = kind.warningText
                self.showBanner(kind.warningText, color: Color(hex: kind.colorHex))
            }
        }
    }

    nonisolated func sceneDidFinishGame(finalScore: Int, isNewBest: Bool) {
        Task { @MainActor in
            self.score = finalScore
            self.isNewBest = isNewBest
            self.highScore = ScoreManager.shared.highScore(for: .rush)
            self.mascotMood = isNewBest ? .party : .sad
            self.speechText = isNewBest
                ? LanguageManager.shared.tr("New cosmic record! Legendary pilot!", "Nouveau record cosmique ! Pilote de légende !", "¡Nuevo récord cósmico! ¡Piloto legendario!")
                : LanguageManager.shared.tr("Hull breached! Ready for another flight?", "Coque touchée ! Prêt pour un autre vol ?", "¡Nave impactada! ¿Listo para otro vuelo?")
            RushAudioController.shared.stopBackgroundMusic()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isGameOver = true
            }
        }
    }

    private func showBanner(_ text: String, color: Color) {
        bannerGeneration += 1
        let gen = bannerGeneration
        bannerColor = color
        withAnimation(.spring(response: 0.28, dampingFraction: 0.68)) {
            bannerText = text
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if self.bannerGeneration == gen {
                withAnimation(.easeOut(duration: 0.22)) {
                    self.bannerText = nil
                }
            }
        }
    }
}

// MARK: - RUSH Main View (Portrait Only)

struct RushView: View {
    let onExit: () -> Void

    @State private var viewModel = RushViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showDragHint = true

    var body: some View {
        ZStack {
            // Deep Hyper Light Drifter Dark Cosmic Background
            LinearGradient(
                colors: [
                    Color(hex: 0x131B2E),
                    Color(hex: 0x0B101D),
                    Color(hex: 0x060911)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // SpriteKit 60 FPS Portrait Space Dodge Scene
            SpriteView(
                scene: viewModel.scene,
                preferredFramesPerSecond: 60,
                options: [.allowsTransparency, .ignoresSiblingOrder]
            )
            .ignoresSafeArea()

            // HUD Overlay (Top Bar, MiniCheerUp! Stage, Warnings & Bottom Power-Up Indicators)
            VStack(spacing: 8) {
                topNavigationBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 4)

                mascotAndScoreStage
                    .padding(.horizontal, Spacing.screenPadding)

                // Surprise Event / Shield Save Callout Pill
                if let banner = viewModel.bannerText {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                        Text(banner)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(viewModel.bannerColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color(hex: 0x090D16).opacity(0.92))
                            .overlay(
                                Capsule()
                                    .stroke(viewModel.bannerColor.opacity(0.75), lineWidth: 1.5)
                            )
                    )
                    .shadow(color: Color.black.opacity(0.45), radius: 8, y: 4)
                    .transition(.scale(scale: 0.75).combined(with: .opacity))
                    .allowsHitTesting(false)
                }

                Spacer()

                // One-Handed Touch & Drag Hint (fades out automatically)
                if showDragHint && !viewModel.isPaused && !viewModel.isGameOver {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(
                            LanguageManager.shared.tr(
                                "Touch and drag anywhere to pilot your ship",
                                "Touchez et glissez pour piloter votre vaisseau",
                                "Toca y desliza para pilotar tu nave"
                            )
                        )
                        .font(CheerUpFont.caption)
                    }
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color(hex: 0x090D16).opacity(0.82))
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                    .padding(.bottom, 4)
                    .transition(.opacity)
                }

                // Bottom Active Power-Ups Bar
                activePowerUpsBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, 10)
            }

            // Pause Modal Overlay
            if viewModel.isPaused {
                pauseOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }

            // Game Over Screen (Shared GameResultView matching Tap, Ping Pong & Gravity)
            if viewModel.isGameOver {
                GameResultView(
                    gameTitle: "RUSH",
                    score: viewModel.score,
                    highScore: viewModel.highScore,
                    accentColor: Color(hex: 0xFF2E93),
                    onReplay: {
                        viewModel.startGame()
                    },
                    onExit: {
                        viewModel.stopAudioOnExit()
                        onExit()
                    }
                )
                .zIndex(20)
            }
        }
        .onAppear {
            viewModel.startGame()
        }
        .onDisappear {
            viewModel.stopAudioOnExit()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.pauseGame()
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                showDragHint = false
            }
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(alignment: .center) {
            // Exit Button
            Button(action: {
                HapticsManager.shared.selection()
                viewModel.stopAudioOnExit()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(CheerUpColors.blueGrey.opacity(0.75))
                    .clipShape(Circle())
            }

            Spacer()

            // Survival Scoring Rule Pill (3s = 1pt)
            HStack(spacing: 6) {
                Image(systemName: "timer")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0xFF2E93))
                Text(LanguageManager.shared.tr("3 SEC • 1 PT", "3 SEC • 1 PT", "3 SEG • 1 PT"))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(CheerUpColors.lightGrey)
                    .tracking(0.8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: 0x0F172A).opacity(0.92))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0xFF2E93).opacity(0.45), lineWidth: 1)
            )
            .allowsHitTesting(false)

            Spacer()

            // Pause Button
            Button(action: {
                HapticsManager.shared.selection()
                viewModel.pauseGame()
            }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(CheerUpColors.blueGrey.opacity(0.75))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - MiniCheerUp! Top-Left Mascot Stage + Score Pill

    private var mascotAndScoreStage: some View {
        HStack(spacing: 10) {
            CheerUpMascotView(mood: viewModel.mascotMood, size: 52)

            HStack(spacing: 0) {
                Text(viewModel.speechText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.deepNavy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 44)
            .background(
                SpeechBubbleShape()
                    .fill(CheerUpColors.lightGrey)
                    .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
            )

            // Compact Score Pill
            VStack(spacing: 0) {
                Text(LanguageManager.shared.tr("SCORE", "SCORE", "PUNTOS"))
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0xFF2E93))
                Text("\(viewModel.score)")
                    .font(.system(size: 21, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: 0x0F172A).opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: 0xFF2E93).opacity(0.55), lineWidth: 1.5)
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bottom Active Power-Ups Bar

    @ViewBuilder
    private var activePowerUpsBar: some View {
        if !viewModel.activeEffects.isEmpty {
            HStack(spacing: 8) {
                ForEach(viewModel.activeEffects) { effect in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(effect.type.color)
                            .frame(width: 8, height: 8)

                        Text(effect.type.badgeTitle)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 32, height: 6)
                            Capsule()
                                .fill(effect.type.color)
                                .frame(width: max(2, 32 * CGFloat(effect.progress)), height: 6)
                                .animation(.linear(duration: 0.2), value: effect.progress)
                        }

                        Text("\(max(1, Int(ceil(effect.remaining))))s")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CheerUpColors.lightGrey)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(hex: 0x0F172A).opacity(0.94))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(effect.type.color.opacity(0.65), lineWidth: 1.5)
                    )
                }
            }
            .allowsHitTesting(false)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - Pause Overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                Text(LanguageManager.shared.tr("PAUSED", "PAUSE", "PAUSA"))
                    .font(CheerUpFont.title)
                    .foregroundStyle(CheerUpColors.lightGrey)

                VStack(spacing: Spacing.md) {
                    CheerUpPrimaryButton(
                        LanguageManager.shared.tr("Resume", "Reprendre", "Continuar"),
                        icon: "play.fill",
                        action: {
                            HapticsManager.shared.selection()
                            viewModel.resumeGame()
                        }
                    )

                    CheerUpSecondaryButton(
                        LanguageManager.shared.tr("Restart", "Recommencer", "Reiniciar"),
                        icon: "arrow.clockwise",
                        action: {
                            HapticsManager.shared.selection()
                            viewModel.startGame()
                        }
                    )

                    CheerUpSecondaryButton(
                        LanguageManager.shared.tr("Arcade", "Arcade", "Arcade"),
                        icon: "square.grid.2x2.fill",
                        action: {
                            HapticsManager.shared.selection()
                            viewModel.stopAudioOnExit()
                            onExit()
                        }
                    )
                }
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 340)
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
    }
}
