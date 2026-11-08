import SwiftUI

// MARK: - Wheels Engine
// State management, physics rotation, audio/haptic sync, and outcome selection.

@Observable
final class WheelsEngine {

    // Wheel Motion
    var rotation: Double = 0
    var pointerDeflection: Double = 0
    var isSpinning: Bool = false

    // Mascot & Dialogue
    var mascotMood: MascotMood = .happy
    var speechText: String = WheelsData.idleLines.randomElement() ?? "Spin me!"

    // Result & Interactive States
    var selectedOutcome: WheelOutcome?
    var showResultSheet: Bool = false
    var countdownRemaining: Int = 0
    var isTimerActive: Bool = false
    var isFlipped: Bool = false // For the "Upside Down" chaos effect!

    // Confetti Particles
    var particles: [WheelsConfettiParticle] = []

    // Internal timing
    private var spinDuration: Double = 4.2
    private var spinStartTime: Date?
    private var spinElapsedTime: Double = 0.0
    private var startAngle: Double = 0
    private var targetAngle: Double = 0
    private var lastTickSegment: Int = -1
    private var timerCountdownInterval: Double = 0
    private var lastFrameDate: Date?

    // MARK: - Spin Trigger
    func spin() {
        guard !isSpinning else { return }

        // Close existing sheet & reset flags
        showResultSheet = false
        isFlipped = false
        isTimerActive = false
        countdownRemaining = 0
        lastFrameDate = nil

        // Select outcome by probability weights
        let outcome = pickOutcome()
        selectedOutcome = outcome

        // 12 segments = 30 degrees per segment
        let targetSegmentIndex = Int.random(in: 0..<12)
        let segmentCenter = (Double(targetSegmentIndex) + 0.5) * 30.0
        let targetModulo = (270.0 - segmentCenter).truncatingRemainder(dividingBy: 360.0)
        let targetBase = targetModulo < 0 ? targetModulo + 360.0 : targetModulo

        // Organic jitter inside segment (±8°)
        let jitter = Double.random(in: -8.0...8.0)

        // 5 to 7 full revolutions + target offset
        let fullRotations = Double(Int.random(in: 5...7)) * 360.0
        let currentNorm = rotation.truncatingRemainder(dividingBy: 360.0)
        let currentPos = currentNorm < 0 ? currentNorm + 360.0 : currentNorm
        let angleDiff = (targetBase + jitter - currentPos).truncatingRemainder(dividingBy: 360.0)
        let normalizedDiff = angleDiff < 0 ? angleDiff + 360.0 : angleDiff

        startAngle = rotation
        targetAngle = startAngle + fullRotations + normalizedDiff

        isSpinning = true
        spinStartTime = Date()
        spinElapsedTime = 0.0
        spinDuration = 4.2
        lastTickSegment = -1

        // Mascot excitement
        mascotMood = .wow
        speechText = WheelsData.spinLines.randomElement() ?? "Wheeeee!"
        HapticsManager.shared.mediumImpact()
    }

    // MARK: - Frame Update (Synchronized with TimelineView)
    func update(currentDate: Date) {
        let now = currentDate
        let dt: Double
        if let last = lastFrameDate {
            dt = min(now.timeIntervalSince(last), 0.1)
        } else {
            dt = 1.0 / 60.0
        }
        lastFrameDate = now

        tick(dt: dt)
    }

    // MARK: - Frame Tick
    func tick(dt: Double) {
        // Update Wheel Spinning with Quartic Ease-Out
        if isSpinning {
            spinElapsedTime += dt
            let progress = min(spinElapsedTime / spinDuration, 1.0)

            // Quartic ease-out deceleration: 1 - (1 - p)^4
            let eased = 1.0 - pow(1.0 - progress, 4.0)
            let current = startAngle + (targetAngle - startAngle) * eased
            rotation = current

            // Ticking sound & pointer needle flicking across segments
            let positiveAngle = (270.0 - current).truncatingRemainder(dividingBy: 360.0)
            let normalized = positiveAngle < 0 ? positiveAngle + 360.0 : positiveAngle
            let currentSegment = Int(floor(normalized / 30.0)) % 12

            if currentSegment != lastTickSegment {
                lastTickSegment = currentSegment
                if progress < 0.985 {
                    AudioManager.shared.play(.tap)
                    HapticsManager.shared.lightTap()
                    pointerDeflection = -20.0
                    withAnimation(.spring(response: 0.08, dampingFraction: 0.55)) {
                        self.pointerDeflection = 0.0
                    }
                }
            }

            // Spin Finished
            if progress >= 1.0 {
                isSpinning = false
                finishSpin()
            }
        }

        // Update Confetti Particles
        if !particles.isEmpty {
            for i in particles.indices {
                particles[i].vy += 12.0 * CGFloat(dt)
                particles[i].x += particles[i].vx * CGFloat(dt)
                particles[i].y += particles[i].vy * CGFloat(dt)
                particles[i].rotation += particles[i].vr * dt
                particles[i].opacity = max(0, particles[i].opacity - 0.22 * dt)
            }
            particles.removeAll(where: { $0.y > 1000 || $0.opacity <= 0.05 })
        }

        // Update Challenge Timer
        if isTimerActive && countdownRemaining > 0 {
            timerCountdownInterval += dt
            if timerCountdownInterval >= 1.0 {
                timerCountdownInterval = 0
                countdownRemaining -= 1
                if countdownRemaining > 0 {
                    AudioManager.shared.play(.tap)
                    HapticsManager.shared.lightTap()
                } else {
                    isTimerActive = false
                    AudioManager.shared.play(.ding)
                    HapticsManager.shared.success()
                }
            }
        }
    }

    // MARK: - Spin Completion
    private func finishSpin() {
        guard let outcome = selectedOutcome else { return }

        // Set Mascot Reaction
        mascotMood = outcome.mood
        switch outcome.type {
        case .happy:
            speechText = WheelsData.happyLines.randomElement() ?? LanguageManager.shared.tr("Show what you got!", "À vous de jouer !", "¡Tu turno!")
            HapticsManager.shared.success()
            spawnConfetti(count: 70)
        case .chaos:
            speechText = WheelsData.chaosLines.randomElement() ?? LanguageManager.shared.tr("Told you so!", "Chaos total !", "¡Te lo advertí!")
            AudioManager.shared.play(.pop)
            HapticsManager.shared.heavyImpact()
            if outcome.titleEn == "Upside Down" {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    isFlipped = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                        self.isFlipped = false
                    }
                }
            }
            spawnConfetti(count: 35)
        }

        // Initialize Countdown Timer if required
        if let sec = outcome.timerSeconds {
            countdownRemaining = sec
            isTimerActive = true
            timerCountdownInterval = 0
        }

        // Reveal card overlay with animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                self.showResultSheet = true
            }
        }
    }

    // MARK: - Spin Again
    func spinAgain() {
        showResultSheet = false
        isTimerActive = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.spin()
        }
    }

    // MARK: - Confetti Generator
    private func spawnConfetti(count: Int) {
        let colors = WheelsData.segments.map { $0.color } + [Color.white, Color(hex: 0xFFD84A)]
        var newParticles: [WheelsConfettiParticle] = []

        for _ in 0..<count {
            let p = WheelsConfettiParticle(
                x: CGFloat.random(in: 40...350),
                y: CGFloat.random(in: 180...320),
                vx: CGFloat.random(in: -220...220),
                vy: CGFloat.random(in: -420 ... -120),
                rotation: Double.random(in: 0...360),
                vr: Double.random(in: -8...8),
                size: CGFloat.random(in: 7...14),
                color: colors.randomElement() ?? Color.orange,
                opacity: 1.0
            )
            newParticles.append(p)
        }

        particles.append(contentsOf: newParticles)
    }

    // MARK: - Weighted Random Selector
    private func pickOutcome() -> WheelOutcome {
        // Odds: 50% Happy, 50% Chaos / Dares / Challenges
        let roll = Int.random(in: 1...100)
        let category: WheelOutcomeType = roll <= 50 ? .happy : .chaos
        let candidates = WheelsData.outcomes.filter { $0.type == category }
        return candidates.randomElement() ?? WheelsData.outcomes[0]
    }
}
