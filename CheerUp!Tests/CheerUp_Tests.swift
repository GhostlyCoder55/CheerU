//
//  CheerUp_Tests.swift
//  CheerUp!Tests
//

import Testing
import CoreGraphics
import UIKit
@testable import CheerUp_

struct CheerUp_Tests {

    @Test func scoreManagerStoresAndRetrieves() async throws {
        let current = ScoreManager.shared.highScore(for: .tap)
        ScoreManager.shared.updateHighScore(for: .tap, score: current + 10)
        #expect(ScoreManager.shared.highScore(for: .tap) == current + 10)
    }

    @Test func tapEngineStartsAndGeneratesCubes() async throws {
        let engine = TapEngine()
        engine.startGame()
        #expect(engine.lives == 3)
        #expect(engine.cubeOrder.count == 4)
    }

    @Test func rushEngineMovementAndSurvivalScoring() async throws {
        let engine = RushEngine()
        engine.reset()
        engine.setInvulnerable(for: 10.0)
        #expect(engine.score == 0)
        #expect(!engine.isGameOver)

        // Advance simulation by 6.0 seconds (61 steps of 0.05s = 3.05s -> 1pt, 122 steps of 0.05s = 6.1s -> 2pts)
        for _ in 0..<61 {
            _ = engine.update(dt: 0.05, targetShipPosition: CGPoint(x: 260, y: 120))
        }
        #expect(engine.shipX > 220)
        #expect(!engine.asteroids.isEmpty)
        #expect(engine.score >= 1)

        for _ in 0..<61 {
            _ = engine.update(dt: 0.05, targetShipPosition: CGPoint(x: 260, y: 120))
        }
        #expect(engine.score >= 2)
    }

    @Test func audioManagerHandlesAllKenneyEffects() async throws {
        AudioManager.shared.setEnabled(true)
        #expect(AudioManager.shared.isEnabled)
        AudioManager.shared.play(.tap)
        AudioManager.shared.play(.pop)
        AudioManager.shared.play(.switchToggle)
        AudioManager.shared.play(.bounce)
        AudioManager.shared.play(.nextLevel)
        AudioManager.shared.play(.win)
        AudioManager.shared.play(.error)
        AudioManager.shared.play(.combo)
        AudioManager.shared.play(.ding)
        AudioManager.shared.play(.slimeStick)
        AudioManager.shared.play(.successTrumpet)
    }

    @Test func wheelsEngineSpinAndOutcomes() async throws {
        // Verify all timed Wheels challenges have doubled durations (10s...30s, even values)
        let timedOutcomes = WheelsData.outcomes.compactMap(\.timerSeconds)
        #expect(timedOutcomes.count == 29)
        #expect(timedOutcomes.allSatisfy { $0 >= 10 && $0 <= 30 && $0 % 2 == 0 })

        let engine = WheelsEngine()
        #expect(!engine.isSpinning)
        #expect(engine.selectedOutcome == nil)

        engine.spin()
        #expect(engine.isSpinning)
        #expect(engine.selectedOutcome != nil)
        #expect(engine.mascotMood == .wow)

        // Advance tick through completion
        engine.tick(dt: 6.0)
        #expect(!engine.isSpinning)
        #expect(engine.selectedOutcome != nil)
    }

    @Test func wheelsAdTriggersEveryFiveSpins() async throws {
        let engine = WheelsEngine()
        engine.resetSpinCount()
        #expect(engine.spinCount == 0)

        for i in 1...5 {
            engine.spin()
            engine.tick(dt: 6.0)
            #expect(engine.spinCount == i)
        }
        #expect(engine.spinCount == 5)
        #expect(engine.selectedOutcome != nil)
    }

    @Test func appStateNavigation() async throws {
        let state = AppState()
        #expect(!state.isPlayingGame)
        #expect(!state.showingIntro)

        state.selectGame(.tap)
        #expect(state.showingIntro)
        #expect(state.selectedGame == .tap)

        state.startGame()
        #expect(state.isPlayingGame)
        #expect(!state.showingIntro)

        state.exitToArcade()
        #expect(!state.isPlayingGame)
        #expect(state.selectedGame == nil)
    }

    @Test func languageManagerTranslatesEnglishFrenchSpanish() async throws {
        let lm = LanguageManager.shared

        lm.currentLanguage = .english
        #expect(lm.tr("Play", "Jouer", "Jugar") == "Play")

        lm.currentLanguage = .french
        #expect(lm.tr("Play", "Jouer", "Jugar") == "Jouer")

        lm.currentLanguage = .spanish
        #expect(lm.tr("Play", "Jouer", "Jugar") == "Jugar")

        // Reset to default
        lm.currentLanguage = .english
    }

    @Test func hapticsManagerMethodsExecute() async throws {
        let hm = HapticsManager.shared
        hm.setEnabled(true)
        #expect(hm.isEnabled)
        hm.lightTap()
        hm.mediumImpact()
        hm.heavyImpact()
        hm.selection()
        hm.success()
        hm.warning()
        hm.error()
    }

    @Test func tapEngineIncorrectPickDoesNotSpawnConfetti() async throws {
        let engine = TapEngine()
        engine.startGame()
        #expect(engine.particles.isEmpty)
        #expect(engine.burstRings.isEmpty)

        // Find an incorrect cube
        let wrongCube = TapCube(id: 99, name: "INVALID", color: .black, hex: 0x000000)
        engine.selectCube(wrongCube, tapPoint: .zero)
        #expect(engine.particles.isEmpty)
        #expect(engine.burstRings.isEmpty)
    }

    @Test func tapEngineConfettiPhysicsDecaysAndCleansUp() async throws {
        let engine = TapEngine()
        let ring = TapBurstRing(x: 100, y: 200, color: .white)
        let particle = TapPixelParticle(
            x: 100,
            y: 200,
            vx: 300,
            vy: -400,
            rotation: 0,
            vr: 180,
            size: 12,
            color: .white,
            lifetime: 0.5
        )
        engine.burstRings = [ring]
        engine.particles = [particle]

        engine.tick(dt: 0.1)
        #expect(engine.particles.count == 1)
        #expect(engine.particles[0].x > 100)
        #expect(engine.burstRings.count == 1)
        #expect(engine.burstRings[0].radius > 22)

        for _ in 0..<10 {
            engine.tick(dt: 0.1)
        }
        #expect(engine.particles.isEmpty)
        #expect(engine.burstRings.isEmpty)
    }

    @Test func wheelsAllOutcomesHaveTrilingualSupport() async throws {
        #expect(WheelsData.outcomes.count >= 24)
        for outcome in WheelsData.outcomes {
            #expect(!outcome.titleEn.isEmpty)
            #expect(!outcome.titleFr.isEmpty)
            #expect(!outcome.titleEs.isEmpty)
            #expect(!outcome.textEn.isEmpty)
            #expect(!outcome.textFr.isEmpty)
            #expect(!outcome.textEs.isEmpty)
        }
    }

    @Test func pingPongEngineMovementAndRallyPhysics() async throws {
        let engine = PingPongEngine()
        engine.reset(mode: .endless)
        #expect(engine.playerScore == 0)
        #expect(engine.cpuScore == 0)
        #expect(!engine.isGameOver)

        // Advance 15 steps of 0.05s (0.75s) to pass initial serve delay (0.55s)
        for _ in 0..<15 {
            _ = engine.update(dt: 0.05, targetPlayerX: 220)
        }
        #expect(engine.ballVel.dy != 0)
        #expect(engine.playerX > 180)
    }

    @Test func pingPongPowerUpsAndDifficultyProgression() async throws {
        #expect(PingPongPowerUpType.allCases.count == 8)
        #expect(PingPongPowerUpType.allCases.contains(.doubleBall))
        #expect(PingPongPowerUpType.doubleBall.uiColorHex == 0xF5F8FC)
        for powerUp in PingPongPowerUpType.allCases {
            let img = PingPongPixelArt.shared.powerUpImage(for: powerUp)
            #expect(img.size.width > 0 && img.size.height > 0)
        }
        let tier1 = PingPongDifficultyTier.forScore(0, rallyCount: 0)
        let tierMax = PingPongDifficultyTier.forScore(55, rallyCount: 20)
        #expect(tier1 == .rookie)
        #expect(tierMax == .unstoppable)

        // Verify Double Ball persistence & independent ball lifecycle
        let engine = PingPongEngine()
        engine.reset(mode: .endless)
        for _ in 0..<60 {
            _ = engine.update(dt: 0.03, targetPlayerX: 180)
            if engine.ballVel.dy < 0 {
                break
            }
        }
        engine.spawnExtraBall()
        #expect(engine.hasExtraBall)
        #expect(!engine.activePowerUps.contains(where: { $0.type == .doubleBall }))

        // Move paddle out of the way (far left) and step until the first ball is missed:
        // Game must NOT end when the first of the two balls is missed, only when both are missed.
        var sawSingleBallRemaining = false
        var missedLineEventsCount = 0
        for _ in 0..<1200 {
            let events = engine.update(dt: 0.02, targetPlayerX: 20)
            for ev in events {
                if case .ballMissedLine = ev {
                    missedLineEventsCount += 1
                }
            }
            if !engine.hasExtraBall && !engine.isGameOver {
                sawSingleBallRemaining = true
                #expect(engine.ballVel.dy != 0)
            }
            if engine.isGameOver {
                break
            }
        }
        #expect(sawSingleBallRemaining)
        #expect(missedLineEventsCount >= 2)
        #expect(engine.isGameOver)
    }

    @Test func gravityEngineMovementAndBoundaryShift() async throws {
        // Verify orb scoring, Earth +1 default growth, and weighted spawn frequency (Earth dominant, Fire/Water rare)
        #expect(ElementalMoteType.earth.points == 1)
        #expect(ElementalMoteType.water.points == 1)
        #expect(ElementalMoteType.fire.points == 2)
        #expect(ElementalMoteType.wind.points == 2)
        #expect(ElementalMoteType.earth.growthSegments == 1)
        #expect(ElementalMoteType.earth.effectDuration == 0.0)

        var counts: [ElementalMoteType: Int] = [:]
        for step in 0..<100 {
            let type = GravityEngine.randomElementalMoteType(roll: (Double(step) + 0.5) / 100.0)
            counts[type, default: 0] += 1
        }
        #expect(counts[.earth, default: 0] == 60)
        #expect(counts[.wind, default: 0] == 18)
        #expect(counts[.fire, default: 0] == 11)
        #expect(counts[.water, default: 0] == 11)
        #expect(counts[.earth, default: 0] > counts[.wind, default: 0])
        #expect(counts[.wind, default: 0] > counts[.fire, default: 0])
        #expect(counts[.wind, default: 0] > counts[.water, default: 0])

        let engine = GravityEngine()
        engine.reset()
        #expect(engine.score == 0)
        #expect(engine.segments.count == 4)
        #expect(engine.orientation == .south)
        #expect(engine.spawnedMotes.count == 3)

        // Advance enough steps (50 steps at 0.05s = 2.5s) for the serpent to cross the top boundary and shift gravity
        var shifted = false
        for _ in 0..<50 {
            let events = engine.update(dt: 0.05)
            if events.contains(where: {
                if case .gravityShifted = $0 { return true }
                return false
            }) {
                shifted = true
                break
            }
        }
        #expect(shifted)
        #expect(engine.orientation != .south)
    }

    @Test func gameCenterManagerLeaderboardIDs() async throws {
        let gcm = GameCenterManager.shared
        #expect(gcm.leaderboardID(for: .tap) == "com.gc.cheerup.tap.highscore")
        #expect(gcm.leaderboardID(for: .pingPong) == "com.gc.cheerup.pingpong.highscore")
        #expect(gcm.leaderboardID(for: .gravity) == "com.gc.cheerup.gravity.highscore")
        #expect(gcm.leaderboardID(for: .rush) == "com.gc.cheerup.rush.highscore")
        #expect(gcm.leaderboardID(for: .chess) == "com.gc.cheerup.chess.wins")
        #expect(gcm.leaderboardID(for: .wheels) == nil)

        #expect(PingPongGameCenterManager.leaderboardID == "com.gc.cheerup.pingpong.highscore")
        #expect(GravityGameCenterManager.leaderboardID == "com.gc.cheerup.gravity.highscore")
        #expect(RushGameCenterManager.leaderboardID == "com.gc.cheerup.rush.highscore")
    }

    @Test func allGameIdentifiersAreConfiguredWithDescriptionsAndIcons() async throws {
        for game in GameIdentifier.allCases {
            #expect(!game.title.isEmpty)
            #expect(!game.subtitle.isEmpty)
            #expect(!game.shortDescription.isEmpty)
            #expect(!game.symbol.isEmpty)
        }
    }

    @Test @MainActor func notificationManagerConfiguresTwoDayTrilingualReminders() async throws {
        #expect(NotificationManager.twoDaysInterval == 172_800)
        #expect(NotificationManager.reminderIdentifier == "cheerup.reminder.twoDays")
        #expect(!NotificationManager.reminderMessages.isEmpty)

        for message in NotificationManager.reminderMessages {
            #expect(!message.en.isEmpty)
            #expect(!message.fr.isEmpty)
            #expect(!message.es.isEmpty)
        }

        let manager = await NotificationManager.shared
        let enContent = await manager.makeReminderContent(for: .english, index: 0)
        let frContent = await manager.makeReminderContent(for: .french, index: 0)
        let esContent = await manager.makeReminderContent(for: .spanish, index: 0)

        #expect(enContent.title == "CheerUp!")
        #expect(enContent.body == NotificationManager.reminderMessages[0].en)
        #expect(frContent.body == NotificationManager.reminderMessages[0].fr)
        #expect(esContent.body == NotificationManager.reminderMessages[0].es)
        #expect(enContent.sound == .default)
    }

    @Test func rewardedAdManagerPreventsDuplicatesOverlapsAndUnrewardedDismissals() async throws {
        #expect(AdMobConfig.arcadeRewardedAdUnitID == "ca-app-pub-8075634631393674/9803471775")
        #expect(AdMobConfig.testArcadeRewardedAdUnitID == "ca-app-pub-3940256099942544/1712485313")
        #expect(AdMobConfig.wheelsAdUnitID == "ca-app-pub-8075634631393674/3191805276")
        #expect(AdMobConfig.testWheelsAdUnitID == "ca-app-pub-3940256099942544/6978759866")

        let manager = await RewardedAdManager.shared

        // 1. Successful reward & duplicate reward prevention
        var rewardCount = 0
        var dismissedWithoutRewardCount = 0
        let started = await manager.beginTestPresentation(
            onRewardEarned: { rewardCount += 1 },
            onDismissedWithoutReward: { dismissedWithoutRewardCount += 1 }
        )
        #expect(started)

        // Overlapping presentation should be rejected
        let overlapStarted = await manager.beginTestPresentation(onRewardEarned: {})
        #expect(!overlapStarted)

        // First reward confirmation succeeds; second duplicate confirmation is ignored
        let firstMark = await manager.markRewardEarned()
        let secondMark = await manager.markRewardEarned()
        #expect(firstMark)
        #expect(!secondMark)

        await manager.completePresentation(didFailToPresent: false)
        #expect(rewardCount == 1)
        #expect(dismissedWithoutRewardCount == 0)

        // 2. Cancelled ad (dismissed without reward)
        var cancelledRewardCount = 0
        var cancelledDismissCount = 0
        _ = await manager.beginTestPresentation(
            onRewardEarned: { cancelledRewardCount += 1 },
            onDismissedWithoutReward: { cancelledDismissCount += 1 }
        )
        await manager.completePresentation(didFailToPresent: false)
        #expect(cancelledRewardCount == 0)
        #expect(cancelledDismissCount == 1)

        // 3. Failed presentation
        var failedRewardCount = 0
        var failedDismissCount = 0
        _ = await manager.beginTestPresentation(
            onRewardEarned: { failedRewardCount += 1 },
            onDismissedWithoutReward: { failedDismissCount += 1 }
        )
        _ = await manager.markRewardEarned()
        await manager.completePresentation(didFailToPresent: true, errorMessage: "Network error")
        #expect(failedRewardCount == 0)
        #expect(failedDismissCount == 1)
        let currentState = await manager.state
        #expect(currentState == .failed("Network error"))
    }

    @Test func supportedGamesContinueAfterRewardedAd() async throws {
        // Tap: gets 1 heart back, preserves round/score, allows continue only once per run
        let tap = TapEngine()
        tap.startGame()
        tap.lives = 0
        tap.round = 5
        tap.isOver = true
        #expect(!tap.hasUsedRewardedContinue)
        tap.continueAfterReward()
        #expect(!tap.isOver)
        #expect(tap.lives == 1)
        #expect(tap.round == 5)
        #expect(tap.hasUsedRewardedContinue)
        // Second continue in same run is blocked
        tap.lives = 0
        tap.isOver = true
        tap.continueAfterReward()
        #expect(tap.isOver)
        #expect(tap.lives == 0)
        // Starting a new game resets one-time continue
        tap.startGame()
        #expect(!tap.hasUsedRewardedContinue)

        // Rush: preserves score, ship position, asteroid field, grants 3.5s invulnerability, one-time per run
        let rush = RushEngine()
        rush.reset()
        rush.setInvulnerable(for: 10.0)
        for _ in 0..<61 {
            _ = rush.update(dt: 0.05, targetShipPosition: nil)
        }
        let rushScoreBefore = rush.score
        #expect(rushScoreBefore >= 1)
        #expect(!rush.hasUsedRewardedContinue)
        rush.continueAfterReward()
        #expect(!rush.isGameOver)
        #expect(rush.invulnerabilityTimer == 3.5)
        #expect(rush.score == rushScoreBefore)
        #expect(rush.hasUsedRewardedContinue)
        for _ in 0..<61 {
            _ = rush.update(dt: 0.05, targetShipPosition: nil)
        }
        #expect(rush.score > rushScoreBefore)
        rush.reset()
        #expect(!rush.hasUsedRewardedContinue)

        // Gravity: preserves score, serpent segments/length, grants white orb transparent ability, one-time per run
        let gravity = GravityEngine()
        gravity.reset()
        let initialSnakeLength = gravity.segments.count
        #expect(!gravity.hasUsedRewardedContinue)
        gravity.continueAfterReward()
        #expect(!gravity.isGameOver)
        #expect(gravity.segments.count == initialSnakeLength)
        #expect(gravity.isWindPhaseActive)
        #expect(gravity.hasUsedRewardedContinue)
        gravity.reset()
        #expect(!gravity.hasUsedRewardedContinue)

        // Ping Pong: preserves playerScore, undoes fatal miss, one-time per run
        let pingPong = PingPongEngine()
        pingPong.reset(mode: .endless)
        #expect(!pingPong.hasUsedRewardedContinue)
        pingPong.continueAfterReward()
        #expect(!pingPong.isGameOver)
        #expect(pingPong.cpuScore == 0)
        #expect(pingPong.hasUsedRewardedContinue)
        pingPong.reset(mode: .endless)
        #expect(!pingPong.hasUsedRewardedContinue)
    }

    // MARK: - Chess Mini-Game Comprehensive Tests

    @Test func chessIdentifierAndIntegrationMetadata() async throws {
        #expect(GameIdentifier.chess.title == "CHESS")
        #expect(GameIdentifier.chess.isGame)
        #expect(!GameIdentifier.chess.subtitle.isEmpty)
        #expect(!GameIdentifier.chess.shortDescription.isEmpty)

        // "Best: X" on Arcade Home tracks the number of chess games won
        let defaults = UserDefaults.standard
        let savedBest = defaults.object(forKey: "cheerup.highscore.chess")
        defer {
            if let savedBest { defaults.set(savedBest, forKey: "cheerup.highscore.chess") } else { defaults.removeObject(forKey: "cheerup.highscore.chess") }
        }

        defaults.removeObject(forKey: "cheerup.highscore.chess")
        #expect(ScoreManager.shared.highScore(for: .chess) == 0)

        // First CHESS win updates Best to 1
        #expect(ScoreManager.shared.recordChessOutcome(winner: .light) == 1)
        #expect(ScoreManager.shared.highScore(for: .chess) == 1)
        // Second win increments Best to 2
        #expect(ScoreManager.shared.recordChessOutcome(winner: .light) == 2)
        #expect(ScoreManager.shared.highScore(for: .chess) == 2)
        // Loss does not reset games won; next win increments Best to 3
        #expect(ScoreManager.shared.recordChessOutcome(winner: .dark) == 2)
        #expect(ScoreManager.shared.recordChessOutcome(winner: .light) == 3)
        // Winning as Brown (.dark) also increments Best to 4
        #expect(ScoreManager.shared.recordChessOutcome(winner: .dark, humanColor: .dark) == 4)
        #expect(ScoreManager.shared.highScore(for: .chess) == 4)
        #expect(WheelsData.outcomes.count >= 55)
    }

    @Test func chessOpeningPositionAndLegalMovesCount() async throws {
        let state = ChessBoardState()
        #expect(state.turn == .light)
        #expect(state.status == .playing)
        // Standard chess opening has 16 pawn pushes + 4 knight moves = 20 legal moves
        #expect(state.legalMoves().count == 20)
        #expect(ChessSquare(algebraic: "a1")?.isLightSquare == false)
        #expect(ChessSquare(algebraic: "h1")?.isLightSquare == true)
        #expect(ChessSquare(algebraic: "a8")?.isLightSquare == true)
    }

    @Test func chessScholarsMateDetection() async throws {
        var state = ChessBoardState()
        func play(_ from: String, _ to: String) {
            let f = ChessSquare(algebraic: from)!
            let t = ChessSquare(algebraic: to)!
            let mv = state.legalMoves(from: f).first { $0.to == t }!
            let moved = state.makeMove(mv)
            #expect(moved)
        }
        play("e2", "e4")
        play("e7", "e5")
        play("f1", "c4")
        play("b8", "c6")
        play("d1", "h5")
        play("g8", "f6")
        play("h5", "f7") // Checkmate!
        #expect(state.status == .checkmate(winner: .light))
        #expect(state.legalMoves().isEmpty)
    }

    @Test func chessCastlingRulesAndThroughCheckPrevention() async throws {
        // Clear both sides for White
        var clean = ChessBoardState(fen: "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")!
        let kingSq = ChessSquare(algebraic: "e1")!
        let kingMoves = clean.legalMoves(from: kingSq)
        #expect(kingMoves.contains { $0.isCastlingKingside && $0.to == ChessSquare(algebraic: "g1")! })
        #expect(kingMoves.contains { $0.isCastlingQueenside && $0.to == ChessSquare(algebraic: "c1")! })

        // Execute queenside castle and verify rook lands on d1
        let qCastle = kingMoves.first { $0.isCastlingQueenside }!
        let castled = clean.makeMove(qCastle)
        #expect(castled)
        #expect(clean.piece(at: ChessSquare(algebraic: "c1")!)?.kind == .king)
        #expect(clean.piece(at: ChessSquare(algebraic: "d1")!)?.kind == .rook)

        // Attacking f1 blocks kingside castling
        let f1Attacked = ChessBoardState(fen: "4k2r/8/8/8/8/5r2/8/R3K2R w KQkq - 0 1")!
        let attackedKingMoves = f1Attacked.legalMoves(from: ChessSquare(algebraic: "e1")!)
        #expect(!attackedKingMoves.contains { $0.isCastlingKingside })
    }

    @Test func chessEnPassantCaptureAndDiscoveredCheckGuard() async throws {
        // Legal en passant: Black just played c7-c5 next to White pawn on d5
        var epState = ChessBoardState(fen: "4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")!
        let e5 = ChessSquare(algebraic: "e5")!
        let d6 = ChessSquare(algebraic: "d6")!
        let epMove = epState.legalMoves(from: e5).first { $0.to == d6 && $0.isEnPassant }
        #expect(epMove != nil)
        let capturedEP = epState.makeMove(epMove!)
        #expect(capturedEP)
        #expect(epState.piece(at: ChessSquare(algebraic: "d5")!) == nil)
        #expect(epState.piece(at: d6)?.kind == .pawn)

        // Horizontal discovered check prevents en passant along rank 5
        let pinnedEP = ChessBoardState(fen: "8/8/8/K1Pp3r/8/8/8/4k3 w - d6 0 1")!
        let c5 = ChessSquare(algebraic: "c5")!
        #expect(!pinnedEP.legalMoves(from: c5).contains { $0.isEnPassant })
    }

    @Test func chessPawnPromotionSupportsAllFourPieces() async throws {
        for choice in PieceKind.promotableKinds {
            var promoState = ChessBoardState(fen: "7k/4P3/8/8/8/8/8/4K3 w - - 0 1")!
            let e7 = ChessSquare(algebraic: "e7")!
            let e8 = ChessSquare(algebraic: "e8")!
            let options = promoState.legalMoves(from: e7).filter { $0.to == e8 }
            #expect(options.count == 4)
            let chosen = options.first { $0.promotion == choice }!
            let promoted = promoState.makeMove(chosen)
            #expect(promoted)
            #expect(promoState.piece(at: e8)?.kind == choice)
        }
    }

    @Test func chessStalemateAndDrawConditions() async throws {
        // Stalemate: Black king on a8, White queen c7, White king b6
        let stale = ChessBoardState(fen: "k7/2Q5/1K6/8/8/8/8/8 b - - 0 1")!
        #expect(stale.status == .stalemate)

        // Insufficient material cases
        let kVsK = ChessBoardState(fen: "4k3/8/8/8/8/8/8/4K3 w - - 0 1")!
        #expect(kVsK.status == .drawInsufficientMaterial)

        let sameBishops = ChessBoardState(fen: "4k1b1/8/8/8/8/8/8/4KB2 w - - 0 1")!
        // f1 (5+0=5 light), g8 (6+7=13 light) -> both light squares
        #expect(sameBishops.status == .drawInsufficientMaterial)

        // 50-move rule at halfMoveClock = 100
        let fifty = ChessBoardState(fen: "4k3/8/8/8/8/8/4R3/4K3 w - - 100 80")!
        #expect(fifty.status == .drawFiftyMove)

        // Threefold repetition with Knight back-and-forth
        var rep = ChessBoardState()
        func ply(_ f: String, _ t: String) {
            let sqF = ChessSquare(algebraic: f)!
            let sqT = ChessSquare(algebraic: t)!
            let m = rep.legalMoves(from: sqF).first { $0.to == sqT }!
            let ok = rep.makeMove(m)
            #expect(ok)
        }
        for _ in 0..<2 {
            ply("g1", "f3"); ply("g8", "f6")
            ply("f3", "g1"); ply("f6", "g8")
        }
        #expect(rep.status == .drawThreefoldRepetition)
    }

    @Test @MainActor func chessAIDifficultiesUndoAndQuickClock() async throws {
        for diff in ChessDifficulty.allCases {
            // Forced mate-in-1 for Black on h2
            let matePos = ChessBoardState(fen: "6k1/8/8/8/8/6Q1/7P/6K1 b - - 0 1")!
            let aiMove = ChessAI.bestMove(for: matePos, difficulty: diff)
            #expect(aiMove != nil)
        }

        // Session Undo & 3-Min / 5-Min Quick Clocks
        let session = ChessSessionEngine(difficulty: .intermediate, timeControl: .threeMinutes)
        #expect(session.whiteTimeRemaining == 180)
        #expect(session.blackTimeRemaining == 180)
        let e2 = ChessSquare(algebraic: "e2")!
        let e4 = ChessSquare(algebraic: "e4")!
        let whiteMove = session.state.legalMoves(from: e2).first { $0.to == e4 }!
        #expect(session.performMove(whiteMove))
        let e7 = ChessSquare(algebraic: "e7")!
        let e5 = ChessSquare(algebraic: "e5")!
        let blackMove = session.state.legalMoves(from: e7).first { $0.to == e5 }!
        #expect(session.performMove(blackMove))
        #expect(session.canUndo)

        // Undo rolls back AI + Player turns back to starting White turn
        #expect(session.undoToPlayerTurn() == 2)
        #expect(session.state.turn == .light)
        #expect(session.state.piece(at: e4) == nil)
        #expect(session.state.piece(at: e2)?.kind == .pawn)

        // Clock timeout check
        let timedWinner = session.tickClock(elapsed: 181)
        #expect(timedWinner == .dark)
        #expect(session.state.status == .timeout(winner: .dark))

        // Reset restores 5-min clock cleanly
        session.reset(difficulty: .advanced, timeControl: .fiveMinutes)
        #expect(session.whiteTimeRemaining == 300)
        #expect(session.state.status == .playing)

        // Verify Play Again (openModeSetup) cleanly dismisses terminal Game Over state
        let vm = ChessViewModel()
        vm.beginMatch(difficulty: .beginner, playerColor: .light, timeControl: .threeMinutes)
        vm.tickClockIfNeeded(now: Date().addingTimeInterval(0.5))
        vm.openModeSetup()
        #expect(vm.showModeSetup)
        #expect(!vm.status.isTerminal)
    }

    @Test func rushSpritesFlameBoostOrbAndContactCalibration() async throws {
        // 1. All 8 new spaceship sprites, 12 flame-boost sprites, and 8 asteroid sprites exist in Assets.xcassets
        for i in 0..<8 {
            #expect(UIImage(named: "rush_ship_\(i)") != nil)
            #expect(UIImage(named: "rush_asteroid_\(i)") != nil)
        }
        for i in 0..<12 {
            #expect(UIImage(named: "rush_flame_ship_\(i)") != nil)
        }

        // 2. Flaming Orange Orb properties: 5.0s duration, flaming orange color (0xFF5500)
        #expect(RushPowerUpType.flameBoost.duration == 5.0)
        #expect(RushPowerUpType.flameBoost.colorHex == 0xFF5500)
        #expect(!RushPowerUpType.flameBoost.badgeTitle.isEmpty)

        // 3. Contact Calibration: solid hull vs exhaust tail
        let engine = RushEngine()
        engine.reset()
        let directHullHit = RushMeteor(
            x: engine.shipX,
            y: engine.shipY + 20.0,
            vx: 0,
            vy: -100,
            rotation: 0,
            angularVelocity: 0
        )
        #expect(engine.isMeteorContactingShip(directHullHit))

        // Far below the hull in the lower exhaust trail or outside solid rock radius should NOT falsely contact
        let belowExhaust = RushMeteor(
            x: engine.shipX,
            y: engine.shipY - 39.0,
            vx: 0,
            vy: -100,
            rotation: 0,
            angularVelocity: 0
        )
        #expect(!engine.isMeteorContactingShip(belowExhaust))
    }
}

// MARK: - Game Center Leaderboard Integration Tests

@Suite(.serialized)
struct GameCenterLeaderboardTests {

    private final class SubmissionRecorder: @unchecked Sendable {
        struct Entry: Equatable {
            let score: Int
            let leaderboardID: String
        }

        private let lock = NSLock()
        private(set) var entries: [Entry] = []

        func record(score: Int, leaderboardID: String) {
            lock.lock()
            entries.append(Entry(score: score, leaderboardID: leaderboardID))
            lock.unlock()
        }
    }

    private final class AtomicFlag: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Bool = false

        func get() -> Bool { lock.withLock { value } }
        func set(_ newValue: Bool) { lock.withLock { value = newValue } }
    }

    @Test func unauthenticatedPlayerNeverBlocksOrSubmits() async throws {
        let recorder = SubmissionRecorder()
        let manager = GameCenterManager(
            isPlayerAuthenticated: { false },
            scoreSubmitter: { score, _, leaderboardID, completion in
                recorder.record(score: score, leaderboardID: leaderboardID)
                completion(nil)
            }
        )

        #expect(!manager.isAuthenticated)
        for game in GameIdentifier.allCases {
            let result: Result<Void, Error> = await withCheckedContinuation { continuation in
                manager.submitScore(42, for: game) { result in
                    continuation.resume(returning: result)
                }
            }
            if case .success = result {
                Issue.record("Expected unauthenticated submission for \(game) to fail")
            }
        }
        #expect(recorder.entries.isEmpty)
    }

    @Test func isolatedManagerRoutesExactIDsAndHandlesNetworkFailure() async throws {
        let recorder = SubmissionRecorder()
        let simulatedError = NSError(domain: "com.gc.test", code: -1009, userInfo: [NSLocalizedDescriptionKey: "Offline"])
        let failNetwork = AtomicFlag()

        let manager = GameCenterManager(
            isPlayerAuthenticated: { true },
            scoreSubmitter: { score, _, leaderboardID, completion in
                recorder.record(score: score, leaderboardID: leaderboardID)
                let shouldFail = failNetwork.get()
                DispatchQueue.global(qos: .utility).async {
                    completion(shouldFail ? simulatedError : nil)
                }
            }
        )

        let expected: [(GameIdentifier, String, Int)] = [
            (.tap, "com.gc.cheerup.tap.highscore", 15),
            (.pingPong, "com.gc.cheerup.pingpong.highscore", 7),
            (.gravity, "com.gc.cheerup.gravity.highscore", 88),
            (.rush, "com.gc.cheerup.rush.highscore", 54),
            (.chess, "com.gc.cheerup.chess.wins", 3)
        ]

        for (game, expectedID, score) in expected {
            let result: Result<Void, Error> = await withCheckedContinuation { continuation in
                manager.submitScore(score, for: game) { result in
                    continuation.resume(returning: result)
                }
            }
            if case .failure(let err) = result {
                Issue.record("Unexpected submission failure for \(game): \(err)")
            }
            #expect(recorder.entries.last == SubmissionRecorder.Entry(score: score, leaderboardID: expectedID))
        }

        // Wheels has no leaderboard, and non-positive scores are skipped cleanly
        let _: Result<Void, Error> = await withCheckedContinuation { continuation in
            manager.submitScore(10, for: .wheels) { result in continuation.resume(returning: result) }
        }
        let _: Result<Void, Error> = await withCheckedContinuation { continuation in
            manager.submitScore(0, for: .tap) { result in continuation.resume(returning: result) }
        }
        #expect(recorder.entries.count == 5)

        // Network failure completes gracefully and stores error without throwing
        failNetwork.set(true)
        let failureResult: Result<Void, Error> = await withCheckedContinuation { continuation in
            manager.submitScore(19, for: .rush) { result in
                continuation.resume(returning: result)
            }
        }
        if case .failure(let error as NSError) = failureResult {
            #expect(error.code == -1009)
        } else {
            Issue.record("Expected offline network error")
        }
        #expect((manager.lastSubmissionError as NSError?)?.code == -1009)
    }

    @Test func intermediateHighScoreUpdatesDoNotSubmitAndChessTracksCumulativeWins() async throws {
        let recorder = SubmissionRecorder()
        GameCenterManager.shared.configureForTesting(
            isPlayerAuthenticated: { true },
            scoreSubmitter: { score, _, leaderboardID, completion in
                recorder.record(score: score, leaderboardID: leaderboardID)
                completion(nil)
            }
        )
        defer { GameCenterManager.shared.resetTestingConfiguration() }

        let chessKey = "cheerup.highscore.chess"
        let pingPongKey = "cheerup.highscore.pingPong"
        let priorChessWins = UserDefaults.standard.object(forKey: chessKey)
        let priorPingPongBest = UserDefaults.standard.object(forKey: pingPongKey)
        defer {
            if let priorChessWins { UserDefaults.standard.set(priorChessWins, forKey: chessKey) } else { UserDefaults.standard.removeObject(forKey: chessKey) }
            if let priorPingPongBest { UserDefaults.standard.set(priorPingPongBest, forKey: pingPongKey) } else { UserDefaults.standard.removeObject(forKey: pingPongKey) }
        }

        // 1. Live high-score updates mid-game must NOT trigger Game Center submissions
        let previousPingBest = ScoreManager.shared.highScore(for: .pingPong)
        ScoreManager.shared.updateHighScore(for: .pingPong, score: previousPingBest + 5)
        #expect(recorder.entries.isEmpty)

        // 2. Chess baseline -> non-wins do NOT increment or submit
        let startingWins = ScoreManager.shared.highScore(for: .chess)
        let lossMatch = UUID()
        let drawMatch = UUID()
        #expect(ScoreManager.shared.recordChessOutcome(winner: .dark, humanColor: .light, matchID: lossMatch) == startingWins)
        #expect(ScoreManager.shared.recordChessOutcome(winner: nil, humanColor: .light, matchID: drawMatch) == startingWins)
        #expect(recorder.entries.isEmpty)

        // 3. First human win increments cumulative total by +1 and submits to chess wins leaderboard
        let winMatch1 = UUID()
        let winsAfter1 = ScoreManager.shared.recordChessOutcome(winner: .light, humanColor: .light, matchID: winMatch1)
        #expect(winsAfter1 == startingWins + 1)
        #expect(ScoreManager.shared.highScore(for: .chess) == startingWins + 1)
        #expect(recorder.entries == [
            SubmissionRecorder.Entry(score: startingWins + 1, leaderboardID: "com.gc.cheerup.chess.wins")
        ])

        // 4. Duplicate completion event for same match does NOT re-increment or re-submit
        let dupWins = ScoreManager.shared.recordChessOutcome(winner: .light, humanColor: .light, matchID: winMatch1)
        #expect(dupWins == startingWins + 1)
        #expect(recorder.entries.count == 1)

        // 5. Starting a new ChessViewModel match preserves cumulative wins; a second win increments to +2
        await MainActor.run {
            let vm = ChessViewModel()
            vm.startNewGame(difficulty: .beginner, playerColor: .dark, timeControl: .untimed)
            #expect(vm.gamesWon == startingWins + 1)
        }
        let winMatch2 = UUID()
        let winsAfter2 = ScoreManager.shared.recordChessOutcome(winner: .dark, humanColor: .dark, matchID: winMatch2)
        #expect(winsAfter2 == startingWins + 2)
        #expect(recorder.entries.count == 2)
        #expect(recorder.entries.last == SubmissionRecorder.Entry(score: startingWins + 2, leaderboardID: "com.gc.cheerup.chess.wins"))
    }

    @Test @MainActor func allArcadeEnginesSubmitOnceAtGameOverAndIgnoreAbandonment() async throws {
        let recorder = SubmissionRecorder()
        GameCenterManager.shared.configureForTesting(
            isPlayerAuthenticated: { true },
            scoreSubmitter: { score, _, leaderboardID, completion in
                recorder.record(score: score, leaderboardID: leaderboardID)
                completion(nil)
            }
        )
        defer { GameCenterManager.shared.resetTestingConfiguration() }

        let keys = ["cheerup.highscore.pingPong", "cheerup.highscore.rush", "cheerup.highscore.gravity", "cheerup.highscore.tap"]
        let savedDefaults = keys.map { ($0, UserDefaults.standard.object(forKey: $0)) }
        defer {
            for (k, v) in savedDefaults {
                if let v { UserDefaults.standard.set(v, forKey: k) } else { UserDefaults.standard.removeObject(forKey: k) }
            }
        }

        // --- Ping Pong (Endless): score increases live without submission, then submits once at game over ---
        let pingPong = PingPongEngine()
        pingPong.reset(mode: .endless)
        var pingEvents: [PingPongEvent] = []
        // Play keeping player paddle tracked to the ball until playerScore >= 1, then abandon paddle so CPU scores
        for _ in 0..<2500 where !pingPong.isGameOver {
            let targetX: CGFloat = pingPong.playerScore >= 1 ? -500 : pingPong.ballPos.x
            pingEvents.append(contentsOf: pingPong.update(dt: 1.0 / 60.0, targetPlayerX: targetX))
            if !pingPong.isGameOver {
                // While game is active, no submission should happen
                #expect(recorder.entries.isEmpty)
            }
        }
        #expect(pingPong.isGameOver)
        #expect(pingPong.playerScore >= 1)
        #expect(recorder.entries.count == 1)
        #expect(recorder.entries.last == SubmissionRecorder.Entry(score: pingPong.playerScore, leaderboardID: "com.gc.cheerup.pingpong.highscore"))

        // Stepping again after gameOver must not submit duplicates
        _ = pingPong.update(dt: 1.0 / 60.0, targetPlayerX: -500)
        #expect(recorder.entries.count == 1)

        // Resetting (simulating abandon/restart before game over) submits 0 times
        pingPong.reset(mode: .classic)
        #expect(recorder.entries.count == 1)

        // --- Rush: earn survival score >= 1 while invulnerable, then collide to trigger single gameOver submission ---
        let rush = RushEngine()
        rush.reset()
        rush.setInvulnerable(for: 3.2)
        var dtTicks = 0
        while rush.score < 1 && dtTicks < 400 {
            _ = rush.update(dt: 0.02, targetShipPosition: CGPoint(x: rush.shipX, y: rush.shipY))
            dtTicks += 1
        }
        #expect(rush.score >= 1)
        #expect(!rush.isGameOver)
        #expect(recorder.entries.count == 1)

        // Allow invulnerability to expire and chase an asteroid until collision triggers gameOver
        var rushSteps = 0
        while !rush.isGameOver && rushSteps < 2000 {
            let target: CGPoint
            if let meteor = rush.asteroids.first(where: { $0.y > rush.shipY }) {
                target = CGPoint(x: meteor.x, y: meteor.y)
            } else {
                target = CGPoint(x: rush.shipX, y: rush.shipY)
            }
            _ = rush.update(dt: 0.02, targetShipPosition: target)
            rushSteps += 1
        }
        #expect(rush.isGameOver)
        #expect(recorder.entries.count == 2)
        #expect(recorder.entries.last == SubmissionRecorder.Entry(score: rush.score, leaderboardID: "com.gc.cheerup.rush.highscore"))
        // Additional updates after gameOver do not duplicate
        _ = rush.update(dt: 0.02, targetShipPosition: nil)
        #expect(recorder.entries.count == 2)

        // --- Gravity: eat 1 mote so score > 0 and length >= 5, then self-collide once ---
        let gravity = GravityEngine()
        gravity.reset()
        var gSteps = 0
        while (gravity.score == 0 || gravity.segments.count < 5) && gSteps < 1000 && !gravity.isGameOver {
            if let mote = gravity.spawnedMotes.first(where: { $0.type != .wind }) ?? gravity.spawnedMotes.first {
                let head = gravity.segments[0]
                if head.x < mote.coord.x { gravity.queueScreenDirection(.right) }
                else if head.x > mote.coord.x { gravity.queueScreenDirection(.left) }
                else if head.y < mote.coord.y { gravity.queueScreenDirection(.up) }
                else if head.y > mote.coord.y { gravity.queueScreenDirection(.down) }
            }
            _ = gravity.update(dt: 0.05)
            gSteps += 1
        }
        // Let any wind-phase or boundary-shift grace timer expire while advancing
        var graceWait = 0
        while (gravity.isEffectActive(.wind) || graceWait < 12) && graceWait < 200 && !gravity.isGameOver {
            _ = gravity.update(dt: 0.05)
            graceWait += 1
        }
        // Trace a tight 2x2 clockwise loop (waiting one grid step per turn) until self-collision
        let turns: [GravityDirection] = [.right, .down, .left, .up]
        for turn in turns + turns where !gravity.isGameOver {
            gravity.queueScreenDirection(turn)
            let startHead = gravity.segments[0]
            var ticks = 0
            while gravity.segments[0] == startHead && !gravity.isGameOver && ticks < 20 {
                _ = gravity.update(dt: 0.05)
                ticks += 1
            }
        }
        #expect(gravity.score > 0)
        #expect(gravity.isGameOver)
        #expect(recorder.entries.count == 3)
        #expect(recorder.entries.last == SubmissionRecorder.Entry(score: gravity.score, leaderboardID: "com.gc.cheerup.gravity.highscore"))
        _ = gravity.update(dt: 0.20)
        #expect(recorder.entries.count == 3)

        // --- Tap: score round 1, then lose all 3 lives -> submits final score once ---
        let tap = TapEngine()
        tap.startGame()
        tap.nextRound()
        #expect(tap.round == 1)
        // Round 1 always uses .tap ("Tap color: <NAME>")
        if let correct = tap.cubeOrder.first(where: { $0.name == tap.instructionWord }) {
            tap.selectCube(correct, tapPoint: .zero)
        }
        tap.nextRound()
        #expect(tap.round == 2)
        // Lose all 3 lives via timer expiry cleanly before queued dispatches advance
        while tap.lives > 0 {
            tap.nextRound(advanceRound: false)
            tap.tick(dt: 10.0)
        }
        #expect(tap.isOver)
        let expectedTapScore = max(0, tap.round - 1)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        #expect(recorder.entries.count == 4)
        #expect(recorder.entries.last == SubmissionRecorder.Entry(score: expectedTapScore, leaderboardID: "com.gc.cheerup.tap.highscore"))
    }
}
