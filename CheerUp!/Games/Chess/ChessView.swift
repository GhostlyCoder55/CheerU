import SwiftUI
import SpriteKit
import Combine

// MARK: - Chess View Model

@Observable
@MainActor
final class ChessViewModel: ChessSceneDelegate {
    private(set) var engine = ChessSessionEngine(difficulty: .intermediate, timeControl: .untimed)
    let scene: ChessScene

    var difficulty: ChessDifficulty = .intermediate
    var humanColor: PieceColor = .light
    var timeControl: ChessTimeControl = .untimed
    var showModeSetup: Bool = true
    var selectedSquare: ChessSquare? = nil
    var highlightedMoves: [ChessMove] = []
    var pendingPromotion: PendingPromotion? = nil

    var isPaused: Bool = false
    var isThinking: Bool = false
    var isAnimating: Bool = false
    var status: ChessGameStatus = .playing
    var turn: PieceColor = .light
    var lastMoveNotation: String = ""
    var fullMoveNumber: Int = 1

    var whiteTimeRemaining: TimeInterval = 0
    var blackTimeRemaining: TimeInterval = 0

    // MiniCheerUp! Mascot & Speech Bubble State
    var mascotMood: MascotMood = .happy
    var speechText: String = LanguageManager.shared.tr(
        "Pick your challenge to begin the match!",
        "Choisissez votre niveau pour commencer !",
        "¡Elige la dificultad para empezar!"
    )

    // Dynamic arcade callout pill ("CHECK!", "CASTLED!", "PROMOTION!")
    var calloutText: String? = nil
    var calloutColor: Color = Color(hex: 0xF3DDB0)
    private var calloutGeneration: Int = 0

    private var aiTask: Task<Void, Never>?
    private var sessionToken: UUID = UUID()
    private var isActiveInForeground = true
    private var lastTickDate = Date()
    private var hasPresentedEndOfSessionAd = false
    private var hasRecordedOutcomeForMatch = false

    var gamesWon: Int = ScoreManager.shared.highScore(for: .chess)

    init() {
        self.scene = ChessScene()
        self.scene.gameDelegate = self
        self.scene.syncBoardImmediately(from: engine.state)
        syncPublishedState()
        RewardedAdManager.shared.preloadWheelsAdIfNeeded()
    }

    // MARK: - Lifecycle, Pause & Clocks

    func pauseGame() {
        guard !showModeSetup, !status.isTerminal, !isPaused else { return }
        isPaused = true
        scene.isGamePaused = true
        lastTickDate = Date()
    }

    func resumeGame() {
        guard isPaused else { return }
        isPaused = false
        scene.isGamePaused = false
        lastTickDate = Date()
    }

    func handleScenePhaseChange(_ phase: ScenePhase) {
        isActiveInForeground = (phase == .active)
        lastTickDate = Date()
        if phase != .active {
            pauseGame()
        } else if !showModeSetup && !status.isTerminal && !isPaused {
            scene.isGamePaused = false
        }
    }

    func tickClockIfNeeded(now: Date) {
        let elapsed = now.timeIntervalSince(lastTickDate)
        lastTickDate = now
        guard isActiveInForeground,
              !showModeSetup,
              !isPaused,
              pendingPromotion == nil,
              !status.isTerminal,
              timeControl.initialSeconds != nil,
              elapsed > 0, elapsed < 2.0 else { return }

        if let winner = engine.tickClock(elapsed: elapsed) {
            cancelAI()
            selectedSquare = nil
            highlightedMoves = []
            scene.clearSelectionAndMarkers()
            syncPublishedState()
            recordOutcomeIfNeeded(winner: winner)
            AudioManager.shared.play(winner == humanColor ? .win : .error)
            mascotMood = winner == humanColor ? .party : .sad
            speechText = winner == humanColor
                ? LanguageManager.shared.tr("Opponent's clock ran out! Victory!", "Temps adverse écoulé ! Victoire !", "¡Tiempo rival agotado! ¡Victoria!")
                : LanguageManager.shared.tr("Out of time! Better luck next game.", "Temps écoulé ! Retentez votre chance.", "¡Sin tiempo! Inténtalo de nuevo.")
            presentEndOfSessionAdIfNeeded()
        } else {
            whiteTimeRemaining = engine.whiteTimeRemaining
            blackTimeRemaining = engine.blackTimeRemaining
        }
    }

    // MARK: - Match Setup & Game Controls

    func beginMatch(difficulty: ChessDifficulty, playerColor: PieceColor, timeControl: ChessTimeControl) {
        self.difficulty = difficulty
        self.humanColor = playerColor
        self.timeControl = timeControl
        self.showModeSetup = false
        startNewGame(difficulty: difficulty, playerColor: playerColor, timeControl: timeControl)
        AudioManager.shared.play(.nextLevel)
    }

    func openModeSetup() {
        cancelAI()
        isPaused = false
        scene.isGamePaused = false
        showModeSetup = true
    }

    func startNewGame(difficulty: ChessDifficulty? = nil, playerColor: PieceColor? = nil, timeControl: ChessTimeControl? = nil) {
        cancelAI()
        sessionToken = UUID()
        if let difficulty { self.difficulty = difficulty }
        if let playerColor { self.humanColor = playerColor }
        if let timeControl { self.timeControl = timeControl }

        scene.playerColor = self.humanColor
        isPaused = false
        scene.isGamePaused = false
        hasPresentedEndOfSessionAd = false
        hasRecordedOutcomeForMatch = false
        gamesWon = ScoreManager.shared.highScore(for: .chess)
        RewardedAdManager.shared.preloadWheelsAdIfNeeded()
        engine.reset(difficulty: self.difficulty, timeControl: self.timeControl)
        selectedSquare = nil
        highlightedMoves = []
        pendingPromotion = nil
        calloutText = nil
        isAnimating = false
        lastTickDate = Date()
        scene.syncBoardImmediately(from: engine.state)
        syncPublishedState()

        mascotMood = .happy
        if self.humanColor == .light {
            speechText = LanguageManager.shared.tr(
                "Tap or drag any cream piece to make your move!",
                "Touchez ou glissez une pièce crème pour jouer !",
                "¡Toca o arrastra una pieza crema para mover!"
            )
        } else {
            speechText = LanguageManager.shared.tr(
                "Cream moves first! AI opening...",
                "Les crèmes jouent d'abord ! Ouverture de l'IA...",
                "¡Mueven las crema primero! Apertura de la IA..."
            )
            scheduleAIMove()
        }
        HapticsManager.shared.selection()
    }

    func selectPromotion(_ move: ChessMove) {
        pendingPromotion = nil
        executeMoveWithAnimation(move, byHuman: true)
    }

    func cleanupOnExit() {
        cancelAI()
        sessionToken = UUID()
    }

    // MARK: - ChessSceneDelegate (Tap & Drag)

    func chessSceneDidTapSquare(_ square: ChessSquare) {
        handleBoardTap(square)
    }

    func chessSceneDidDragPiece(from: ChessSquare, to: ChessSquare) -> Bool {
        guard !showModeSetup, !isAnimating, !isThinking, !isPaused, pendingPromotion == nil else { return false }
        guard !status.isTerminal, turn == humanColor else { return false }

        let legal = engine.state.legalMoves(from: from).filter { $0.to == to }
        guard !legal.isEmpty else { return false }

        selectedSquare = nil
        highlightedMoves = []
        scene.clearSelectionAndMarkers()

        if legal.count > 1, legal.allSatisfy({ $0.promotion != nil }) {
            scene.syncBoardImmediately(from: engine.state)
            pendingPromotion = PendingPromotion(from: from, to: to, color: humanColor, options: legal)
            AudioManager.shared.play(.tap)
            return true
        } else if let move = legal.first {
            executeMoveWithAnimation(move, byHuman: true)
            return true
        }
        return false
    }

    private func handleBoardTap(_ square: ChessSquare) {
        guard !showModeSetup, !isAnimating, !isThinking, !isPaused, pendingPromotion == nil else { return }
        guard !status.isTerminal, turn == humanColor else { return }

        if let _ = selectedSquare {
            let matchingMoves = highlightedMoves.filter { $0.to == square }
            if !matchingMoves.isEmpty {
                if matchingMoves.count > 1, matchingMoves.allSatisfy({ $0.promotion != nil }) {
                    selectedSquare = nil
                    highlightedMoves = []
                    scene.clearSelectionAndMarkers()
                    pendingPromotion = PendingPromotion(
                        from: matchingMoves[0].from,
                        to: square,
                        color: humanColor,
                        options: matchingMoves
                    )
                    AudioManager.shared.play(.tap)
                    return
                } else if let move = matchingMoves.first {
                    selectedSquare = nil
                    highlightedMoves = []
                    executeMoveWithAnimation(move, byHuman: true)
                    return
                }
            }
        }

        if let tappedPiece = engine.state.piece(at: square), tappedPiece.color == humanColor {
            let legal = engine.state.legalMoves(from: square)
            if legal.isEmpty {
                selectedSquare = nil
                highlightedMoves = []
                scene.clearSelectionAndMarkers()
                let inCheck = engine.state.isKingInCheck(for: humanColor)
                let kingSq = engine.state.kingSquare(for: humanColor)
                scene.nudgeBlockedPiece(pieceID: tappedPiece.id, kingSquare: inCheck ? kingSq : nil)
                mascotMood = .wow
                speechText = inCheck
                    ? LanguageManager.shared.tr(
                        "Your King is in check! Move to protect the King.",
                        "Votre Roi est en échec ! Protégez le Roi.",
                        "¡Tu Rey está en jaque! Protege al Rey."
                    )
                    : LanguageManager.shared.tr(
                        "No legal moves for that piece right now!",
                        "Aucun coup légal pour cette pièce !",
                        "¡Esa pieza no tiene jugadas legales ahora!"
                    )
                return
            }

            selectedSquare = square
            highlightedMoves = legal
            scene.showSelection(pieceID: tappedPiece.id, legalMoves: legal)
            AudioManager.shared.play(.tap)
        } else {
            deselectSquare()
        }
    }

    private func deselectSquare() {
        selectedSquare = nil
        highlightedMoves = []
        scene.clearSelectionAndMarkers()
    }

    // MARK: - Move Execution & AI Pipeline

    private func recordOutcomeIfNeeded(winner: PieceColor?) {
        guard !hasRecordedOutcomeForMatch else { return }
        hasRecordedOutcomeForMatch = true
        gamesWon = ScoreManager.shared.recordChessOutcome(winner: winner, humanColor: humanColor)
    }

    private func executeMoveWithAnimation(_ move: ChessMove, byHuman: Bool) {
        let activeToken = sessionToken
        guard engine.performMove(move) else { return }
        let postState = engine.state
        syncPublishedState()
        updateMascotAndCallout(for: move, status: postState.status, byHuman: byHuman)

        if postState.status.isTerminal {
            // Persist win streak immediately so exiting mid-animation never drops a win
            recordOutcomeIfNeeded(winner: postState.status.winner)
        }

        isAnimating = true
        scene.animateMove(move, resultingState: postState) { [weak self] in
            guard let self, self.sessionToken == activeToken else { return }
            self.isAnimating = false
            if postState.status.isTerminal {
                self.recordOutcomeIfNeeded(winner: postState.status.winner)
                self.presentEndOfSessionAdIfNeeded()
            } else if postState.turn != self.humanColor {
                self.scheduleAIMove()
            }
        }
    }

    /// Presents a forced ad once when a Chess game session finishes.
    private func presentEndOfSessionAdIfNeeded() {
        guard !hasPresentedEndOfSessionAd else { return }
        hasPresentedEndOfSessionAd = true
        let activeToken = sessionToken

        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 850_000_000)
            guard let self, self.sessionToken == activeToken, self.status.isTerminal else { return }
            RewardedAdManager.shared.presentWheelsAd(
                onRewardEarned: {
                    RewardedAdManager.shared.preloadWheelsAdIfNeeded()
                },
                onDismissedWithoutReward: {
                    RewardedAdManager.shared.preloadWheelsAdIfNeeded()
                }
            )
        }
    }

    private func scheduleAIMove() {
        cancelAI()
        let activeToken = sessionToken
        let boardSnapshot = engine.state
        let chosenDifficulty = difficulty
        isThinking = true

        aiTask = Task { [weak self] in
            let thinkStart = Date()
            let chosenMove = await Task.detached(priority: .userInitiated) {
                ChessAI.bestMove(for: boardSnapshot, difficulty: chosenDifficulty)
            }.value

            let elapsed = Date().timeIntervalSince(thinkStart)
            let minDelay: TimeInterval = 0.20
            if elapsed < minDelay {
                let waitNs = UInt64((minDelay - elapsed) * 1_000_000_000)
                try? await Task.sleep(nanoseconds: waitNs)
            }

            guard let self, !Task.isCancelled, self.sessionToken == activeToken else { return }
            self.isThinking = false
            guard let move = chosenMove, !self.engine.state.status.isTerminal else { return }
            self.executeMoveWithAnimation(move, byHuman: false)
        }
    }

    private func cancelAI() {
        aiTask?.cancel()
        aiTask = nil
        isThinking = false
    }

    private func syncPublishedState() {
        status = engine.state.status
        turn = engine.state.turn
        fullMoveNumber = engine.state.fullMoveNumber
        lastMoveNotation = engine.state.lastMove?.notation ?? ""
        whiteTimeRemaining = engine.whiteTimeRemaining
        blackTimeRemaining = engine.blackTimeRemaining
    }

    private func triggerCallout(_ text: String, color: Color) {
        calloutGeneration += 1
        let gen = calloutGeneration
        calloutColor = color
        withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
            calloutText = text
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_700_000_000)
            if self.calloutGeneration == gen {
                withAnimation(.easeOut(duration: 0.25)) {
                    self.calloutText = nil
                }
            }
        }
    }

    private func updateMascotAndCallout(for move: ChessMove, status: ChessGameStatus, byHuman: Bool) {
        switch status {
        case .checkmate(let winner):
            triggerCallout(
                LanguageManager.shared.tr("CHECKMATE!", "ÉCHEC ET MAT !", "¡JAQUE MATE!"),
                color: winner == humanColor ? Color(hex: 0xF3DDB0) : CheerUpColors.Tap.red
            )
            if winner == humanColor {
                mascotMood = .party
                speechText = LanguageManager.shared.tr("CHECKMATE! Brilliant victory!", "ÉCHEC ET MAT ! Magnifique victoire !", "¡JAQUE MATE! ¡Victoria brillante!")
            } else {
                mascotMood = .sad
                speechText = LanguageManager.shared.tr("Checkmate! Rematch anytime!", "Échec et mat ! On prend la revanche ?", "¡Jaque mate! ¿Revancha cuando quieras?")
            }
        case .check(let victimColor):
            let aiInCheck = victimColor != humanColor
            triggerCallout(
                LanguageManager.shared.tr("CHECK!", "ÉCHEC !", "¡JAQUE!"),
                color: aiInCheck ? Color(hex: 0x2EDB8A) : CheerUpColors.Tap.red
            )
            mascotMood = aiInCheck ? .party : .wow
            speechText = aiInCheck
                ? LanguageManager.shared.tr("Nice check! Keep up the pressure!", "Joli échec ! Maintenez la pression !", "¡Buen jaque! ¡Sigue presionando!")
                : LanguageManager.shared.tr("Watch out — your King is in check!", "Attention — votre Roi est en échec !", "¡Cuidado! ¡Tu Rey está en jaque!")
        case .stalemate:
            triggerCallout(LanguageManager.shared.tr("STALEMATE", "PAT", "AHOGADO"), color: CheerUpColors.lightGrey)
            mascotMood = .sus
            speechText = LanguageManager.shared.tr("Stalemate! A hard-fought draw.", "Pat ! Match nul très disputé.", "¡Ahogado! Empate muy reñido.")
        case .drawFiftyMove, .drawThreefoldRepetition, .drawInsufficientMaterial:
            triggerCallout(LanguageManager.shared.tr("DRAW GAME", "MATCH NUL", "TABLAS"), color: CheerUpColors.lightGrey)
            mascotMood = .sus
            speechText = LanguageManager.shared.tr("Draw game! Well balanced.", "Partie nulle ! Bien équilibré.", "¡Tablas! Partida muy equilibrada.")
        default:
            if move.promotion != nil {
                triggerCallout(
                    LanguageManager.shared.tr("PROMOTION!", "PROMOTION !", "¡CORONACIÓN!"),
                    color: Color(hex: 0xF3DDB0)
                )
                mascotMood = byHuman ? .party : .wow
                speechText = byHuman
                    ? LanguageManager.shared.tr("Pawn promoted! Royal power unlocked!", "Pion promu ! Puissance royale !", "¡Peón coronado! ¡Nuevo poder real!")
                    : LanguageManager.shared.tr("Whoa! Opponent promoted a pawn!", "Oh ! L'adversaire a promu un pion !", "¡Vaya! ¡El rival coronó un peón!")
            } else if move.isCastling {
                triggerCallout(
                    LanguageManager.shared.tr("CASTLED!", "ROQUE !", "¡ENROQUE!"),
                    color: Color(hex: 0x22D3EE)
                )
                mascotMood = .happy
                speechText = LanguageManager.shared.tr("Crisp castling! King safely tucked.", "Joli roque ! Le Roi est à l'abri.", "¡Buen enroque! El Rey está seguro.")
            } else if move.isEnPassant {
                triggerCallout("EN PASSANT!", color: Color(hex: 0xF3DDB0))
                mascotMood = .party
                speechText = LanguageManager.shared.tr("En Passant! Classic master tactic!", "Prise en passant ! Coup de maître !", "¡Al paso! ¡Jugada maestra!")
            } else if let cap = move.capturedPiece {
                if cap.kind.value >= 5 {
                    triggerCallout(
                        byHuman
                            ? LanguageManager.shared.tr("BIG CAPTURE!", "GROSSE PRISE !", "¡GRAN CAPTURA!")
                            : LanguageManager.shared.tr("WATCH OUT!", "ATTENTION !", "¡CUIDADO!"),
                        color: byHuman ? Color(hex: 0xF3DDB0) : CheerUpColors.Tap.red
                    )
                }
                mascotMood = byHuman ? .party : .dizzy
                speechText = byHuman
                    ? (cap.kind.value >= 5
                       ? LanguageManager.shared.tr("Huge capture! What a strike!", "Prise énorme ! Quel coup !", "¡Gran captura! ¡Vaya golpe!")
                       : LanguageManager.shared.tr("Clean capture! Material up!", "Jolie prise !", "¡Buena captura!"))
                    : LanguageManager.shared.tr("Ouch! Careful on the next move!", "Aïe ! Attention au prochain coup !", "¡Ay! ¡Ojo en la siguiente jugada!")
            } else if byHuman {
                mascotMood = .happy
                speechText = LanguageManager.shared.tr("Thinking of a reply...", "Réflexion en cours...", "Pensando respuesta...")
            } else {
                mascotMood = .happy
                speechText = LanguageManager.shared.tr("Your turn! Spot the best tactic.", "À vous ! Trouvez le meilleur coup.", "¡Tu turno! Busca la mejor táctica.")
            }
        }
    }

    func formattedClock(_ seconds: TimeInterval) -> String {
        let clamped = max(0, Int(ceil(seconds)))
        let m = clamped / 60
        let s = clamped % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Chess Main Portrait View

struct ChessView: View {
    let onExit: () -> Void

    @State private var viewModel = ChessViewModel()
    @State private var selectedDifficulty: ChessDifficulty = .intermediate
    @State private var selectedPlayerColor: PieceColor = .light
    @State private var selectedTimeControl: ChessTimeControl = .untimed
    @Environment(\.scenePhase) private var scenePhase

    private let clockTimer = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Unified Dark Slate Arcade Background matching all CheerUp! games
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Subtle warm amber ambient glow behind the wooden pixel chessboard
            RadialGradient(
                colors: [
                    Color(hex: 0xB87A44).opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 300
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            VStack(spacing: 4) {
                topNavigationBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, 2)

                mascotAndClockStage
                    .padding(.horizontal, Spacing.screenPadding)

                Spacer(minLength: 0)

                // Maximized SpriteKit 2D Brown-and-Cream Pixel Chessboard
                ZStack(alignment: .top) {
                    SpriteView(
                        scene: viewModel.scene,
                        preferredFramesPerSecond: 60,
                        options: [.allowsTransparency, .ignoresSiblingOrder, .shouldCullNonVisibleNodes]
                    )
                    .aspectRatio(ChessScene.sceneWidth / ChessScene.sceneHeight, contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    if let callout = viewModel.calloutText {
                        HStack(spacing: 6) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(viewModel.calloutColor)
                            Text(callout)
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundStyle(viewModel.calloutColor)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(CheerUpColors.darkBlue.opacity(0.95))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(viewModel.calloutColor.opacity(0.75), lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 6, y: 3)
                        .transition(.scale(scale: 0.8).combined(with: .opacity))
                        .allowsHitTesting(false)
                        .padding(.top, 2)
                    }
                }
                .layoutPriority(1)

                Spacer(minLength: 0)

                bottomActionBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, 6)
            }

            // Pre-Match Difficulty & Clock Selection Overlay
            if viewModel.showModeSetup {
                modeSetupOverlay
                    .transition(.opacity)
                    .zIndex(12)
            }

            // Pawn Promotion Modal
            if let promo = viewModel.pendingPromotion {
                promotionOverlay(promo)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
                    .zIndex(15)
            }

            // Pause Modal Overlay
            if viewModel.isPaused {
                pauseOverlay
                    .transition(.opacity)
                    .zIndex(20)
            }

            // End-of-Game Modal
            if viewModel.status.isTerminal && !viewModel.isAnimating {
                gameOverOverlay
                    .transition(.opacity)
                    .zIndex(25)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            viewModel.handleScenePhaseChange(newPhase)
        }
        .onReceive(clockTimer) { now in
            viewModel.tickClockIfNeeded(now: now)
        }
        .onDisappear {
            if !RewardedAdManager.shared.isPresentingAd {
                viewModel.cleanupOnExit()
            }
        }
    }

    // MARK: - Top Navigation Bar

    private var topNavigationBar: some View {
        HStack(alignment: .center, spacing: 8) {
            Button(action: {
                HapticsManager.shared.selection()
                viewModel.cleanupOnExit()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .background(CheerUpColors.blueGrey.opacity(0.75))
                    .clipShape(Circle())
            }

            Spacer()

            // Active Match Mode Pill (e.g. "CHESS • Intermediate")
            HStack(spacing: 6) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: 0xF3DDB0))
                Text("CHESS • \(viewModel.difficulty.localizedTitle)")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundStyle(CheerUpColors.lightGrey)
                if viewModel.timeControl != .untimed {
                    Text("• \(viewModel.timeControl.shortTitle)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xF3DDB0))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(CheerUpColors.darkBlue.opacity(0.9))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1))

            Spacer()

            Button(action: {
                HapticsManager.shared.selection()
                viewModel.pauseGame()
            }) {
                Image(systemName: "pause.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .frame(width: 34, height: 34)
                    .background(CheerUpColors.blueGrey.opacity(0.75))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Top-Left MiniCheerUp! Mascot Stage + Optional Clocks

    private var mascotAndClockStage: some View {
        HStack(spacing: 10) {
            CheerUpMascotView(mood: viewModel.mascotMood, size: 48)

            HStack(spacing: 0) {
                Text(viewModel.speechText)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
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

            if viewModel.timeControl.initialSeconds != nil {
                let opponentColor = viewModel.humanColor.opponent
                let playerColor = viewModel.humanColor
                VStack(spacing: 3) {
                    clockPill(
                        time: viewModel.formattedClock(opponentColor == .dark ? viewModel.blackTimeRemaining : viewModel.whiteTimeRemaining),
                        active: viewModel.turn == opponentColor && !viewModel.status.isTerminal,
                        isDarkPiece: opponentColor == .dark
                    )
                    clockPill(
                        time: viewModel.formattedClock(playerColor == .dark ? viewModel.blackTimeRemaining : viewModel.whiteTimeRemaining),
                        active: viewModel.turn == playerColor && !viewModel.status.isTerminal,
                        isDarkPiece: playerColor == .dark
                    )
                }
            }
        }
    }

    private func clockPill(time: String, active: Bool, isDarkPiece: Bool) -> some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isDarkPiece ? Color(hex: 0x7A482F) : Color(hex: 0xF3DDB0))
                .overlay(Circle().stroke(Color(hex: 0x24130B), lineWidth: 1))
                .frame(width: 8, height: 8)
            Text(time)
                .font(.system(size: 12, weight: .black, design: .monospaced))
                .foregroundStyle(active ? CheerUpColors.deepNavy : CheerUpColors.lightGrey)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(active ? Color(hex: 0xF3DDB0) : CheerUpColors.darkBlue.opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(active ? Color(hex: 0xFBF0D9) : CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1)
        )
    }

    // MARK: - Bottom Status & New Match Bar

    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Turn / Notation Pill
            HStack(spacing: 6) {
                if viewModel.isThinking {
                    ProgressView()
                        .tint(Color(hex: 0xF3DDB0))
                        .scaleEffect(0.75)
                } else {
                    Circle()
                        .fill(viewModel.turn == .light ? Color(hex: 0xF3DDB0) : Color(hex: 0x7A482F))
                        .overlay(Circle().stroke(Color(hex: 0x24130B), lineWidth: 1.5))
                        .frame(width: 11, height: 11)
                }
                Text(turnSummaryText)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.lightGrey)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(CheerUpColors.darkBlue.opacity(0.92))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1))

            Spacer()

            // New Match / Restart Button (opens difficulty, side & clock selection)
            Button(action: {
                HapticsManager.shared.selection()
                selectedDifficulty = viewModel.difficulty
                selectedPlayerColor = viewModel.humanColor
                selectedTimeControl = viewModel.timeControl
                viewModel.openModeSetup()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 13, weight: .bold))
                    Text(LanguageManager.shared.tr("New Game", "Nouvelle partie", "Nueva partida"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundStyle(CheerUpColors.deepNavy)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: 0xF3DDB0))
                .clipShape(Capsule())
            }
        }
    }

    private var turnSummaryText: String {
        if viewModel.isThinking {
            return LanguageManager.shared.tr("AI thinking...", "IA réfléchit...", "IA pensando...")
        }
        if !viewModel.lastMoveNotation.isEmpty {
            return "\(viewModel.fullMoveNumber). \(viewModel.lastMoveNotation)"
        }
        return viewModel.turn == .light
            ? LanguageManager.shared.tr("Cream to move", "Trait aux Crèmes", "Mueven Crema")
            : LanguageManager.shared.tr("Brown to move", "Trait aux Bruns", "Mueven Marrón")
    }

    // MARK: - Difficulty, Piece Color & Clock Selection Overlay (Triggered when clicking Play)

    private var modeSetupOverlay: some View {
        ZStack {
            Color.black.opacity(0.68)
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                VStack(spacing: 4) {
                    Text("CHESS")
                        .font(CheerUpFont.title)
                        .foregroundStyle(Color(hex: 0xF3DDB0))

                    Text(LanguageManager.shared.tr("Choose AI Difficulty", "Choisissez le niveau de l'IA", "Elige la dificultad de la IA"))
                        .font(CheerUpFont.callout)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                }

                // Difficulty Cards: Easy (Beginner) / Medium (Intermediate) / Hard (Advanced)
                VStack(spacing: 8) {
                    ForEach(ChessDifficulty.allCases) { level in
                        let isSelected = selectedDifficulty == level
                        Button(action: {
                            HapticsManager.shared.selection()
                            AudioManager.shared.play(.tap)
                            selectedDifficulty = level
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(difficultyTitle(level))
                                        .font(.system(size: 16, weight: .black, design: .rounded))
                                        .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.lightGrey)
                                    Text(difficultySubtitle(level))
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundStyle(isSelected ? CheerUpColors.deepNavy.opacity(0.78) : CheerUpColors.mutedSilver)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.mutedSilver.opacity(0.5))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(isSelected ? Color(hex: 0xF3DDB0) : CheerUpColors.deepNavy.opacity(0.7))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(isSelected ? Color(hex: 0xFBF0D9) : CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1.5)
                            )
                        }
                    }
                }

                // Piece Color Selector: Cream (.light) vs Brown (.dark)
                VStack(spacing: 6) {
                    Text(LanguageManager.shared.tr("YOUR PIECES", "VOS PIÈCES", "TUS PIEZAS"))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(CheerUpColors.mutedSilver)

                    HStack(spacing: 8) {
                        ForEach([PieceColor.light, PieceColor.dark], id: \.self) { pieceColor in
                            let isSelected = selectedPlayerColor == pieceColor
                            let isCream = pieceColor == .light
                            Button(action: {
                                HapticsManager.shared.selection()
                                selectedPlayerColor = pieceColor
                            }) {
                                HStack(spacing: 6) {
                                    Image(uiImage: ChessSpriteAssets.pieceImage(kind: .king, color: pieceColor))
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 30)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(
                                            isCream
                                                ? LanguageManager.shared.tr("Cream", "Crème", "Crema")
                                                : LanguageManager.shared.tr("Brown", "Brun", "Marrón")
                                        )
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                        .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.lightGrey)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)

                                        Text(
                                            isCream
                                                ? LanguageManager.shared.tr("Moves 1st", "Joue 1er", "Sale 1.º")
                                                : LanguageManager.shared.tr("Moves 2nd", "Joue 2e", "Sale 2.º")
                                        )
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundStyle(isSelected ? CheerUpColors.deepNavy.opacity(0.78) : CheerUpColors.mutedSilver)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                    }

                                    Spacer(minLength: 2)

                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.mutedSilver.opacity(0.5))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isSelected ? Color(hex: 0xF3DDB0) : CheerUpColors.deepNavy.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(
                                            isSelected ? Color(hex: 0xFBF0D9) : CheerUpColors.blueGrey.opacity(0.6),
                                            lineWidth: 1.5
                                        )
                                )
                            }
                        }
                    }
                }

                // Optional Quick Clock Selector
                VStack(spacing: 6) {
                    Text(LanguageManager.shared.tr("TIME CONTROL", "CADENCE", "RELOJ"))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(CheerUpColors.mutedSilver)

                    HStack(spacing: 8) {
                        ForEach(ChessTimeControl.allCases) { control in
                            let isSelected = selectedTimeControl == control
                            Button(action: {
                                HapticsManager.shared.selection()
                                selectedTimeControl = control
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: control == .untimed ? "infinity" : "timer")
                                        .font(.system(size: 11, weight: .bold))
                                    Text(control.shortTitle)
                                        .font(.system(size: 12, weight: .black, design: .rounded))
                                }
                                .foregroundStyle(isSelected ? CheerUpColors.deepNavy : CheerUpColors.lightGrey)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 9)
                                .background(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .fill(isSelected ? CheerUpColors.lightGrey : CheerUpColors.deepNavy.opacity(0.7))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1)
                                )
                            }
                        }
                    }
                }

                CheerUpPrimaryButton(
                    LanguageManager.shared.tr("Start Match", "Lancer la partie", "Empezar partida"),
                    icon: "play.fill",
                    action: {
                        viewModel.beginMatch(
                            difficulty: selectedDifficulty,
                            playerColor: selectedPlayerColor,
                            timeControl: selectedTimeControl
                        )
                    }
                )
            }
            .padding(Spacing.lg)
            .frame(maxWidth: 344)
            .background(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                    .fill(CheerUpColors.darkBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                            .stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1.5)
                    )
            )
            .popIn()
        }
    }

    private func difficultyTitle(_ level: ChessDifficulty) -> String {
        switch level {
        case .beginner:
            return LanguageManager.shared.tr("Easy", "Facile", "Fácil")
        case .intermediate:
            return LanguageManager.shared.tr("Medium", "Moyen", "Medio")
        case .advanced:
            return LanguageManager.shared.tr("Hard", "Difficile", "Difícil")
        }
    }

    private func difficultySubtitle(_ level: ChessDifficulty) -> String {
        switch level {
        case .beginner:
            return LanguageManager.shared.tr("Relaxed pace for casual play", "Rythme détendu pour s'amuser", "Ritmo relajado para disfrutar")
        case .intermediate:
            return LanguageManager.shared.tr("Balanced tactics & solid defense", "Tactique équilibrée et défense solide", "Táctica equilibrada y defensa sólida")
        case .advanced:
            return LanguageManager.shared.tr("Deep search & sharp counterplay", "Calcul avancé et jeu incisif", "Cálculo profundo y juego preciso")
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
                        LanguageManager.shared.tr("New Game", "Nouvelle partie", "Nueva partida"),
                        icon: "arrow.clockwise",
                        action: {
                            HapticsManager.shared.selection()
                            selectedDifficulty = viewModel.difficulty
                            selectedPlayerColor = viewModel.humanColor
                            selectedTimeControl = viewModel.timeControl
                            viewModel.openModeSetup()
                        }
                    )

                    CheerUpSecondaryButton(
                        LanguageManager.shared.tr("Arcade", "Arcade", "Arcade"),
                        icon: "square.grid.2x2.fill",
                        action: {
                            HapticsManager.shared.selection()
                            viewModel.cleanupOnExit()
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

    // MARK: - Pawn Promotion Overlay

    private func promotionOverlay(_ promo: PendingPromotion) -> some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Text(LanguageManager.shared.tr("CHOOSE PROMOTION", "PROMOTION DU PION", "ELIGE PROMOCIÓN"))
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: 0xF3DDB0))

                HStack(spacing: 12) {
                    ForEach(promo.options, id: \.self) { move in
                        if let kind = move.promotion {
                            Button(action: {
                                viewModel.selectPromotion(move)
                            }) {
                                VStack(spacing: 6) {
                                    Image(uiImage: ChessSpriteAssets.pieceImage(kind: kind, color: promo.color))
                                        .interpolation(.none)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 44, height: 54)
                                    Text(promotionName(kind))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundStyle(Color(hex: 0xF3DDB0))
                                }
                                .padding(10)
                                .background(Color(hex: 0x45291B))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(hex: 0xF3DDB0), lineWidth: 1.5)
                                )
                            }
                        }
                    }
                }
            }
            .padding(20)
            .background(CheerUpColors.darkBlue)
            .clipShape(RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cardCornerRadius, style: .continuous)
                    .stroke(Color(hex: 0xF3DDB0).opacity(0.75), lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.5), radius: 18)
            .popIn()
        }
    }

    private func promotionName(_ kind: PieceKind) -> String {
        switch kind {
        case .queen:  return LanguageManager.shared.tr("Queen", "Dame", "Dama")
        case .rook:   return LanguageManager.shared.tr("Rook", "Tour", "Torre")
        case .bishop: return LanguageManager.shared.tr("Bishop", "Fou", "Alfil")
        case .knight: return LanguageManager.shared.tr("Knight", "Cavalier", "Caballo")
        default:      return ""
        }
    }

    // MARK: - Checkmate / Stalemate / Draw / Timeout Result Modal

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.65)
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                Text("CHESS")
                    .font(CheerUpFont.title2)
                    .foregroundStyle(CheerUpColors.lightGrey)

                VStack(spacing: Spacing.xs) {
                    Text(outcomeHeadline)
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(outcomeColor)
                        .multilineTextAlignment(.center)

                    Text(outcomeDetail)
                        .font(CheerUpFont.callout)
                        .foregroundStyle(CheerUpColors.mutedSilver)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text(LanguageManager.shared.tr("BEST", "RECORD", "RÉCORD"))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CheerUpColors.mutedSilver)
                        Text("\(viewModel.gamesWon)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(viewModel.status.winner == viewModel.humanColor ? Color(hex: 0xF3DDB0) : CheerUpColors.lightGrey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CheerUpColors.deepNavy.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    VStack(spacing: 2) {
                        Text(LanguageManager.shared.tr("MOVES", "COUPS", "JUGADAS"))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(CheerUpColors.mutedSilver)
                        Text("\(viewModel.fullMoveNumber)")
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .foregroundStyle(CheerUpColors.lightGrey)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(CheerUpColors.deepNavy.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                VStack(spacing: Spacing.md) {
                    CheerUpPrimaryButton(
                        LanguageManager.shared.tr("Play Again", "Rejouer", "Jugar otra vez"),
                        icon: "arrow.clockwise",
                        action: {
                            HapticsManager.shared.selection()
                            selectedDifficulty = viewModel.difficulty
                            selectedPlayerColor = viewModel.humanColor
                            selectedTimeControl = viewModel.timeControl
                            viewModel.openModeSetup()
                        }
                    )

                    CheerUpSecondaryButton(
                        LanguageManager.shared.tr("Arcade", "Arcade", "Arcade"),
                        icon: "square.grid.2x2.fill",
                        action: {
                            HapticsManager.shared.selection()
                            viewModel.cleanupOnExit()
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

    private var outcomeHeadline: String {
        switch viewModel.status {
        case .checkmate(let w):
            return w == viewModel.humanColor
                ? LanguageManager.shared.tr("VICTORY!", "VICTOIRE !", "¡VICTORIA!")
                : LanguageManager.shared.tr("CHECKMATE", "ÉCHEC ET MAT", "JAQUE MATE")
        case .timeout(let w):
            return w == viewModel.humanColor
                ? LanguageManager.shared.tr("TIME WIN!", "VICTOIRE AU TEMPS !", "¡VICTORIA POR TIEMPO!")
                : LanguageManager.shared.tr("TIME OUT", "TEMPS ÉCOULÉ", "TIEMPO AGOTADO")
        case .stalemate:
            return LanguageManager.shared.tr("STALEMATE", "PAT", "AHOGADO")
        case .drawFiftyMove, .drawThreefoldRepetition, .drawInsufficientMaterial:
            return LanguageManager.shared.tr("DRAW", "MATCH NUL", "TABLAS")
        default:
            return ""
        }
    }

    private var outcomeDetail: String {
        switch viewModel.status {
        case .checkmate(let w):
            return w == viewModel.humanColor
                ? LanguageManager.shared.tr("You checkmated the AI!", "Vous avez maté l'IA !", "¡Diste jaque mate a la IA!")
                : LanguageManager.shared.tr("The AI checkmated your King.", "L'IA a maté votre Roi.", "La IA dio jaque mate a tu Rey.")
        case .timeout(let w):
            return w == viewModel.humanColor
                ? LanguageManager.shared.tr("Opponent ran out of time.", "Le temps de l'adversaire est écoulé.", "El rival se quedó sin tiempo.")
                : LanguageManager.shared.tr("Your clock reached 0:00.", "Votre horloge a atteint 0:00.", "Tu reloj llegó a 0:00.")
        case .stalemate:
            return LanguageManager.shared.tr("No legal moves remaining.", "Aucun coup légal restant.", "Sin jugadas legales posibles.")
        case .drawFiftyMove:
            return LanguageManager.shared.tr("50 moves without capture or pawn push.", "50 coups sans prise ni avancée de pion.", "50 jugadas sin captura ni avance de peón.")
        case .drawThreefoldRepetition:
            return LanguageManager.shared.tr("Same position repeated three times.", "Position répétée trois fois.", "Misma posición repetida tres veces.")
        case .drawInsufficientMaterial:
            return LanguageManager.shared.tr("Neither side has enough material to mate.", "Matériel insuffisant pour mater.", "Material insuficiente para dar mate.")
        default:
            return ""
        }
    }

    private var outcomeColor: Color {
        if let w = viewModel.status.winner {
            return w == viewModel.humanColor ? Color(hex: 0xF3DDB0) : CheerUpColors.Tap.red
        }
        return CheerUpColors.lightGrey
    }
}
