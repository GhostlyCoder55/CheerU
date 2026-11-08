import SwiftUI
import SpriteKit

// MARK: - Ping Pong View Model
// Bridges the SpriteKit PingPongScene with SwiftUI HUD, MiniCheerUp! mascot
// power-up announcements, pause/resume handling, and Tap-style Game Over summary.

@Observable
@MainActor
final class PingPongViewModel: PingPongSceneDelegate {
    var mode: PingPongMode = .endless
    var playerScore: Int = 0
    var cpuScore: Int = 0
    var rally: Int = 0
    var highScore: Int = 0
    var activePowerUps: [ActivePowerUpState] = []

    var isPaused: Bool = false
    var isGameOver: Bool = false
    var playerWon: Bool = false
    var isNewBest: Bool = false

    // MiniCheerUp! Mascot & Speech Bubble State
    var mascotMood: MascotMood = .happy
    var speechText: String = LanguageManager.shared.tr(
        "Drag to return! Watch for power ups!",
        "Glissez pour renvoyer ! Guettez les bonus !",
        "¡Desliza para devolver! ¡Atento a los bonos!"
    )

    // Dynamic arcade callout banner ("GETTING HOT!", "TOO FAST!", etc.)
    var calloutText: String? = nil
    var calloutColor: Color = .yellow
    private var calloutGeneration: Int = 0

    let scene: PingPongScene

    init() {
        self.highScore = ScoreManager.shared.highScore(for: .pingPong)
        self.scene = PingPongScene(size: CGSize(width: 393, height: 852))
        self.scene.gameDelegate = self
    }

    func startGame(mode: PingPongMode? = nil) {
        if let mode {
            self.mode = mode
        }
        isPaused = false
        isGameOver = false
        playerWon = false
        isNewBest = false
        calloutText = nil
        mascotMood = .happy
        speechText = LanguageManager.shared.tr(
            "Let's rally! Hit power ups on the table!",
            "C'est parti ! Visez les bonus sur la table !",
            "¡Vamos! ¡Golpea los potenciadores!"
        )
        highScore = ScoreManager.shared.highScore(for: .pingPong)
        scene.startNewGame(mode: self.mode)
    }

    func switchMode(_ newMode: PingPongMode) {
        guard newMode != mode else { return }
        HapticsManager.shared.selection()
        AudioManager.shared.play(.switchToggle)
        startGame(mode: newMode)
    }

    func pauseGame() {
        guard !isGameOver, !isPaused else { return }
        isPaused = true
        scene.isGamePaused = true
    }

    func resumeGame() {
        guard isPaused else { return }
        isPaused = false
        scene.isGamePaused = false
    }

    // MARK: - Mascot Power-Up Announcements

    private func announceSpawnedPowerUp(_ type: PingPongPowerUpType) {
        mascotMood = .wow
        switch type {
        case .giantPaddle:
            speechText = LanguageManager.shared.tr("Ooh! Giant Paddle spotted!", "Oh ! Raquette Géante en vue !", "¡Mira! ¡Pala Gigante a la vista!")
        case .speedBoost:
            speechText = LanguageManager.shared.tr("Speed Boost on the table!", "Turbo Vitesse sur la table !", "¡Turbo Velocidad en la mesa!")
        case .slowMotion:
            speechText = LanguageManager.shared.tr("Slow Motion spawned! Grab it!", "Ralenti apparu ! À saisir !", "¡Cámara Lenta! ¡Atrápala!")
        case .stickyPaddle:
            speechText = LanguageManager.shared.tr("Sticky Paddle! Catch & aim!", "Raquette Aimant ! Visez bien !", "¡Pala Imán! ¡Atrapa y apunta!")
        case .doublePoints:
            speechText = LanguageManager.shared.tr("2X Points! Hit it for double score!", "Points Doublés ! Visez bien !", "¡Puntos Dobles en juego!")
        case .shield:
            speechText = LanguageManager.shared.tr("A Shield appeared! Safety net!", "Un Bouclier est apparu !", "¡Apareció un Escudo protector!")
        case .chaosBall:
            speechText = LanguageManager.shared.tr("Chaos Ball incoming! Watch out!", "Balle Chaos en vue ! Attention !", "¡Bola Caos en la mesa!")
        }
    }

    private func announceCollectedPowerUp(_ type: PingPongPowerUpType) {
        switch type {
        case .giantPaddle:
            mascotMood = .happy
            speechText = LanguageManager.shared.tr("GIANT PADDLE! Nothing gets past us!", "RAQUETTE GÉANTE ! Rien ne passe !", "¡PALA GIGANTE! ¡Nada pasará!")
        case .speedBoost:
            mascotMood = .party
            speechText = LanguageManager.shared.tr("SPEED BOOST! Supercharged returns!", "TURBO VITESSE ! Retours ultra rapides !", "¡TURBO ACTIVO! ¡A toda velocidad!")
        case .slowMotion:
            mascotMood = .happy
            speechText = LanguageManager.shared.tr("SLOW MOTION! Easy pickings now.", "RALENTI ACTIVÉ ! Tout en douceur.", "¡CÁMARA LENTA! Qué tranquilidad.")
        case .stickyPaddle:
            mascotMood = .sus
            speechText = LanguageManager.shared.tr("STICKY PADDLE! Tap to launch!", "AIMANT ACTIVÉ ! Touchez pour lancer !", "¡PALA IMÁN! ¡Toca para lanzar!")
        case .doublePoints:
            mascotMood = .party
            speechText = LanguageManager.shared.tr("DOUBLE POINTS! Rack 'em up!", "POINTS DOUBLÉS ! Faites grimper le score !", "¡PUNTOS DOBLES! ¡A sumar!")
        case .shield:
            mascotMood = .happy
            speechText = LanguageManager.shared.tr("SHIELD UP! One free save ready!", "BOUCLIER ACTIF ! Un arrêt garanti !", "¡ESCUDO ACTIVO! ¡Una salvada extra!")
        case .chaosBall:
            mascotMood = .dizzy
            speechText = LanguageManager.shared.tr("CHAOS BALL! Wild bounces ahead!", "BALLE CHAOS ! Rebonds imprévisibles !", "¡BOLA CAOS! ¡Rebotes locos!")
        }
    }

    // MARK: - PingPongSceneDelegate

    nonisolated func sceneDidUpdateState(
        playerScore: Int,
        cpuScore: Int,
        rally: Int,
        activePowerUps: [ActivePowerUpState]
    ) {
        Task { @MainActor in
            if self.playerScore != playerScore {
                self.playerScore = playerScore
                if playerScore > self.highScore {
                    self.highScore = playerScore
                    ScoreManager.shared.updateHighScore(for: .pingPong, score: playerScore)
                }
            }
            if self.cpuScore != cpuScore {
                self.cpuScore = cpuScore
            }
            if self.rally != rally {
                self.rally = rally
            }
            self.activePowerUps = activePowerUps
        }
    }

    nonisolated func sceneDidSpawnPowerUp(_ type: PingPongPowerUpType) {
        Task { @MainActor in
            self.announceSpawnedPowerUp(type)
        }
    }

    nonisolated func sceneDidCollectPowerUp(_ type: PingPongPowerUpType) {
        Task { @MainActor in
            self.announceCollectedPowerUp(type)
        }
    }

    nonisolated func sceneDidTriggerCallout(text: String, colorHex: UInt) {
        Task { @MainActor in
            self.calloutGeneration += 1
            let gen = self.calloutGeneration
            self.calloutColor = Color(hex: colorHex)
            withAnimation(.spring(response: 0.28, dampingFraction: 0.65)) {
                self.calloutText = text
            }
            try? await Task.sleep(nanoseconds: 1_350_000_000)
            if self.calloutGeneration == gen {
                withAnimation(.easeOut(duration: 0.22)) {
                    self.calloutText = nil
                }
            }
        }
    }

    nonisolated func sceneDidFinishGame(
        finalScore: Int,
        playerWon: Bool,
        isNewBest: Bool
    ) {
        Task { @MainActor in
            self.playerScore = finalScore
            self.playerWon = playerWon
            self.isNewBest = isNewBest
            self.mascotMood = (playerWon || isNewBest) ? .party : .sad
            self.speechText = (playerWon || isNewBest)
                ? LanguageManager.shared.tr("New record! You're a table legend!", "Nouveau record ! Quelle légende !", "¡Nuevo récord! ¡Increíble!")
                : LanguageManager.shared.tr("Good rally! One more match?", "Bel échange ! On rejoue ?", "¡Buen partido! ¿Otra vez?")
            self.highScore = ScoreManager.shared.highScore(for: .pingPong)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isGameOver = true
            }
        }
    }
}

// MARK: - Ping Pong Main View (Portrait Only)

struct PingPongView: View {
    let onExit: () -> Void

    @State private var viewModel = PingPongViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showDragHint = true

    var body: some View {
        ZStack {
            // Unified Dark Slate Arcade Background
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // SpriteKit 60 FPS Table Scene
            SpriteView(
                scene: viewModel.scene,
                preferredFramesPerSecond: 60,
                options: [.allowsTransparency, .ignoresSiblingOrder]
            )
            .ignoresSafeArea()

            // Top & Bottom HUD Overlay
            VStack(spacing: 8) {
                topScoreHUD
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 4)

                // MiniCheerUp! Mascot Stage (Top-Left Corner with Speech Bubble & Compact Scoreboard)
                mascotAndScoreStage
                    .padding(.horizontal, Spacing.screenPadding)

                Spacer()

                // Playful Arcade Callout Banner ("GETTING HOT!", "TOO FAST!", etc.)
                if let callout = viewModel.calloutText {
                    Text(callout)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(viewModel.calloutColor)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(CheerUpColors.deepNavy.opacity(0.92))
                                .overlay(
                                    Capsule()
                                        .stroke(viewModel.calloutColor.opacity(0.65), lineWidth: 2)
                                )
                        )
                        .shadow(color: Color.black.opacity(0.45), radius: 8, y: 4)
                        .transition(.scale(scale: 0.7).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .padding(.bottom, 16)
                }

                // Initial One-Handed Drag Hint
                if showDragHint && viewModel.playerScore == 0 && !viewModel.isPaused && !viewModel.isGameOver {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 13, weight: .bold))
                        Text(LanguageManager.shared.tr("Drag horizontally to move paddle", "Glissez pour bouger la raquette", "Desliza para mover la pala"))
                            .font(CheerUpFont.caption)
                    }
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(CheerUpColors.deepNavy.opacity(0.75))
                    .clipShape(Capsule())
                    .allowsHitTesting(false)
                    .padding(.bottom, 6)
                    .transition(.opacity)
                }

                // Active Power-Up Indicators Bar at Bottom
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

            // Game Over Result Overlay (Shared Tap-style GameResultView showing Final Score & Best Score)
            if viewModel.isGameOver {
                GameResultView(
                    gameTitle: "PING PONG",
                    score: viewModel.playerScore,
                    highScore: viewModel.highScore,
                    accentColor: Color(hex: 0x00A896),
                    onReplay: {
                        viewModel.startGame()
                    },
                    onExit: onExit
                )
                .zIndex(20)
            }
        }
        .onAppear {
            viewModel.startGame(mode: .endless)
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

    private var topScoreHUD: some View {
        HStack(alignment: .center) {
            // Exit Button
            Button(action: {
                HapticsManager.shared.selection()
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

            // Mode Switcher Pill (Endless Challenge prioritized, Classic Arcade available)
            HStack(spacing: 4) {
                ForEach(PingPongMode.allCases) { modeItem in
                    let isSelected = viewModel.mode == modeItem
                    Button(action: {
                        viewModel.switchMode(modeItem)
                    }) {
                        Text(modeItem == .endless ? LanguageManager.shared.tr("ENDLESS", "SANS FIN", "SIN FIN") : LanguageManager.shared.tr("CLASSIC", "CLASSIQUE", "CLÁSICO"))
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.mutedSilver)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isSelected ? CheerUpColors.lightGrey : Color.clear)
                            )
                    }
                }
            }
            .padding(3)
            .background(CheerUpColors.darkBlue.opacity(0.9))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1)
            )

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
            // MiniCheerUp! Mascot Cube in the top-left corner (matching Tap & Wheels)
            CheerUpMascotView(mood: viewModel.mascotMood, size: 54)

            // Cheery's Speech Bubble announcing power-ups & rallies
            HStack(spacing: 0) {
                Text(viewModel.speechText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.deepNavy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: 46)
            .background(
                SpeechBubbleShape()
                    .fill(CheerUpColors.lightGrey)
                    .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
            )

            // Compact Score Pill on the Right
            HStack(spacing: 10) {
                VStack(spacing: 0) {
                    Text(LanguageManager.shared.tr("SCORE", "SCORE", "PUNTOS"))
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color(hex: 0x00A896))
                    Text("\(viewModel.playerScore)")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }

                if viewModel.mode == .classic {
                    Divider()
                        .frame(height: 24)
                        .background(CheerUpColors.blueGrey)

                    VStack(spacing: 0) {
                        Text("CPU")
                            .font(.system(size: 9, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0xFF4B5C))
                        Text("\(viewModel.cpuScore)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(CheerUpColors.lightGrey)
                            .monospacedDigit()
                            .contentTransition(.numericText())
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(CheerUpColors.darkBlue.opacity(0.92))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: 0x00A896).opacity(0.45), lineWidth: 1.5)
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Bottom Active Power-Ups Bar

    private var activePowerUpsBar: some View {
        HStack(spacing: 8) {
            if viewModel.activePowerUps.isEmpty {
                Text(LanguageManager.shared.tr("Hit glowing icons on the table for power ups", "Touchez les icônes sur la table pour des bonus", "Golpea los iconos de la mesa para potenciadores"))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(CheerUpColors.mutedSilver.opacity(0.55))
                    .frame(height: 34)
            } else {
                ForEach(viewModel.activePowerUps) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(item.type.color)
                            .frame(width: 8, height: 8)

                        Text(item.type.shortBadge)
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        // Countdown bar
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 34, height: 6)
                            Capsule()
                                .fill(item.type.color)
                                .frame(width: max(2, 34 * CGFloat(item.progress)), height: 6)
                        }

                        Text(String(format: "%.0fs", ceil(item.remaining)))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CheerUpColors.lightGrey)
                            .monospacedDigit()
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(CheerUpColors.darkBlue.opacity(0.92))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(item.type.color.opacity(0.6), lineWidth: 1.5)
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .frame(minHeight: 36)
        .animation(.spring(response: 0.3, dampingFraction: 0.75), value: viewModel.activePowerUps.count)
        .allowsHitTesting(false)
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
