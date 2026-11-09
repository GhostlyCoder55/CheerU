import Foundation
import CoreGraphics

// MARK: - RUSH Engine
// Portrait-oriented 2D arcade spaceship engine with smooth 1-finger drag tracking,
// uniform slow-moving random meteors that progressively ramp up the longer the player survives,
// pure survival-duration scoring (2 seconds = 1 point), and Shield / Slow Speed power-up orbs.

final class RushEngine {

    // MARK: - Playfield Bounds (Portrait Logical Coordinates)
    private(set) var worldWidth: CGFloat = 393.0
    private(set) var worldHeight: CGFloat = 852.0

    private var minShipX: CGFloat { 26.0 }
    private var maxShipX: CGFloat { worldWidth - 26.0 }
    private var minShipY: CGFloat { 86.0 }
    private var maxShipY: CGFloat { worldHeight - 190.0 }

    // MARK: - Player Spaceship State
    let shipCollisionRadius: CGFloat = 11.0
    private(set) var shipX: CGFloat = 196.5
    private(set) var shipY: CGFloat = 190.0
    private(set) var shipVX: CGFloat = 0.0
    private(set) var shipTilt: CGFloat = 0.0

    // MARK: - Game State (Pure Survival Scoring: 3 seconds = 1 pt)
    static let secondsPerPoint: Double = 3.0

    private(set) var score: Int = 0
    private(set) var nearMissStreak: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var elapsedTime: Double = 0.0

    private(set) var asteroids: [RushMeteor] = []
    private(set) var collectibles: [RushCollectible] = []
    private(set) var activeEffects: [ActiveRushEffect] = []

    // Surprise Event State
    private(set) var pendingWarningEvent: RushSpecialEventKind? = nil
    private(set) var pendingSafeCorridorX: CGFloat? = nil
    private var warningTimer: Double = 0.0
    private(set) var activeSpecialEvent: RushSpecialEventKind? = nil
    private var specialEventTimer: Double = 0.0

    // Spawning & Timers
    private var meteorSpawnTimer: Double = 0.0
    private var powerUpSpawnTimer: Double = 6.5
    private var nextSurpriseEventTime: Double = 15.0
    private var invulnerabilityTimer: Double = 0.0

    var hasShield: Bool {
        activeEffects.contains(where: { $0.type == .shield })
    }

    var isSlowTimeActive: Bool {
        activeEffects.contains(where: { $0.type == .slowTime })
    }

    init() {
        reset()
    }

    func updateWorldSize(width: CGFloat, height: CGFloat) {
        guard width > 100, height > 200 else { return }
        worldWidth = width
        worldHeight = height
        shipX = min(max(shipX, minShipX), maxShipX)
        shipY = min(max(shipY, minShipY), maxShipY)
    }

    func reset() {
        score = 0
        nearMissStreak = 0
        isGameOver = false
        elapsedTime = 0.0

        shipX = worldWidth * 0.5
        shipY = min(max(worldHeight * 0.24, minShipY), maxShipY)
        shipVX = 0.0
        shipTilt = 0.0

        asteroids.removeAll()
        collectibles.removeAll()
        activeEffects.removeAll()

        pendingWarningEvent = nil
        pendingSafeCorridorX = nil
        warningTimer = 0.0
        activeSpecialEvent = nil
        specialEventTimer = 0.0

        meteorSpawnTimer = 0.45
        powerUpSpawnTimer = 6.5
        nextSurpriseEventTime = 15.0
        invulnerabilityTimer = 0.0
    }

    func setInvulnerable(for duration: Double) {
        invulnerabilityTimer = duration
    }

    // MARK: - Frame Update

    func update(dt rawDt: Double, targetShipPosition: CGPoint?) -> [RushEvent] {
        guard !isGameOver else { return [] }
        let dt = min(max(rawDt, 0.0), 1.0 / 20.0)
        var events: [RushEvent] = []

        elapsedTime += dt
        if invulnerabilityTimer > 0 {
            invulnerabilityTimer = max(0, invulnerabilityTimer - dt)
        }

        // 1. Survival Duration Scoring: strictly 3 seconds = 1 point
        let targetScore = Int((elapsedTime + 0.0001) / Self.secondsPerPoint)
        if targetScore > score {
            score = targetScore
            events.append(.scoreChanged(newScore: score))
        }

        // 2. Smooth 1-finger ship movement
        updateShipMovement(dt: dt, target: targetShipPosition)

        // 3. Active Power-Up Orb Timers
        for i in activeEffects.indices.reversed() {
            activeEffects[i].remaining -= dt
            if activeEffects[i].remaining <= 0 {
                activeEffects.remove(at: i)
            }
        }

        // 4. Surprise Event Warning & Execution
        updateSpecialEvents(dt: dt, events: &events)

        // 5. Progressive Meteor Spawning (Snappy pace that gets harder the longer you survive)
        let speedScale: CGFloat = isSlowTimeActive ? 0.50 : 1.0
        meteorSpawnTimer -= dt * Double(speedScale)
        if meteorSpawnTimer <= 0 {
            spawnRandomMeteor()
            let ramp = min(1.0, elapsedTime / 90.0)
            let lateBonus = min(0.12, max(0.0, elapsedTime - 90.0) * 0.0018)
            let baseInterval = 0.76 - ramp * 0.45 - lateBonus
            let eventFactor = (activeSpecialEvent == .meteorShower) ? 0.52 : 1.0
            meteorSpawnTimer = max(0.20, baseInterval * eventFactor * Double.random(in: 0.84...1.16))
        }

        // 6. Little Power-Up Orb Spawning (Shield or Slow Speed)
        powerUpSpawnTimer -= dt
        if powerUpSpawnTimer <= 0 {
            spawnPowerUpOrb()
            powerUpSpawnTimer = Double.random(in: 8.5...13.0)
        }

        // 7. Update Collectibles & Check Pickup
        updateCollectibles(dt: dt, events: &events)

        // 8. Update Meteors, Near-Miss Graze Feedback & Collisions
        updateMeteors(dt: dt, speedScale: speedScale, events: &events)

        return events
    }

    // MARK: - Ship Tracking

    private func updateShipMovement(dt: Double, target: CGPoint?) {
        let prevX = shipX
        if let target {
            let clampedX = min(max(target.x, minShipX), maxShipX)
            let clampedY = min(max(target.y, minShipY), maxShipY)
            let alpha = CGFloat(1.0 - pow(0.00008, dt))
            shipX += (clampedX - shipX) * alpha
            shipY += (clampedY - shipY) * alpha
        }
        shipX = min(max(shipX, minShipX), maxShipX)
        shipY = min(max(shipY, minShipY), maxShipY)

        if dt > 0.0001 {
            shipVX = (shipX - prevX) / CGFloat(dt)
            let targetTilt = max(-1.0, min(1.0, shipVX / 420.0))
            shipTilt += (targetTilt - shipTilt) * CGFloat(min(1.0, dt * 14.0))
        }
    }

    // MARK: - Special Events & Fair Telegraphs

    private func updateSpecialEvents(dt: Double, events: inout [RushEvent]) {
        if let pending = pendingWarningEvent {
            warningTimer -= dt
            if warningTimer <= 0 {
                pendingWarningEvent = nil
                triggerSpecialEvent(pending, events: &events)
            }
            return
        }

        if activeSpecialEvent != nil {
            specialEventTimer -= dt
            if specialEventTimer <= 0 {
                activeSpecialEvent = nil
                pendingSafeCorridorX = nil
            }
            return
        }

        if elapsedTime >= nextSurpriseEventTime {
            nextSurpriseEventTime = elapsedTime + Double.random(in: 16.0...22.0)
            let chosen = RushSpecialEventKind.allCases.randomElement() ?? .meteorShower
            pendingWarningEvent = chosen
            warningTimer = 1.25

            if chosen == .twinGate {
                pendingSafeCorridorX = CGFloat.random(in: (worldWidth * 0.24)...(worldWidth * 0.76))
            } else {
                pendingSafeCorridorX = nil
            }

            events.append(.specialEventWarning(chosen, safeCorridorX: pendingSafeCorridorX))
        }
    }

    private func triggerSpecialEvent(_ kind: RushSpecialEventKind, events: inout [RushEvent]) {
        events.append(.specialEventStarted(kind))
        switch kind {
        case .meteorShower:
            activeSpecialEvent = .meteorShower
            specialEventTimer = 4.2
        case .twinGate:
            activeSpecialEvent = .twinGate
            specialEventTimer = 2.2
            spawnTwinGateFormation(safeCenterX: pendingSafeCorridorX ?? (worldWidth * 0.5))
        }
    }

    // MARK: - Spawning Uniform Meteors & Little Orbs

    private func spawnRandomMeteor() {
        let ramp = min(1.0, elapsedTime / 90.0)
        let extraEndurance = min(55.0, max(0.0, elapsedTime - 90.0) * 0.65)
        let baseSpeed = CGFloat(175.0 + ramp * 150.0 + extraEndurance)

        let spawnX = CGFloat.random(in: 28.0...(worldWidth - 28.0))
        let spawnY = worldHeight + 42.0

        let vy = -baseSpeed * CGFloat.random(in: 0.88...1.14)
        let vx = CGFloat.random(in: -32.0...32.0)

        asteroids.append(
            RushMeteor(
                x: spawnX,
                y: spawnY,
                vx: vx,
                vy: vy,
                rotation: CGFloat.random(in: 0...(2 * .pi)),
                angularVelocity: CGFloat.random(in: -2.0...2.0)
            )
        )
    }

    private func spawnTwinGateFormation(safeCenterX: CGFloat) {
        let gapHalfWidth: CGFloat = 58.0
        let cols = 7
        let spacing = (worldWidth - 40.0) / CGFloat(max(1, cols - 1))
        let spawnY = worldHeight + 42.0
        let ramp = min(1.0, elapsedTime / 90.0)
        let vy = -CGFloat(195.0 + ramp * 105.0)

        for i in 0..<cols {
            let x = 20.0 + CGFloat(i) * spacing
            if abs(x - safeCenterX) < gapHalfWidth {
                continue
            }
            asteroids.append(
                RushMeteor(
                    x: x,
                    y: spawnY,
                    vx: 0,
                    vy: vy,
                    rotation: CGFloat(i) * 0.6,
                    angularVelocity: 1.5
                )
            )
        }
    }

    private func spawnPowerUpOrb() {
        guard collectibles.count < 2 else { return }
        let type: RushPowerUpType
        if !hasShield && Bool.random() {
            type = .shield
        } else {
            type = Bool.random() ? .slowTime : .shield
        }

        let x = CGFloat.random(in: 42.0...(worldWidth - 42.0))
        collectibles.append(
            RushCollectible(
                type: type,
                x: x,
                y: worldHeight + 26.0,
                vy: -145.0
            )
        )
    }

    // MARK: - Collectibles Update

    private func updateCollectibles(dt: Double, events: inout [RushEvent]) {
        let pickupRadius: CGFloat = shipCollisionRadius + 18.0
        for i in collectibles.indices.reversed() {
            collectibles[i].y += collectibles[i].vy * CGFloat(dt)
            collectibles[i].bobPhase += dt * 4.2
            collectibles[i].x += CGFloat(sin(collectibles[i].bobPhase)) * 16.0 * CGFloat(dt)

            let dx = collectibles[i].x - shipX
            let dy = collectibles[i].y - shipY
            let distSq = dx * dx + dy * dy

            if distSq <= pickupRadius * pickupRadius {
                let item = collectibles.remove(at: i)
                applyPowerUp(item, events: &events)
                continue
            }

            if collectibles[i].y < -40.0 {
                collectibles.remove(at: i)
            }
        }
    }

    private func applyPowerUp(_ item: RushCollectible, events: inout [RushEvent]) {
        if let idx = activeEffects.firstIndex(where: { $0.type == item.type }) {
            activeEffects[idx].remaining = item.type.duration
        } else {
            activeEffects.append(
                ActiveRushEffect(
                    type: item.type,
                    remaining: item.type.duration,
                    totalDuration: item.type.duration
                )
            )
        }

        events.append(.powerUpCollected(item.type, x: item.x, y: item.y))
    }

    // MARK: - Meteors, Near-Miss & Collision Detection

    private func updateMeteors(dt: Double, speedScale: CGFloat, events: inout [RushEvent]) {
        let hitThreshold = RushMeteor.collisionRadius + shipCollisionRadius - 2.0

        for i in asteroids.indices.reversed() {
            asteroids[i].x += asteroids[i].vx * CGFloat(dt) * speedScale
            asteroids[i].y += asteroids[i].vy * CGFloat(dt) * speedScale
            asteroids[i].rotation += asteroids[i].angularVelocity * CGFloat(dt) * speedScale

            if asteroids[i].x < 24.0 {
                asteroids[i].x = 24.0
                asteroids[i].vx = abs(asteroids[i].vx)
            } else if asteroids[i].x > worldWidth - 24.0 {
                asteroids[i].x = worldWidth - 24.0
                asteroids[i].vx = -abs(asteroids[i].vx)
            }

            let meteor = asteroids[i]
            let dist = hypot(meteor.x - shipX, meteor.y - shipY)

            // 1. Direct Collision Check
            if dist < hitThreshold {
                if invulnerabilityTimer > 0 {
                    asteroids.remove(at: i)
                    continue
                }
                if let shieldIdx = activeEffects.firstIndex(where: { $0.type == .shield }) {
                    activeEffects.remove(at: shieldIdx)
                    invulnerabilityTimer = 0.65
                    let hitX = meteor.x
                    let hitY = meteor.y
                    asteroids.remove(at: i)
                    events.append(.shieldAbsorbedHit(x: hitX, y: hitY))
                    continue
                } else {
                    let hitX = meteor.x
                    let hitY = meteor.y
                    asteroids.remove(at: i)
                    triggerGameOver(impactX: hitX, impactY: hitY, events: &events)
                    return
                }
            }

            // 2. Near-Miss Graze Visual & Haptic Feedback (score is strictly 3s = 1pt)
            if !meteor.hasGrantedNearMiss && dist < RushMeteor.grazeRadius && meteor.y <= shipY + 14.0 {
                asteroids[i].hasGrantedNearMiss = true
                nearMissStreak += 1
                events.append(.nearMiss(x: (meteor.x + shipX) * 0.5, y: (meteor.y + shipY) * 0.5, streak: nearMissStreak))
            }

            // 3. Despawn off-screen bottom
            if asteroids[i].y < -60.0 {
                asteroids.remove(at: i)
            }
        }
    }

    private func triggerGameOver(impactX: CGFloat, impactY: CGFloat, events: inout [RushEvent]) {
        isGameOver = true
        let previousBest = ScoreManager.shared.highScore(for: .rush)
        let isNewBest = score > previousBest && score > 0
        ScoreManager.shared.updateHighScore(for: .rush, score: score)
        RushGameCenterManager.shared.submitScore(score)
        events.append(.gameOver(finalScore: score, isNewBest: isNewBest, impactX: impactX, impactY: impactY))
    }
}
