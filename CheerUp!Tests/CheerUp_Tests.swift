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

    @Test @MainActor func hapticsManagerMethodsExecute() async throws {
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
}
