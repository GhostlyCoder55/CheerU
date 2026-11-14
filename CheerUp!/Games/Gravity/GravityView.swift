import SwiftUI
import SpriteKit

// MARK: - Gravity View Model
// Bridges the SpriteKit GravityScene with SwiftUI HUD, MiniCheerUp! mascot
// commentary, tactile D-Pad button controls, quick orb instructions,
// pause/resume handling, and GameResultView.

@Observable
@MainActor
final class GravityViewModel: GravitySceneDelegate {
    var score: Int = 0
    var highScore: Int = 0
    var orientation: GravityOrientation = .south
    var activeEffects: [ActiveElementalEffect] = []

    var isPaused: Bool = false
    var isGameOver: Bool = false
    var isNewBest: Bool = false
    var showTutorial: Bool = false
    var hasUsedRewardedContinue: Bool = false

    // MiniCheerUp! Mascot & Speech Bubble State
    var mascotMood: MascotMood = .happy
    var speechText: String = LanguageManager.shared.tr(
        "Use the buttons below to steer! Crossing edges shifts gravity!",
        "Utilisez les boutons en bas ! Les bords changent la gravité !",
        "¡Usa los botones de abajo! ¡Los bordes cambian la gravedad!"
    )

    let scene: GravityScene

    private static let tutorialSeenKey = "cheerup.gravity.tutorialSeen"

    init() {
        self.highScore = ScoreManager.shared.highScore(for: .gravity)
        self.scene = GravityScene(size: CGSize(width: 393, height: 852))
        self.scene.gameDelegate = self
    }

    func onAppearStart() {
        if !UserDefaults.standard.bool(forKey: Self.tutorialSeenKey) {
            showTutorial = true
            scene.isGamePaused = true
        } else {
            startGame()
        }
    }

    func dismissTutorialAndPlay() {
        UserDefaults.standard.set(true, forKey: Self.tutorialSeenKey)
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showTutorial = false
        }
        startGame()
    }

    func openTutorial() {
        pauseGame()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            showTutorial = true
        }
    }

    func startGame() {
        isPaused = false
        isGameOver = false
        isNewBest = false
        hasUsedRewardedContinue = false
        mascotMood = .happy
        speechText = LanguageManager.shared.tr(
            "Tap the arrows below! Crossing glowing edges rotates gravity!",
            "Touchez les flèches en bas ! Franchir un bord tourne le monde !",
            "¡Toca las flechas abajo! ¡Cruzar bordes gira la gravedad!"
        )
        highScore = ScoreManager.shared.highScore(for: .gravity)
        scene.startNewGame()
        GravityAudioController.shared.startBackgroundMusic()
    }

    func continueAfterReward() {
        guard !hasUsedRewardedContinue else { return }
        hasUsedRewardedContinue = true
        isPaused = false
        isGameOver = false
        isNewBest = false
        mascotMood = .happy
        speechText = LanguageManager.shared.tr(
            "Second chance! Guide the serpent!",
            "Seconde chance ! Guidez le serpent !",
            "¡Segunda oportunidad! ¡Guía a la serpiente!"
        )
        scene.continueAfterReward()
        GravityAudioController.shared.startBackgroundMusic()
    }

    func pauseGame() {
        guard !isGameOver, !isPaused else { return }
        isPaused = true
        scene.isGamePaused = true
        GravityAudioController.shared.pauseBackgroundMusic()
    }

    func resumeGame() {
        guard isPaused else { return }
        isPaused = false
        showTutorial = false
        scene.isGamePaused = false
        GravityAudioController.shared.startBackgroundMusic()
    }

    func stopAudioOnExit() {
        GravityAudioController.shared.stopBackgroundMusic()
    }

    func pressDirectionButton(_ direction: GravityDirection) {
        guard !isPaused, !isGameOver, !showTutorial else { return }
        AudioManager.shared.play(.tap)
        scene.handleSwipe(direction)
    }

    // MARK: - GravitySceneDelegate

    nonisolated func sceneDidUpdateState(
        score: Int,
        orientation: GravityOrientation,
        activeEffects: [ActiveElementalEffect]
    ) {
        Task { @MainActor in
            if self.score != score {
                self.score = score
                if score > self.highScore {
                    self.highScore = score
                    ScoreManager.shared.updateHighScore(for: .gravity, score: score)
                }
            }
            if self.orientation != orientation {
                self.orientation = orientation
            }
            if self.activeEffects != activeEffects {
                self.activeEffects = activeEffects
            }
        }
    }

    nonisolated func sceneDidCollectMote(_ type: ElementalMoteType, pointsAdded: Int) {
        Task { @MainActor in
            switch type {
            case .fire:
                self.mascotMood = .party
                self.speechText = LanguageManager.shared.tr(
                    "Speed boost & double points! (+\(pointsAdded))",
                    "Vitesse + points doublés ! (+\(pointsAdded))",
                    "¡Velocidad y puntos dobles! (+\(pointsAdded))"
                )
            case .water:
                self.mascotMood = .happy
                self.speechText = LanguageManager.shared.tr(
                    "Calm, slower movement. (+\(pointsAdded))",
                    "Mouvement calme et ralenti. (+\(pointsAdded))",
                    "¡Movimiento lento y preciso! (+\(pointsAdded))"
                )
            case .earth:
                self.mascotMood = .wow
                self.speechText = LanguageManager.shared.tr(
                    "Bonus +3 tail growth! (+\(pointsAdded))",
                    "Croissance +3 segments ! (+\(pointsAdded))",
                    "¡Crecimiento +3 segmentos! (+\(pointsAdded))"
                )
            case .wind:
                self.mascotMood = .sus
                self.speechText = LanguageManager.shared.tr(
                    "Pass safely through your tail!",
                    "Traversez votre propre corps !",
                    "¡Atraviesa tu propia cola!"
                )
            }
        }
    }

    nonisolated func sceneDidShiftGravity(_ orientation: GravityOrientation) {
        Task { @MainActor in
            self.orientation = orientation
        }
    }

    nonisolated func sceneDidPhaseThroughSelf() {
        Task { @MainActor in
            self.mascotMood = .party
            self.speechText = LanguageManager.shared.tr(
                "Ghosted right through your tail!",
                "Vous avez traversé votre queue !",
                "¡Atravesaste tu propia cola!"
            )
        }
    }

    nonisolated func sceneDidFinishGame(finalScore: Int, isNewBest: Bool) {
        Task { @MainActor in
            self.score = finalScore
            self.isNewBest = isNewBest
            self.highScore = ScoreManager.shared.highScore(for: .gravity)
            self.mascotMood = isNewBest ? .party : .sad
            self.speechText = isNewBest
                ? LanguageManager.shared.tr("New record in the enchanted forest!", "Nouveau record dans la forêt enchantée !", "¡Nuevo récord en el bosque encantado!")
                : LanguageManager.shared.tr("Tangled in the roots! Try again?", "Emmêlé dans les racines ! On rejoue ?", "¡Enredado! ¿Otra partida?")
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                self.isGameOver = true
            }
        }
    }
}

// MARK: - Gravity Main View (Button Controls + Quick Orb Instructions)

struct GravityView: View {
    let onExit: () -> Void

    @State private var viewModel = GravityViewModel()
    @Environment(\.scenePhase) private var scenePhase
    @State private var hasStartedSession = false

    var body: some View {
        ZStack {
            // Enchanted Forest Dark Slate & Moss Background Gradient
            LinearGradient(
                colors: [
                    Color(hex: 0x10281C),
                    Color(hex: 0x091912),
                    Color(hex: 0x050E0A)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // SpriteKit 60 FPS Enchanted Torus Scene (Controlled via Buttons Below)
            SpriteView(
                scene: viewModel.scene,
                preferredFramesPerSecond: 60,
                options: [.allowsTransparency, .ignoresSiblingOrder, .shouldCullNonVisibleNodes]
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // HUD Overlay (Top Bar, MiniCheerUp! Stage, Quick Orb Instructions, and Bottom D-Pad Buttons)
            VStack(spacing: 6) {
                topNavigationBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 4)

                mascotAndScoreStage
                    .padding(.horizontal, Spacing.screenPadding)

                // Quick Small Instructions of Orb Powers & Gravity Rule
                quickInstructionsStrip
                    .padding(.horizontal, Spacing.screenPadding)

                Spacer()

                // Active Elemental Timers (when active)
                if !viewModel.activeEffects.isEmpty {
                    activeEffectsRow
                        .padding(.horizontal, 6)
                }

                // Tactile Arcade Directional Pad Buttons Below the Board
                directionalButtonsPad
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, 10)
            }

            // Interactive How-To-Play Tutorial Modal
            if viewModel.showTutorial {
                tutorialOverlay
                    .transition(.opacity)
                    .zIndex(15)
            }

            // Pause Modal Overlay
            if viewModel.isPaused && !viewModel.showTutorial {
                pauseOverlay
                    .transition(.opacity)
                    .zIndex(10)
            }

            // Game Over Screen (Consistent with Tap & Ping Pong)
            if viewModel.isGameOver {
                GameResultView(
                    gameTitle: "GRAVITY",
                    score: viewModel.score,
                    highScore: viewModel.highScore,
                    accentColor: Color(hex: 0x10B981),
                    onReplay: {
                        viewModel.startGame()
                    },
                    onExit: {
                        viewModel.stopAudioOnExit()
                        onExit()
                    },
                    onWatchAdContinue: viewModel.hasUsedRewardedContinue ? nil : {
                        viewModel.continueAfterReward()
                    }
                )
                .zIndex(20)
            }
        }
        .onAppear {
            guard !hasStartedSession else { return }
            hasStartedSession = true
            viewModel.onAppearStart()
        }
        .onDisappear {
            if !RewardedAdManager.shared.isPresentingAd {
                viewModel.stopAudioOnExit()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                viewModel.pauseGame()
            } else if !viewModel.isGameOver && !viewModel.isPaused && !viewModel.showTutorial {
                viewModel.scene.isGamePaused = false
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

            // Live Gravity Compass Pill
            HStack(spacing: 6) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color(hex: 0x22D3EE))
                    .rotationEffect(.degrees(viewModel.orientation.compassDegrees))
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: viewModel.orientation)

                Text(viewModel.orientation.title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(CheerUpColors.lightGrey)
                    .tracking(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(hex: 0x0B1E15).opacity(0.92))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(hex: 0x22D3EE).opacity(0.45), lineWidth: 1)
            )

            Spacer()

            HStack(spacing: 8) {
                // Help / Tutorial Button
                Button(action: {
                    HapticsManager.shared.selection()
                    viewModel.openTutorial()
                }) {
                    Image(systemName: "questionmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                        .frame(width: 36, height: 36)
                        .background(CheerUpColors.blueGrey.opacity(0.75))
                        .clipShape(Circle())
                }

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
    }

    // MARK: - MiniCheerUp! Top-Left Mascot Stage + Score Pill

    private var mascotAndScoreStage: some View {
        HStack(spacing: 10) {
            // MiniCheerUp! Mascot Cube in top-left corner
            CheerUpMascotView(mood: viewModel.mascotMood, size: 50)

            // Speech Bubble
            HStack(spacing: 0) {
                Text(viewModel.speechText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.deepNavy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .frame(minHeight: 42)
            .background(
                SpeechBubbleShape()
                    .fill(CheerUpColors.lightGrey)
                    .shadow(color: Color.black.opacity(0.28), radius: 5, x: 0, y: 2)
            )

            // Compact Score Pill on the Right
            VStack(spacing: 0) {
                Text(LanguageManager.shared.tr("SCORE", "SCORE", "PUNTOS"))
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x10B981))
                Text("\(viewModel.score)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(hex: 0x0B1E15).opacity(0.94))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color(hex: 0x10B981).opacity(0.5), lineWidth: 1.5)
            )
        }
        .allowsHitTesting(false)
    }

    // MARK: - Quick Small Instructions of Orb Powers & How the Game Works

    private var quickInstructionsStrip: some View {
        VStack(spacing: 4) {
            // 4 Elemental Orb Powers Legend
            HStack(spacing: 10) {
                ForEach(ElementalMoteType.allCases) { mote in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(mote.color)
                            .frame(width: 7, height: 7)
                        Text(moteLegendLabel(for: mote))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CheerUpColors.lightGrey.opacity(0.92))
                    }
                }
            }

            // One-line rule summary
            Text(
                LanguageManager.shared.tr(
                    "Eat orbs to grow • Crossing borders rotates gravity • Avoid your tail",
                    "Mangez les orbes • Les bords tournent la gravité • Évitez votre queue",
                    "Come orbes • Cruzar bordes gira la gravedad • Evita tu cola"
                )
            )
            .font(.system(size: 10, weight: .medium, design: .rounded))
            .foregroundStyle(CheerUpColors.mutedSilver.opacity(0.85))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(hex: 0x0B1E15).opacity(0.85))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: 0x3E2C1C).opacity(0.65), lineWidth: 1)
        )
        .allowsHitTesting(false)
    }

    private func moteLegendLabel(for type: ElementalMoteType) -> String {
        switch type {
        case .fire:  return LanguageManager.shared.tr("Fire: Fast/2x", "Feu: Vite/2x", "Fuego: 2x")
        case .water: return LanguageManager.shared.tr("Water: Slow", "Eau: Lent", "Agua: Lento")
        case .earth: return LanguageManager.shared.tr("Earth: +3 Size", "Terre: +3", "Tierra: +3")
        case .wind:  return LanguageManager.shared.tr("Wind: Ghost", "Vent: Fantôme", "Viento: Fase")
        }
    }

    // MARK: - Active Elemental Effects Row

    private var activeEffectsRow: some View {
        HStack(spacing: 6) {
            ForEach(viewModel.activeEffects) { effect in
                HStack(spacing: 5) {
                    Circle()
                        .fill(effect.type.color)
                        .frame(width: 7, height: 7)

                    Text(effect.type.shortBadge)
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 18, height: 5)
                        Capsule()
                            .fill(effect.type.color)
                            .frame(width: max(2, 18 * CGFloat(effect.progress)), height: 5)
                    }

                    Text(String(format: "%.0fs", ceil(effect.remaining)))
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(CheerUpColors.lightGrey)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .layoutPriority(2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(height: 30)
                .background(Color(hex: 0x0B1E15).opacity(0.95))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(effect.type.color.opacity(0.65), lineWidth: 1.5)
                )
            }
        }
        .frame(minHeight: 32)
        .allowsHitTesting(false)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: viewModel.activeEffects)
    }

    // MARK: - Tactile Cross (+) Directional Pad

    private var directionalButtonsPad: some View {
        VStack(spacing: 6) {
            // Top arm: UP
            dPadButton(direction: .up, systemIcon: "chevron.up")

            // Middle arms: LEFT + Center Cross Hub + RIGHT
            HStack(spacing: 6) {
                dPadButton(direction: .left, systemIcon: "chevron.left")

                // Center Cross (+) Hub
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(hex: 0x0A1B13))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(hex: 0x10B981).opacity(0.3), lineWidth: 1.5)
                        )

                    Circle()
                        .fill(Color(hex: 0x10B981).opacity(0.45))
                        .frame(width: 12, height: 12)
                }
                .frame(width: 56, height: 56)

                dPadButton(direction: .right, systemIcon: "chevron.right")
            }

            // Bottom arm: DOWN
            dPadButton(direction: .down, systemIcon: "chevron.down")
        }
        .padding(.vertical, 4)
    }

    private func dPadButton(direction: GravityDirection, systemIcon: String) -> some View {
        Button(action: {
            viewModel.pressDirectionButton(direction)
        }) {
            ZStack {
                // 3D Bottom Shadow Base
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.5))
                    .offset(y: 4)

                // Tactile Forest Emerald & Slate Cap
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x1A4230), Color(hex: 0x0E261C)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(hex: 0x10B981).opacity(0.65), lineWidth: 1.8)
                    )

                Image(systemName: systemIcon)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(CheerUpColors.lightGrey)
            }
            .frame(width: 76, height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(CubeButtonStyle())
    }

    // MARK: - Short Tutorial Overlay

    private var tutorialOverlay: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                HStack(spacing: 10) {
                    CheerUpMascotView(mood: .wow, size: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GRAVITY")
                            .font(CheerUpFont.title2)
                            .foregroundStyle(CheerUpColors.lightGrey)
                        Text(LanguageManager.shared.tr("Enchanted Torus Serpent", "Le Serpent du Tore Enchanté", "Serpiente del Toro Encantado"))
                            .font(CheerUpFont.caption)
                            .foregroundStyle(Color(hex: 0x10B981))
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    tutorialRow(
                        icon: "dpad.fill",
                        color: Color(hex: 0x10B981),
                        title: LanguageManager.shared.tr("Steer with Buttons Below", "Dirigez avec les Boutons", "Controla con los Botones"),
                        detail: LanguageManager.shared.tr("Use the 4 arrow buttons below the board to steer the serpent toward glowing orbs.", "Utilisez les 4 flèches sous le plateau pour guider le serpent vers les orbes.", "Usa los 4 botones de flecha debajo del tablero para guiar a la serpiente.")
                    )

                    tutorialRow(
                        icon: "arrow.triangle.2.circlepath.circle.fill",
                        color: Color(hex: 0x22D3EE),
                        title: LanguageManager.shared.tr("Crossing Edges Shifts Gravity", "Les Bords Changent la Gravité", "Cruzar Bordes Cambia la Gravedad"),
                        detail: LanguageManager.shared.tr("Wrapping across a glowing rune border rotates the world's perspective!", "Franchir une bordure runique fait pivoter la perspective du monde !", "¡Cruzar un borde rúnico rota la perspectiva del mundo!")
                    )

                    tutorialRow(
                        icon: "sparkles",
                        color: Color(hex: 0xA855F7),
                        title: LanguageManager.shared.tr("4 Elemental Orbs", "4 Orbes Élémentaires", "4 Orbes Elementales"),
                        detail: LanguageManager.shared.tr("Fire boosts speed & 2x points, Water slows time, Earth grows +3, Wind phases through your tail.", "Feu accélère (2x), Eau ralentit, Terre +3 segments, Vent traverse votre queue.", "Fuego acelera (2x), Agua calma, Tierra +3 segmentos, Viento atraviesa tu cola.")
                    )
                }
                .padding(14)
                .background(Color(hex: 0x07140E).opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                CheerUpPrimaryButton(
                    LanguageManager.shared.tr("Got It, Let's Play!", "Compris, Jouer !", "¡Entendido, A Jugar!"),
                    icon: "play.fill",
                    action: {
                        HapticsManager.shared.selection()
                        viewModel.dismissTutorialAndPlay()
                    }
                )
            }
            .padding(Spacing.xxl)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                    .fill(Color(hex: 0x0B1E15))
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                            .stroke(Color(hex: 0x10B981).opacity(0.45), lineWidth: 1.5)
                    )
            )
            .popIn()
        }
    }

    private func tutorialRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 26, alignment: .center)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(CheerUpColors.lightGrey)
                Text(detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(CheerUpColors.mutedSilver)
                    .fixedSize(horizontal: false, vertical: true)
            }
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
