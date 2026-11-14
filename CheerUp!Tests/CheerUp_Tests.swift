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

    @Test func notificationManagerConfiguresTwoDayTrilingualReminders() async throws {
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
}
