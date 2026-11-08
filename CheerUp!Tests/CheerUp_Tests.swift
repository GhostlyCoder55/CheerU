//
//  CheerUp_Tests.swift
//  CheerUp!Tests
//

import Testing
import CoreGraphics
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
    }

    @Test func wheelsEngineSpinAndOutcomes() async throws {
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

        // Find an incorrect cube
        let wrongCube = TapCube(id: 99, name: "INVALID", color: .black, hex: 0x000000)
        engine.selectCube(wrongCube, tapPoint: .zero)
        #expect(engine.particles.isEmpty)
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
        #expect(PingPongPowerUpType.allCases.count == 7)
        let tier1 = PingPongDifficultyTier.forScore(0, rallyCount: 0)
        let tierMax = PingPongDifficultyTier.forScore(55, rallyCount: 20)
        #expect(tier1 == .rookie)
        #expect(tierMax == .unstoppable)
    }

    @Test func gravityEngineMovementAndBoundaryShift() async throws {
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
        #expect(gcm.leaderboardID(for: .tap) == "com.gc.CheerUp.tap.endless")
        #expect(gcm.leaderboardID(for: .pingPong) == "com.gc.CheerUp.pingpong.endless")
        #expect(gcm.leaderboardID(for: .gravity) == "com.gc.CheerUp.gravity.endless")
        #expect(gcm.leaderboardID(for: .rush) == "com.gc.CheerUp.rush.endless")
        #expect(gcm.leaderboardID(for: .wheels) == nil)
    }

    @Test func allGameIdentifiersAreConfiguredWithDescriptionsAndIcons() async throws {
        for game in GameIdentifier.allCases {
            #expect(!game.title.isEmpty)
            #expect(!game.subtitle.isEmpty)
            #expect(!game.shortDescription.isEmpty)
            #expect(!game.symbol.isEmpty)
        }
    }
}
