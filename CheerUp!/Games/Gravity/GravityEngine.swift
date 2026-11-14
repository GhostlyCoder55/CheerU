import Foundation
import CoreGraphics

// MARK: - Gravity Engine
// Pure 2D torus-grid serpent engine with perspective-shifting boundary crossings,
// elemental motes (Fire, Water, Earth, Wind), buffered swipe inputs, and
// smooth interpolation progress for 60 FPS SpriteKit rendering.

final class GravityEngine {

    // MARK: - Grid Constants (Square Torus so 90°/180° rotations never distort!)
    static let gridColumns: Int = 17
    static let gridRows: Int    = 17

    // MARK: - Game State
    private(set) var score: Int = 0
    private(set) var motesCollectedCount: Int = 0
    private(set) var isGameOver: Bool = false
    private(set) var hasUsedRewardedContinue: Bool = false

    // Serpent body: index 0 is Head, last is Tail
    private(set) var segments: [GridCoord] = []
    private(set) var previousSegments: [GridCoord] = []
    private(set) var moveDirection: GravityDirection = .up
    private var queuedDirections: [GravityDirection] = []
    private var pendingGrowth: Int = 0

    // Gravity Orientation
    private(set) var orientation: GravityOrientation = .south
    private var shiftGraceTimer: Double = 0.0

    // Elemental Motes & Active Effects
    private(set) var spawnedMotes: [SpawnedMote] = []
    private(set) var activeEffects: [ActiveElementalEffect] = []

    // Step timing & interpolation (0.0 -> 1.0 between grid cells)
    private var stepAccumulator: Double = 0.0
    private(set) var stepProgress: CGFloat = 0.0

    var currentStepInterval: Double {
        // Constant, comfortable normal pace throughout the game (never speeds up with score)
        let base = 0.22
        if isEffectActive(.water) {
            return base * 1.38 // Water slows movement for calm precision
        } else if isEffectActive(.fire) {
            return base * 0.86 // Fire gives a gentle, manageable speed boost
        }
        return base
    }

    var isWindPhaseActive: Bool {
        isEffectActive(.wind)
    }

    var isFireBoostActive: Bool {
        isEffectActive(.fire)
    }

    var isWaterCalmActive: Bool {
        isEffectActive(.water)
    }

    init() {
        reset()
    }

    // MARK: - Reset

    func reset() {
        score = 0
        motesCollectedCount = 0
        isGameOver = false
        hasUsedRewardedContinue = false
        orientation = .south
        moveDirection = .up
        queuedDirections.removeAll()
        pendingGrowth = 0
        shiftGraceTimer = 0
        stepAccumulator = 0
        stepProgress = 0

        let cx = Self.gridColumns / 2
        let cy = Self.gridRows / 2
        segments = [
            GridCoord(x: cx, y: cy),
            GridCoord(x: cx, y: cy - 1),
            GridCoord(x: cx, y: cy - 2),
            GridCoord(x: cx, y: cy - 3)
        ]
        previousSegments = segments

        spawnedMotes.removeAll()
        activeEffects.removeAll()

        // Spawn 3 initial elemental motes so the world feels alive immediately
        spawnMote(preferredType: .earth)
        spawnMote(preferredType: .fire)
        spawnMote(preferredType: nil)
    }

    /// Continues the current run after a rewarded video ad, preserving full length, score, and entity positions,
    /// and granting an instant white orb (transparent phase body) ability.
    func continueAfterReward() {
        guard !hasUsedRewardedContinue else { return }
        hasUsedRewardedContinue = true
        isGameOver = false

        queuedDirections.removeAll()
        pendingGrowth = 0
        stepAccumulator = -0.35
        stepProgress = 0

        // Grant instant white orb (wind phase) ability for 7.5 seconds so the serpent is transparent
        // and phases through its own body safely to get its feet back in the game!
        activeEffects.removeAll { $0.type == .wind }
        activeEffects.append(ActiveElementalEffect(type: .wind, remaining: 7.5, totalDuration: 7.5))
        shiftGraceTimer = 3.5

        // Keep all existing segments, length, score, orientation, and spawned motes intact!
    }

    // MARK: - Player Swipe Input (Screen-Relative!)

    /// Accepts a swipe direction in screen coordinates and converts it using the current
    /// gravity orientation so swiping UP/DOWN/LEFT/RIGHT always steers in that screen direction.
    func queueScreenDirection(_ screenDir: GravityDirection) {
        guard !isGameOver else { return }
        let worldDir = orientation.screenToWorldDirection(screenDir)
        let referenceDir = queuedDirections.last ?? moveDirection

        // Prevent 180-degree self-reversal or redundant same-direction queue
        guard worldDir != referenceDir && worldDir != referenceDir.opposite else { return }
        if queuedDirections.count < 2 {
            queuedDirections.append(worldDir)
        }
    }

    // MARK: - Delta-Time Update

    func update(dt rawDt: Double) -> [GravityEvent] {
        guard !isGameOver else { return [] }
        let dt = min(max(rawDt, 0.0), 1.0 / 20.0)
        var events: [GravityEvent] = []

        if shiftGraceTimer > 0 {
            shiftGraceTimer = max(0, shiftGraceTimer - dt)
        }

        // Update active elemental effect timers
        for i in activeEffects.indices.reversed() {
            activeEffects[i].remaining -= dt
            if activeEffects[i].remaining <= 0 {
                activeEffects.remove(at: i)
            }
        }

        let interval = currentStepInterval
        stepAccumulator += dt

        while stepAccumulator >= interval && !isGameOver {
            stepAccumulator -= interval
            advanceOneGridStep(events: &events)
        }

        stepProgress = CGFloat(min(1.0, max(0.0, stepAccumulator / interval)))
        return events
    }

    // MARK: - Discrete Torus Step & Gravity Shift

    private func advanceOneGridStep(events: inout [GravityEvent]) {
        previousSegments = segments

        if !queuedDirections.isEmpty {
            let nextDir = queuedDirections.removeFirst()
            if nextDir != moveDirection.opposite {
                moveDirection = nextDir
            }
        }

        guard let head = segments.first else { return }
        let rawNextX = head.x + moveDirection.dx
        let rawNextY = head.y + moveDirection.dy

        // Check if crossing a torus boundary triggers a local gravity shift
        var crossedBoundary: GravityDirection? = nil
        var wrappedX = rawNextX
        var wrappedY = rawNextY

        if rawNextX >= Self.gridColumns {
            wrappedX = 0
            crossedBoundary = .right
        } else if rawNextX < 0 {
            wrappedX = Self.gridColumns - 1
            crossedBoundary = .left
        }

        if rawNextY >= Self.gridRows {
            wrappedY = 0
            crossedBoundary = .up
        } else if rawNextY < 0 {
            wrappedY = Self.gridRows - 1
            crossedBoundary = .down
        }

        let nextHead = GridCoord(x: wrappedX, y: wrappedY)

        // Check self-collision (tail moves out of the way unless growing)
        let bodyToCheck = pendingGrowth > 0 ? segments : Array(segments.dropLast())
        if bodyToCheck.contains(nextHead) {
            if isWindPhaseActive || shiftGraceTimer > 0 {
                // Wind mote (or post-shift grace) lets the serpent phase safely through its own body!
                events.append(.windPhasedThroughSelf(coord: nextHead))
            } else {
                triggerGameOver(events: &events)
                return
            }
        }

        // Move serpent head forward
        segments.insert(nextHead, at: 0)
        if pendingGrowth > 0 {
            pendingGrowth -= 1
        } else if segments.count > 1 {
            segments.removeLast()
        }

        events.append(.moved)

        // Check Elemental Mote collection
        if let moteIndex = spawnedMotes.firstIndex(where: { $0.coord == nextHead }) {
            let collected = spawnedMotes.remove(at: moteIndex)
            handleMoteCollected(collected, events: &events)
        }

        // Apply Gravity Shift when crossing a torus boundary
        if let boundary = crossedBoundary {
            applyBoundaryGravityShift(crossedEdge: boundary, events: &events)
        }
    }

    private func applyBoundaryGravityShift(crossedEdge: GravityDirection, events: inout [GravityEvent]) {
        // Make the first 2 points approachable: gentle 90° shifts on left/right, full 4-edge shifts as score rises
        let quarterTurns: Int
        switch crossedEdge {
        case .right:
            quarterTurns = 1  // Rotate 90° clockwise
        case .left:
            quarterTurns = -1 // Rotate 90° counter-clockwise
        case .up:
            quarterTurns = score >= 4 ? 2 : 1 // 180° flip once warmed up, 90° early on
        case .down:
            quarterTurns = -1 // Rotate 90° counter-clockwise
        }

        let newOrientation = orientation.shifted(byQuarterTurns: quarterTurns)
        guard newOrientation != orientation else { return }

        orientation = newOrientation
        // Clear stale queued turns & grant a brief 0.45s grace window so a shift never causes an unfair collision
        queuedDirections.removeAll()
        shiftGraceTimer = 0.45
        events.append(.gravityShifted(newOrientation: newOrientation, crossedEdge: crossedEdge))
    }

    // MARK: - Mote Collection & Spawning

    private func handleMoteCollected(_ mote: SpawnedMote, events: inout [GravityEvent]) {
        motesCollectedCount += 1

        let multiplier = isFireBoostActive ? 2 : 1
        let pointsAdded = mote.type.points * multiplier
        score += pointsAdded
        pendingGrowth += mote.type.growthSegments

        // Activate elemental effect if it has a duration
        if mote.type.effectDuration > 0 {
            // Fire and Water replace each other cleanly so speed is unambiguous
            if mote.type == .fire {
                activeEffects.removeAll(where: { $0.type == .water })
            } else if mote.type == .water {
                activeEffects.removeAll(where: { $0.type == .fire })
            }

            if let idx = activeEffects.firstIndex(where: { $0.type == mote.type }) {
                activeEffects[idx].remaining = mote.type.effectDuration
            } else {
                activeEffects.append(
                    ActiveElementalEffect(
                        type: mote.type,
                        remaining: mote.type.effectDuration,
                        totalDuration: mote.type.effectDuration
                    )
                )
            }
        }

        events.append(.moteCollected(mote.type, coord: mote.coord, pointsAdded: pointsAdded, newScore: score))

        // Ensure 3 motes remain scattered in the world
        while spawnedMotes.count < 3 {
            spawnMote(preferredType: nil)
        }
    }

    private func spawnMote(preferredType: ElementalMoteType?) {
        var occupied = Set(segments)
        for m in spawnedMotes {
            occupied.insert(m.coord)
        }

        var candidates: [GridCoord] = []
        for x in 0..<Self.gridColumns {
            for y in 0..<Self.gridRows {
                let c = GridCoord(x: x, y: y)
                if !occupied.contains(c) {
                    candidates.append(c)
                }
            }
        }

        guard let chosenCoord = candidates.randomElement() else { return }

        let chosenType: ElementalMoteType
        if let preferredType {
            chosenType = preferredType
        } else {
            // Balanced elemental distribution
            let roll = Double.random(in: 0...1)
            if roll < 0.34 {
                chosenType = .earth
            } else if roll < 0.60 {
                chosenType = .fire
            } else if roll < 0.82 {
                chosenType = .water
            } else {
                chosenType = .wind
            }
        }

        spawnedMotes.append(SpawnedMote(type: chosenType, coord: chosenCoord))
    }

    func isEffectActive(_ type: ElementalMoteType) -> Bool {
        activeEffects.contains(where: { $0.type == type })
    }

    // MARK: - Game Over

    private func triggerGameOver(events: inout [GravityEvent]) {
        isGameOver = true
        let previousBest = ScoreManager.shared.highScore(for: .gravity)
        let isNewBest = score > previousBest && score > 0
        ScoreManager.shared.updateHighScore(for: .gravity, score: score)
        GravityGameCenterManager.shared.submitScore(score)
        events.append(.gameOver(finalScore: score, isNewBest: isNewBest))
    }
}
