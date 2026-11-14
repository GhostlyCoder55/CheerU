import Foundation
import CoreGraphics

// MARK: - Ping Pong Engine
// Pure 2D arcade table-tennis simulation: delta-time movement, swept collision
// detection, AI opponent with reaction delay & imperfect accuracy, power-ups,
// score & rally progression.

final class PingPongEngine {

    // MARK: - Court Constants (Portrait Reference Space: 360 x 620)
    static let courtWidth: CGFloat  = 360.0
    static let courtHeight: CGFloat = 620.0
    static let wallInset: CGFloat   = 18.0
    static let netY: CGFloat        = 310.0

    static let playerY: CGFloat     = 68.0
    static let cpuY: CGFloat        = 552.0

    static let basePaddleWidth: CGFloat  = 78.0
    static let giantPaddleWidth: CGFloat = 122.0
    static let cpuPaddleWidth: CGFloat   = 74.0
    static let paddleHeight: CGFloat     = 14.0
    static let ballRadius: CGFloat       = 8.5

    // MARK: - Game State
    private(set) var mode: PingPongMode = .endless
    private(set) var playerScore: Int = 0
    private(set) var cpuScore: Int = 0
    private(set) var currentRally: Int = 0
    private(set) var longestRally: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var playerWon: Bool = false
    private(set) var hasUsedRewardedContinue: Bool = false

    private(set) var difficultyTier: PingPongDifficultyTier = .rookie
    private(set) var highestDifficultyReached: PingPongDifficultyTier = .rookie

    // MARK: - Entities
    private(set) var playerX: CGFloat = 180.0
    private(set) var playerVX: CGFloat = 0.0
    private(set) var cpuX: CGFloat = 180.0
    private(set) var cpuVX: CGFloat = 0.0

    private(set) var ballPos: CGPoint = CGPoint(x: 180.0, y: 310.0)
    private(set) var ballVel: CGVector = .zero
    private(set) var baseSpeed: CGFloat = 340.0

    // Sticky paddle state
    private(set) var isBallStuckToPlayer: Bool = false
    private var stuckOffsetX: CGFloat = 0.0
    private var stuckTimer: Double = 0.0

    // Serve pause timer
    private(set) var serveDelayTimer: Double = 0.0
    private var nextServeTowardPlayer: Bool = true

    // Power-ups
    private(set) var spawnedPowerUps: [SpawnedPowerUp] = []
    private(set) var activePowerUps: [ActivePowerUpState] = []
    private var powerUpSpawnTimer: Double = 4.5

    // AI tracking state
    private var aiTargetX: CGFloat = 180.0
    private var aiReactionTimer: Double = 0.0
    private var aiAimErrorOffset: CGFloat = 0.0

    // Callout cooldown so messages don't overlap spam
    private var calloutCooldown: Double = 0.0

    // Classic mode lives or Endless mode shield/lives
    var hasShieldActive: Bool {
        isPowerUpActive(.shield)
    }

    var currentPlayerPaddleWidth: CGFloat {
        isPowerUpActive(.giantPaddle) ? Self.giantPaddleWidth : Self.basePaddleWidth
    }

    var currentSpeedMultiplier: CGFloat {
        if isPowerUpActive(.slowMotion) {
            return 0.64
        } else if isPowerUpActive(.speedBoost) {
            return 1.32
        }
        return 1.0
    }

    var isDoublePoints: Bool {
        isPowerUpActive(.doublePoints)
    }

    var isChaosBall: Bool {
        isPowerUpActive(.chaosBall)
    }

    init() {
        reset(mode: .endless)
    }

    // MARK: - Reset & Serve

    func reset(mode: PingPongMode) {
        self.mode = mode
        playerScore = 0
        cpuScore = 0
        currentRally = 0
        longestRally = 0
        isGameOver = false
        playerWon = false
        hasUsedRewardedContinue = false
        difficultyTier = .rookie
        highestDifficultyReached = .rookie

        playerX = Self.courtWidth / 2
        playerVX = 0
        cpuX = Self.courtWidth / 2
        cpuVX = 0

        spawnedPowerUps.removeAll()
        activePowerUps.removeAll()
        powerUpSpawnTimer = 4.2
        calloutCooldown = 0

        isBallStuckToPlayer = false
        prepareServe(towardPlayer: false, initialDelay: 0.55)
    }

    /// Resumes the current match after a rewarded video ad with an extra attempt.
    func continueAfterReward() {
        guard !hasUsedRewardedContinue else { return }
        hasUsedRewardedContinue = true
        isGameOver = false
        playerWon = false
        if mode == .endless {
            cpuScore = max(0, cpuScore - 1)
        } else {
            cpuScore = max(0, mode.targetScore - 1)
        }
        isBallStuckToPlayer = false
        prepareServe(towardPlayer: false, initialDelay: 0.75)
    }

    private func prepareServe(towardPlayer: Bool, initialDelay: Double = 0.65) {
        isBallStuckToPlayer = false
        currentRally = 0
        ballPos = CGPoint(x: Self.courtWidth / 2, y: Self.netY)
        ballVel = .zero
        serveDelayTimer = initialDelay
        nextServeTowardPlayer = towardPlayer
        aiTargetX = Self.courtWidth / 2
        aiAimErrorOffset = CGFloat.random(in: -22...22)
    }

    private func launchServe() {
        let tierBoost = CGFloat(difficultyTier.rawValue - 1) * 26.0
        baseSpeed = min(560.0, 345.0 + tierBoost)

        let angleRange: ClosedRange<CGFloat> = -0.38...0.38
        let angle = CGFloat.random(in: angleRange)
        let dirY: CGFloat = nextServeTowardPlayer ? -1.0 : 1.0

        ballVel = CGVector(
            dx: sin(angle) * baseSpeed,
            dy: cos(angle) * baseSpeed * dirY
        )
    }

    // MARK: - Sticky Paddle Launch

    func releaseStuckBall() -> [PingPongEvent] {
        guard isBallStuckToPlayer else { return [] }
        isBallStuckToPlayer = false

        let normalizedOffset = max(-1.0, min(1.0, stuckOffsetX / (currentPlayerPaddleWidth * 0.5)))
        let bounceAngle = normalizedOffset * (.pi * 0.34)
        let speed = min(740.0, baseSpeed * 1.12) * currentSpeedMultiplier

        ballVel = CGVector(
            dx: sin(bounceAngle) * speed + playerVX * 0.18,
            dy: abs(cos(bounceAngle) * speed)
        )
        ballPos.y = Self.playerY + Self.paddleHeight * 0.5 + Self.ballRadius + 2.0
        return [.stickyLaunched(position: ballPos)]
    }

    // MARK: - Main Delta-Time Update

    func update(dt rawDt: Double, targetPlayerX: CGFloat?) -> [PingPongEvent] {
        guard !isGameOver else { return [] }
        let dt = min(max(rawDt, 0.0), 1.0 / 20.0)
        var events: [PingPongEvent] = []

        if calloutCooldown > 0 {
            calloutCooldown = max(0, calloutCooldown - dt)
        }

        // 1. Update Player Paddle Position (smooth, immediate response)
        let halfPlayerW = currentPlayerPaddleWidth * 0.5
        let minPlayerX = Self.wallInset + halfPlayerW
        let maxPlayerX = Self.courtWidth - Self.wallInset - halfPlayerW

        if let targetX = targetPlayerX {
            let clampedTarget = max(minPlayerX, min(maxPlayerX, targetX))
            let newX = playerX + (clampedTarget - playerX) * min(1.0, CGFloat(dt * 38.0))
            playerVX = dt > 0.0001 ? (newX - playerX) / CGFloat(dt) : 0
            playerX = newX
        } else {
            playerVX *= 0.8
        }

        // Keep player paddle in bounds if Giant Paddle expired
        playerX = max(minPlayerX, min(maxPlayerX, playerX))

        // 2. Update Active Power-Up Timers
        for i in activePowerUps.indices.reversed() {
            activePowerUps[i].remaining -= dt
            if activePowerUps[i].remaining <= 0 {
                activePowerUps.remove(at: i)
            }
        }

        // 3. Update Spawned Field Power-Ups & Spawning Logic
        updatePowerUpSpawning(dt: dt, events: &events)

        // 4. Handle Serve Delay
        if serveDelayTimer > 0 {
            serveDelayTimer -= dt
            if serveDelayTimer <= 0 {
                launchServe()
            }
            updateCPU(dt: dt)
            return events
        }

        // 5. Handle Ball Stuck on Sticky Paddle
        if isBallStuckToPlayer {
            ballPos = CGPoint(
                x: max(Self.wallInset + Self.ballRadius, min(Self.courtWidth - Self.wallInset - Self.ballRadius, playerX + stuckOffsetX)),
                y: Self.playerY + Self.paddleHeight * 0.5 + Self.ballRadius + 1.0
            )
            stuckTimer -= dt
            if stuckTimer <= 0 {
                events.append(contentsOf: releaseStuckBall())
            }
            updateCPU(dt: dt)
            return events
        }

        // 6. Sub-stepped Ball Physics (prevents tunneling at high speeds)
        let subSteps = 3
        let subDt = CGFloat(dt) / CGFloat(subSteps)

        for _ in 0..<subSteps {
            guard !isGameOver && serveDelayTimer <= 0 && !isBallStuckToPlayer else { break }
            stepBallPhysics(dt: subDt, events: &events)
        }

        // 7. Update CPU Opponent
        updateCPU(dt: dt)

        return events
    }

    // MARK: - Sub-Stepped Ball Physics & Collisions

    private func stepBallPhysics(dt: CGFloat, events: inout [PingPongEvent]) {
        let prevPos = ballPos
        var nextPos = CGPoint(
            x: ballPos.x + ballVel.dx * dt,
            y: ballPos.y + ballVel.dy * dt
        )

        // Left & Right Table Wall Bounces
        let minBallX = Self.wallInset + Self.ballRadius
        let maxBallX = Self.courtWidth - Self.wallInset - Self.ballRadius

        if nextPos.x < minBallX {
            nextPos.x = minBallX + (minBallX - nextPos.x)
            ballVel.dx = abs(ballVel.dx)
            applyChaosDeflectionIfNeeded()
            events.append(.wallBounce(position: nextPos))
        } else if nextPos.x > maxBallX {
            nextPos.x = maxBallX - (nextPos.x - maxBallX)
            ballVel.dx = -abs(ballVel.dx)
            applyChaosDeflectionIfNeeded()
            events.append(.wallBounce(position: nextPos))
        }

        // Check Power-Up Collection by Ball or Player Paddle
        checkPowerUpCollection(at: nextPos, events: &events)

        // Player Paddle Collision (Swept Y check)
        let playerHitY = Self.playerY + Self.paddleHeight * 0.5 + Self.ballRadius
        if ballVel.dy < 0 && prevPos.y >= playerHitY - 6.0 && nextPos.y <= playerHitY {
            let halfW = currentPlayerPaddleWidth * 0.5 + Self.ballRadius + 4.0
            if abs(nextPos.x - playerX) <= halfW {
                // Successful Player Return!
                nextPos.y = playerHitY
                handlePlayerPaddleContact(at: &nextPos, events: &events)
                ballPos = nextPos
                return
            }
        }

        // CPU Paddle Collision (Swept Y check)
        let cpuHitY = Self.cpuY - Self.paddleHeight * 0.5 - Self.ballRadius
        if ballVel.dy > 0 && prevPos.y <= cpuHitY + 6.0 && nextPos.y >= cpuHitY {
            let halfW = Self.cpuPaddleWidth * 0.5 + Self.ballRadius + 3.0
            if abs(nextPos.x - cpuX) <= halfW {
                // CPU Return!
                nextPos.y = cpuHitY
                handleCPUPaddleContact(at: &nextPos, events: &events)
                ballPos = nextPos
                return
            }
        }

        // Shield Bottom Barrier Save
        let shieldLineY: CGFloat = 34.0
        if ballVel.dy < 0 && hasShieldActive && nextPos.y <= shieldLineY {
            nextPos.y = shieldLineY + 2.0
            ballVel.dy = abs(ballVel.dy)
            removePowerUp(.shield)
            events.append(.shieldSaved(position: nextPos))
            triggerCallout(LanguageManager.shared.tr("NICE SAVE!", "BEL ARRÊT !", "¡GRAN SALVADA!"), hex: 0x00D2FF, events: &events, force: true)
            ballPos = nextPos
            return
        }

        // Check Scoring / Out of Bounds
        if nextPos.y < -15.0 {
            // Player missed the ball!
            ballPos = nextPos
            handlePlayerMissed(events: &events)
            return
        } else if nextPos.y > Self.courtHeight + 15.0 {
            // CPU missed the ball! Player scores!
            ballPos = nextPos
            handleCPUMissed(events: &events)
            return
        }

        ballPos = nextPos
    }

    // MARK: - Paddle Contact Physics

    private func handlePlayerPaddleContact(at pos: inout CGPoint, events: inout [PingPongEvent]) {
        currentRally += 1
        longestRally = max(longestRally, currentRally)

        // In Endless Challenge, every 2 rally hits also awards a rally bonus point, keeping fast rallies rewarding
        if mode == .endless && currentRally % 2 == 0 {
            let pts = isDoublePoints ? 2 : 1
            playerScore += pts
            events.append(.playerScored(pointsAdded: pts, newScore: playerScore, position: pos))
            updateDifficultyProgression(events: &events)
        }

        // Check Sticky Paddle
        if isPowerUpActive(.stickyPaddle) {
            isBallStuckToPlayer = true
            stuckOffsetX = max(-currentPlayerPaddleWidth * 0.42, min(currentPlayerPaddleWidth * 0.42, pos.x - playerX))
            stuckTimer = 1.15 // Auto-releases after 1.15s or on tap/drag release
            ballVel = .zero
            events.append(.stickyCaught(position: pos))
            return
        }

        // Calculate reflection angle based on contact offset from paddle center
        let halfW = currentPlayerPaddleWidth * 0.5
        let relativeHit = max(-1.0, min(1.0, (pos.x - playerX) / halfW))
        let maxBounceAngle: CGFloat = .pi * 0.37 // ~66 degrees max

        var bounceAngle = relativeHit * maxBounceAngle
        if isChaosBall {
            bounceAngle += CGFloat.random(in: -0.28...0.28)
            bounceAngle = max(-.pi * 0.42, min(.pi * 0.42, bounceAngle))
        }

        // Gradually increase rally speed
        baseSpeed = min(780.0, baseSpeed + 14.0)
        let isSmash = abs(relativeHit) > 0.72 || abs(playerVX) > 420 || isPowerUpActive(.speedBoost)
        let smashMultiplier: CGFloat = isSmash ? 1.10 : 1.0
        let effectiveSpeed = min(840.0, baseSpeed * currentSpeedMultiplier * smashMultiplier)

        ballVel = CGVector(
            dx: sin(bounceAngle) * effectiveSpeed + playerVX * 0.12,
            dy: abs(cos(bounceAngle) * effectiveSpeed)
        )

        // Ensure vertical speed is never too flat
        let minVerticalSpeed = effectiveSpeed * 0.42
        if ballVel.dy < minVerticalSpeed {
            ballVel.dy = minVerticalSpeed
        }

        events.append(.paddleHit(isPlayer: true, position: pos, speed: effectiveSpeed, isSmash: isSmash))

        // Schedule new AI reaction & imperfect aim error for this incoming shot
        scheduleAIReactionForIncomingShot()

        // Occasional playful arcade callouts
        if abs(pos.x - playerX) >= halfW * 0.86 {
            triggerCallout(LanguageManager.shared.tr("NICE SAVE!", "BEL ARRÊT !", "¡GRAN SALVADA!"), hex: 0x2EDB8A, events: &events)
        } else if effectiveSpeed > 640 {
            triggerCallout(LanguageManager.shared.tr("TOO FAST!", "TROP VITE !", "¡DEMASIADO RÁPIDO!"), hex: 0xFF4B5C, events: &events)
        } else if currentRally == 8 {
            triggerCallout(LanguageManager.shared.tr("GETTING HOT!", "ÇA CHAUFFE !", "¡EN RACHA!"), hex: 0xFFC83D, events: &events)
        } else if currentRally == 16 {
            triggerCallout(LanguageManager.shared.tr("UNSTOPPABLE!", "INARRÊTABLE !", "¡IMPARABLE!"), hex: 0xFF7AB6, events: &events)
        }
    }

    private func handleCPUPaddleContact(at pos: inout CGPoint, events: inout [PingPongEvent]) {
        currentRally += 1
        longestRally = max(longestRally, currentRally)

        let halfW = Self.cpuPaddleWidth * 0.5
        let relativeHit = max(-1.0, min(1.0, (pos.x - cpuX) / halfW))
        var bounceAngle = relativeHit * (.pi * 0.34)

        // Add slight random angle variance from CPU
        bounceAngle += CGFloat.random(in: -0.15...0.15)
        if isChaosBall {
            bounceAngle += CGFloat.random(in: -0.26...0.26)
        }
        bounceAngle = max(-.pi * 0.40, min(.pi * 0.40, bounceAngle))

        baseSpeed = min(780.0, baseSpeed + 10.0)
        let effectiveSpeed = min(820.0, baseSpeed * currentSpeedMultiplier)

        ballVel = CGVector(
            dx: sin(bounceAngle) * effectiveSpeed,
            dy: -abs(cos(bounceAngle) * effectiveSpeed)
        )

        let minVerticalSpeed = effectiveSpeed * 0.45
        if abs(ballVel.dy) < minVerticalSpeed {
            ballVel.dy = -minVerticalSpeed
        }

        events.append(.paddleHit(isPlayer: false, position: pos, speed: effectiveSpeed, isSmash: false))
    }

    private func applyChaosDeflectionIfNeeded() {
        guard isChaosBall else { return }
        let speed = hypot(ballVel.dx, ballVel.dy)
        guard speed > 10 else { return }
        let currentAngle = atan2(ballVel.dx, abs(ballVel.dy))
        let tweakedAngle = max(-.pi * 0.40, min(.pi * 0.40, currentAngle + CGFloat.random(in: -0.32...0.32)))
        let signY: CGFloat = ballVel.dy >= 0 ? 1.0 : -1.0
        ballVel.dx = sin(tweakedAngle) * speed
        ballVel.dy = cos(tweakedAngle) * speed * signY
    }

    // MARK: - Scoring & Game Over Rules

    private func handleCPUMissed(events: inout [PingPongEvent]) {
        let basePts = mode == .endless ? 3 : 1
        let pts = isDoublePoints ? basePts * 2 : basePts
        playerScore += pts

        events.append(.playerScored(pointsAdded: pts, newScore: playerScore, position: ballPos))
        updateDifficultyProgression(events: &events)

        if mode == .classic && playerScore >= mode.targetScore {
            finishGame(playerWon: true, events: &events)
            return
        }

        prepareServe(towardPlayer: false, initialDelay: 0.75)
    }

    private func handlePlayerMissed(events: inout [PingPongEvent]) {
        cpuScore += 1
        events.append(.cpuScored(newCpuScore: cpuScore, position: ballPos))

        if mode == .endless {
            // In Endless Challenge, missing the ball (without Shield) ends the run!
            finishGame(playerWon: false, events: &events)
        } else {
            // Classic Arcade: first to 7 points wins
            if cpuScore >= mode.targetScore {
                finishGame(playerWon: false, events: &events)
            } else {
                prepareServe(towardPlayer: true, initialDelay: 0.85)
            }
        }
    }

    private func finishGame(playerWon: Bool, events: inout [PingPongEvent]) {
        isGameOver = true
        self.playerWon = playerWon
        ballVel = .zero

        let previousBest = ScoreManager.shared.highScore(for: .pingPong)
        let isNewBest = playerScore > previousBest && playerScore > 0
        ScoreManager.shared.updateHighScore(for: .pingPong, score: playerScore)

        if mode == .endless {
            PingPongGameCenterManager.shared.submitEndlessScore(playerScore)
        }

        events.append(.gameOver(finalScore: playerScore, playerWon: playerWon, isNewBest: isNewBest))
    }

    // MARK: - Difficulty Progression

    private func updateDifficultyProgression(events: inout [PingPongEvent]) {
        let newTier = PingPongDifficultyTier.forScore(playerScore, rallyCount: longestRally)
        if newTier.rawValue > difficultyTier.rawValue {
            difficultyTier = newTier
            if newTier.rawValue > highestDifficultyReached.rawValue {
                highestDifficultyReached = newTier
            }
            events.append(.difficultyIncreased(newTier))
        }
    }

    // MARK: - AI Opponent Logic

    private func scheduleAIReactionForIncomingShot() {
        let tierIndex = CGFloat(difficultyTier.rawValue - 1) // 0 to 5
        // Reaction delay shrinks as difficulty increases (0.18s down to 0.04s)
        let baseReaction = max(0.04, 0.18 - Double(tierIndex) * 0.026)
        aiReactionTimer = baseReaction + Double.random(in: 0.0...0.05)

        // Imperfect positioning error so player can outplay CPU with sharp angles & speed boosts
        let maxError = max(14.0, 38.0 - tierIndex * 4.2)
        // Occasional mistake chance (especially on fast or chaos shots)
        let mistakeChance = max(0.08, 0.24 - Double(tierIndex) * 0.025)
        if Double.random(in: 0...1) < mistakeChance {
            let sign: CGFloat = Bool.random() ? 1.0 : -1.0
            aiAimErrorOffset = sign * CGFloat.random(in: (maxError * 0.9)...(maxError * 1.45))
        } else {
            aiAimErrorOffset = CGFloat.random(in: -maxError...maxError)
        }
    }

    private func updateCPU(dt: Double) {
        let halfCPU = Self.cpuPaddleWidth * 0.5
        let minX = Self.wallInset + halfCPU
        let maxX = Self.courtWidth - Self.wallInset - halfCPU

        if ballVel.dy > 0 {
            // Ball is heading toward CPU
            if aiReactionTimer > 0 {
                aiReactionTimer -= dt
            } else {
                // Predict interception X with one wall reflection approximation
                let distY = max(1.0, Self.cpuY - ballPos.y)
                let timeToReach = distY / max(80.0, ballVel.dy)
                var predictedX = ballPos.x + ballVel.dx * timeToReach

                // Reflect inside court walls
                let playableMin = Self.wallInset + Self.ballRadius
                let playableMax = Self.courtWidth - Self.wallInset - Self.ballRadius
                let width = playableMax - playableMin
                if width > 0 {
                    var rel = predictedX - playableMin
                    let bounces = Int(floor(rel / width))
                    rel = rel - CGFloat(bounces) * width
                    if abs(bounces) % 2 == 1 {
                        predictedX = playableMax - rel
                    } else {
                        predictedX = playableMin + rel
                    }
                }

                aiTargetX = predictedX + aiAimErrorOffset
            }
        } else {
            // Drift back toward center-ish when ball moves toward player
            aiTargetX = Self.courtWidth * 0.5 + (ballPos.x - Self.courtWidth * 0.5) * 0.28
        }

        let clampedTarget = max(minX, min(maxX, aiTargetX))
        let tierIndex = CGFloat(difficultyTier.rawValue - 1)
        let maxCpuSpeed: CGFloat = 250.0 + tierIndex * 42.0 // Scales from 250 pt/s to 460 pt/s

        let diff = clampedTarget - cpuX
        let maxStep = maxCpuSpeed * CGFloat(dt)
        let step = max(-maxStep, min(maxStep, diff))
        cpuVX = dt > 0.0001 ? step / CGFloat(dt) : 0
        cpuX = max(minX, min(maxX, cpuX + step))
    }

    // MARK: - Power-Up System

    func isPowerUpActive(_ type: PingPongPowerUpType) -> Bool {
        activePowerUps.contains(where: { $0.type == type })
    }

    private func removePowerUp(_ type: PingPongPowerUpType) {
        activePowerUps.removeAll(where: { $0.type == type })
    }

    private func updatePowerUpSpawning(dt: Double, events: inout [PingPongEvent]) {
        // Age existing field power-ups
        for i in spawnedPowerUps.indices.reversed() {
            spawnedPowerUps[i].age += dt
            if spawnedPowerUps[i].age >= spawnedPowerUps[i].lifetime {
                spawnedPowerUps.remove(at: i)
            }
        }

        // Spawn new power-up at fair intervals (max 2 on table at once)
        guard spawnedPowerUps.count < 2 else { return }
        powerUpSpawnTimer -= dt
        guard powerUpSpawnTimer <= 0 else { return }

        powerUpSpawnTimer = Double.random(in: 5.5...8.5)

        // Pick a balanced power-up
        let availableTypes = PingPongPowerUpType.allCases.filter { candidate in
            // Avoid spawning exact same power-up already on table
            if spawnedPowerUps.contains(where: { $0.type == candidate }) { return false }
            // Avoid spawning Shield if already shielded
            if candidate == .shield && hasShieldActive { return false }
            return true
        }

        guard let chosenType = availableTypes.randomElement() else { return }

        // Spawn in middle playable zone so ball or player can interact with it
        let spawnX = CGFloat.random(in: (Self.wallInset + 42)...(Self.courtWidth - Self.wallInset - 42))
        let spawnY = CGFloat.random(in: 185...415)
        let item = SpawnedPowerUp(type: chosenType, position: CGPoint(x: spawnX, y: spawnY))
        spawnedPowerUps.append(item)
        events.append(.powerUpSpawned(item))
    }

    private func checkPowerUpCollection(at ballPoint: CGPoint, events: inout [PingPongEvent]) {
        guard !spawnedPowerUps.isEmpty else { return }

        for i in spawnedPowerUps.indices.reversed() {
            let item = spawnedPowerUps[i]
            let distBall = hypot(ballPoint.x - item.position.x, ballPoint.y - item.position.y)
            let hitRadius = item.radius + Self.ballRadius + 4.0

            if distBall <= hitRadius {
                let collected = spawnedPowerUps.remove(at: i)
                activatePowerUp(collected.type, at: collected.position, events: &events)
            }
        }
    }

    private func activatePowerUp(_ type: PingPongPowerUpType, at position: CGPoint, events: inout [PingPongEvent]) {
        // Balance rule: Do not activate multiple disruptive physics effects simultaneously
        if type.isPhysicsDisruptive {
            activePowerUps.removeAll(where: { $0.type.isPhysicsDisruptive && $0.type != type })
        }

        if let existingIndex = activePowerUps.firstIndex(where: { $0.type == type }) {
            activePowerUps[existingIndex].remaining = type.duration
        } else {
            activePowerUps.append(
                ActivePowerUpState(
                    type: type,
                    remaining: type.duration,
                    totalDuration: type.duration
                )
            )
        }

        events.append(.powerUpCollected(type, position: position))

        if type == .chaosBall {
            triggerCallout(LanguageManager.shared.tr("CHAOS MODE!", "MODE CHAOS !", "¡MODO CAOS!"), hex: type.uiColorHex, events: &events, force: true)
        } else {
            triggerCallout(type.name + "!", hex: type.uiColorHex, events: &events)
        }
    }

    // MARK: - Callouts

    private func triggerCallout(_ text: String, hex: UInt, events: inout [PingPongEvent], force: Bool = false) {
        guard force || calloutCooldown <= 0 else { return }
        calloutCooldown = 2.0
        events.append(.callout(text: text, colorHex: hex))
    }
}
