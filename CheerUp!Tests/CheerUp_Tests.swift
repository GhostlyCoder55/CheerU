//
//  CheerUp_Tests.swift
//  CheerUp!Tests
//

import Testing
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

    @Test func tradeOffEngineConstraintParadox() async throws {
        let engine = TradeOffEngine()
        #expect(!engine.isFast)
        #expect(!engine.isGood)
        #expect(!engine.isCheap)

        // Turn on Fast, Good, Cheap
        engine.toggle(.fast)
        engine.toggle(.good)
        engine.toggle(.cheap)

        // The paradox: when 3rd is toggled on, one must be sacrificed
        let activeCount = [engine.isFast, engine.isGood, engine.isCheap].filter { $0 }.count
        #expect(activeCount == 2)
        #expect(engine.sacrificedValue == .good)
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
        AudioManager.shared.play(.lose)
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
}
