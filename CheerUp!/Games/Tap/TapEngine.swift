import SwiftUI

// MARK: - TAP Engine
// Faithfully implements the rules, progressive difficulty, psych-outs,
// and speech interactions from the CheerUp!.html vision.

@Observable
final class TapEngine {
    var lives: Int = 3
    var round: Int = 0
    var streak: Int = 0
    var highScore: Int = 0
    var isOver: Bool = false
    var isLive: Bool = false
    var hasUsedRewardedContinue: Bool = false
    private var hasSubmittedScoreForCurrentEnding: Bool = false
    private var sessionGeneration: Int = 0

    // Mascot & Dialogue
    var mascotMood: MascotMood = .happy
    var speechText: String = "Hi! I'm Cheery. Don't let me down."

    // Instruction Card
    var instructionPrefix: String = "Ready?"
    var instructionWord: String = ""
    var instructionColor: Color = .white
    var instructionTag: String = ""
    var isPsychAnimation: Bool = false

    // Countdown Progress (1.0 -> 0.0)
    var progress: Double = 1.0
    private var timeLimit: Double = 3.6
    private var timeElapsed: Double = 0

    // Grid of Cubes
    var cubeOrder: [TapCube] = []
    var particles: [TapPixelParticle] = []
    var burstRings: [TapBurstRing] = []
    private var lastFrameDate: Date? = nil

    // Milestone Rule Banner
    var bannerText: String? = nil
    var showBanner: Bool = false

    // Target Verification Closure
    private var isCorrectAnswer: ((Int) -> Bool)? = nil
    private var lastTargetColorId: Int? = nil

    private let cubes = [
        TapCube(id: 0, name: "RED", color: CheerUpColors.Tap.red, hex: 0xFF4B5C),
        TapCube(id: 1, name: "BLUE", color: CheerUpColors.Tap.blue, hex: 0x3D7BFF),
        TapCube(id: 2, name: "GREEN", color: CheerUpColors.Tap.green, hex: 0x2EDB8A),
        TapCube(id: 3, name: "YELLOW", color: CheerUpColors.Tap.yellow, hex: 0xFFC83D)
    ]

    private let cubesFr = ["ROUGE", "BLEU", "VERT", "JAUNE"]
    private let cubesEs = ["ROJO", "AZUL", "VERDE", "AMARILLO"]

    private func cubeName(for id: Int) -> String {
        switch LanguageManager.shared.currentLanguage {
        case .french:  return cubesFr[id]
        case .spanish: return cubesEs[id]
        case .english: return cubes[id].name
        }
    }

    private var cheers: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Bravo !", "Top !", "Super !", "Génial !", "Parfait !"]
        case .spanish:
            return ["¡Genial!", "¡Bien!", "¡Perfecto!", "¡Súper!", "¡Excelente!"]
        case .english:
            return ["Nice!", "Boom!", "Smooth.", "Yes yes yes!", "Look at you go."]
        }
    }

    private var oopsMessages: [String] {
        switch LanguageManager.shared.currentLanguage {
        case .french:
            return ["Oups.", "Pas facile !", "Presque !", "Aïe."]
        case .spanish:
            return ["¡Ups!", "¡Difícil!", "¡Casi!", "¡Ánimo!"]
        case .english:
            return ["Oof.", "Colours are hard, okay?", "I believed in you.", "That's a no from me."]
        }
    }

    private var milestones: [Int: (rule: TapRuleType, text: String)] {
        [
            6: (.ink, LanguageManager.shared.tr("Follow the ink color!", "Suivez la couleur de l'encre !", "¡Sigue el color de la tinta!")),
            12: (.not, LanguageManager.shared.tr("Some colors are now banned!", "Des couleurs sont bannies !", "¡Colores prohibidos!")),
            18: (.prev, LanguageManager.shared.tr("Memory test. Don't blink!", "Test mémoire. Attention !", "¡Prueba de memoria!")),
            25: (.lie, LanguageManager.shared.tr("Watch out for psychs!", "Attention aux pièges !", "¡Cuidado con las trampas!"))
        ]
    }

    init() {
        self.highScore = ScoreManager.shared.highScore(for: .tap)
        self.cubeOrder = cubes
    }

    func startGame() {
        sessionGeneration += 1
        lives = 3
        round = 0
        streak = 0
        isOver = false
        isLive = false
        hasUsedRewardedContinue = false
        hasSubmittedScoreForCurrentEnding = false
        lastTargetColorId = nil
        particles = []
        burstRings = []
        lastFrameDate = nil
        mascotMood = .happy
        speechText = LanguageManager.shared.tr("Let's go! Tap fast, think faster.", "C'est parti ! Touchez vite.", "¡Vamos! Toca rápido.")
        AudioManager.shared.play(.pop)

        let gen = sessionGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            guard let self, self.sessionGeneration == gen else { return }
            self.nextRound()
        }
    }

    /// Grants one additional life/attempt (1 heart) after a rewarded video ad and resumes from the current round.
    func continueAfterReward() {
        guard !hasUsedRewardedContinue else { return }
        hasUsedRewardedContinue = true
        hasSubmittedScoreForCurrentEnding = false
        sessionGeneration += 1

        lives = 1
        isOver = false
        isLive = false
        progress = 1.0
        timeElapsed = 0
        showBanner = false
        mascotMood = .happy
        speechText = LanguageManager.shared.tr(
            "Second chance! Let's go!",
            "Seconde chance ! C'est parti !",
            "¡Segunda oportunidad! ¡Vamos!"
        )
        AudioManager.shared.play(.pop)

        let gen = sessionGeneration
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self, self.sessionGeneration == gen else { return }
            self.nextRound(advanceRound: false)
        }
    }

    func nextRound(advanceRound: Bool = true) {
        guard !isOver else { return }
        if advanceRound || round == 0 {
            round += 1
        }
        instructionTag = ""

        if let milestone = milestones[round] {
            AudioManager.shared.play(.nextLevel)
            bannerText = milestone.text
            showBanner = true
            mascotMood = .wow

            let gen = sessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self, self.sessionGeneration == gen, !self.isOver else { return }
                self.showBanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    guard self.sessionGeneration == gen, !self.isOver else { return }
                    self.setupRound(forcedRule: milestone.rule)
                }
            }
        } else {
            setupRound(forcedRule: nil)
        }
    }

    private func setupRound(forcedRule: TapRuleType?) {
        guard !isOver else { return }

        // Choose rule based on round progression
        // Removing "select color name" — choosing the ink color carries the color task!
        var pool: [TapRuleType] = []
        if round < 6 {
            pool = [.tap] // Warm-up: word and ink color match
        } else {
            // Primarily choosing the ink color
            pool = [.ink, .ink, .ink, .ink]
            if round >= 12 { pool.append(.not); pool.append(.not) }
            // Make "last round's color" rare (low probability slot in expanded pool)
            if round >= 18 && lastTargetColorId != nil { pool.append(.prev) }
            if round >= 25 { pool.append(.lie) }
        }

        var rule = forcedRule ?? (round == 1 ? .tap : (pool.randomElement() ?? .tap))
        if rule == .prev && lastTargetColorId == nil { rule = round < 6 ? .tap : .ink }

        // Shuffle grid order only on higher levels (round 20+)
        if round >= 20 {
            cubeOrder = cubes.shuffled()
        } else {
            cubeOrder = cubes
        }

        let targetId = Int.random(in: 0..<4)
        var extraTime: Double = 0
        var lieFakeId: Int? = nil

        switch rule {
        case .tap:
            instructionPrefix = LanguageManager.shared.tr("Tap", "Touchez", "Toca")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { c in c == targetId }
            lastTargetColorId = targetId

        case .not:
            instructionPrefix = LanguageManager.shared.tr("Anything but", "Sauf", "Menos")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { c in c != targetId }
            lastTargetColorId = targetId
            extraTime = 0.5

        case .ink:
            let inkId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            instructionPrefix = LanguageManager.shared.tr("Tap ink:", "Encre :", "Tinta:")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[inkId].color
            isCorrectAnswer = { c in c == inkId }
            lastTargetColorId = inkId
            extraTime = 0.6

        case .prev:
            let prevId = lastTargetColorId ?? targetId
            instructionPrefix = LanguageManager.shared.tr("Tap last round's", "Dernière", "Anterior")
            instructionWord = LanguageManager.shared.tr("COLOR", "COULEUR", "COLOR")
            instructionColor = .white
            instructionTag = ""
            isCorrectAnswer = { c in c == prevId }
            extraTime = 2.0

        case .lie:
            lieFakeId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            isCorrectAnswer = { c in c == targetId }
            lastTargetColorId = targetId
            extraTime = 0.6
        }

        // Calculate time limit — gentler curve, difficulty rises slower, and higher levels retain comfortable time
        let baseTime = round == 1 ? 5.5 : max(2.0, 4.4 - Double(round) * 0.04)
        timeLimit = baseTime + extraTime
        timeElapsed = 0
        progress = 1.0

        if let fakeId = lieFakeId {
            // Psych-out mechanic!
            instructionPrefix = LanguageManager.shared.tr("Tap", "Touchez", "Toca")
            instructionWord = cubeName(for: fakeId)
            instructionColor = cubes[fakeId].color
            isLive = false

            let gen = sessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                guard let self, self.sessionGeneration == gen, !self.isOver else { return }
                self.instructionWord = self.cubeName(for: targetId)
                self.instructionColor = self.cubes[targetId].color
                self.instructionTag = LanguageManager.shared.tr("Psych!", "Raté !", "¡Caíste!")
                self.isPsychAnimation = true
                AudioManager.shared.play(.switchToggle)

                self.isLive = true
            }
        } else {
            isLive = true
        }
    }

    func selectCube(_ cube: TapCube, tapPoint: CGPoint) {
        guard isLive, !isOver else { return }
        isLive = false

        if let isCorrect = isCorrectAnswer, isCorrect(cube.id) {
            // Correct! Spawn celebratory confetti in Wheels style
            spawnConfetti(at: tapPoint, color: cube.color)

            streak += 1
            if streak % 5 == 0 {
                AudioManager.shared.play(.combo)
            } else {
                AudioManager.shared.play(.pop)
            }
            HapticsManager.shared.lightTap()

            mascotMood = Double.random(in: 0...1) < 0.25 ? .wow : .happy
            if Double.random(in: 0...1) < 0.5 {
                speechText = cheers.randomElement() ?? "Nice!"
            }

            let gen = sessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { [weak self] in
                guard let self, self.sessionGeneration == gen else { return }
                self.nextRound()
            }
        } else {
            // Wrong! No confetti when picking the wrong color
            handleMistake(say: oopsMessages.randomElement() ?? "Oof.")
        }
    }

    private func handleMistake(say: String) {
        streak = 0
        lives = max(0, lives - 1)
        AudioManager.shared.play(.error)
        HapticsManager.shared.heavyImpact()
        mascotMood = .sad
        speechText = say

        if lives <= 0 {
            isOver = true
            let gen = sessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self, self.sessionGeneration == gen, self.isOver else { return }
                self.finishGame()
            }
        } else {
            let gen = sessionGeneration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                guard let self, self.sessionGeneration == gen else { return }
                self.nextRound()
            }
        }
    }

    func resetFrameTiming() {
        lastFrameDate = nil
    }

    func update(currentDate: Date) {
        let dt: Double
        if let last = lastFrameDate {
            dt = min(max(currentDate.timeIntervalSince(last), 0), 0.05)
        } else {
            dt = 1.0 / 60.0
        }
        lastFrameDate = currentDate
        tick(dt: dt)
    }

    func tick(dt: Double = 0.05) {
        // Update subtle tap shockwave rings
        if !burstRings.isEmpty {
            for i in burstRings.indices {
                burstRings[i].age += dt
                let t = min(1.0, burstRings[i].age / burstRings[i].duration)
                let eased = 1.0 - pow(1.0 - t, 3.0)
                burstRings[i].radius = 22 + (burstRings[i].maxRadius - 22) * CGFloat(eased)
                burstRings[i].opacity = 0.7 * (1.0 - eased)
            }
            burstRings.removeAll(where: { $0.age >= $0.duration })
        }

        // Update explosive confetti particles with air drag, gravity, lateral sway & 3D tumble
        if !particles.isEmpty {
            for i in particles.indices {
                particles[i].age += dt
                let damping = CGFloat(pow(particles[i].drag, dt))
                particles[i].vx *= damping
                particles[i].vy *= damping
                particles[i].vy += particles[i].gravity * CGFloat(dt)

                particles[i].swayPhase += particles[i].swaySpeed * dt
                let flutter = CGFloat(sin(particles[i].swayPhase)) * particles[i].swayAmplitude
                particles[i].x += (particles[i].vx + flutter) * CGFloat(dt)
                particles[i].y += particles[i].vy * CGFloat(dt)

                particles[i].rotation += particles[i].vr * dt
                particles[i].tilt += particles[i].tiltSpeed * dt

                let lifeProgress = particles[i].age / particles[i].lifetime
                if lifeProgress >= 0.58 {
                    let fadeProgress = min(1.0, (lifeProgress - 0.58) / 0.42)
                    particles[i].opacity = max(0, 1.0 - pow(fadeProgress, 1.5))
                }
            }
            particles.removeAll(where: { $0.age >= $0.lifetime || $0.opacity <= 0.01 })
        }

        guard isLive, !isOver else { return }

        timeElapsed += dt
        progress = max(0, 1.0 - (timeElapsed / timeLimit))

        if progress <= 0 {
            isLive = false
            handleMistake(say: LanguageManager.shared.tr("Too slow! The colours got bored.", "Trop lent ! Les couleurs s'ennuient.", "¡Muy lento! Los colores se aburrieron."))
        }
    }

    private func spawnConfetti(at point: CGPoint, color: Color) {
        burstRings.append(TapBurstRing(x: point.x, y: point.y, color: color))
        if burstRings.count > 6 {
            burstRings.removeFirst(burstRings.count - 6)
        }

        let palette: [Color] = [
            color,
            color,
            color,
            Color.white,
            Color(hex: 0xFFC83D), // Yellow
            Color(hex: 0x2EDB8A), // Green
            Color(hex: 0x3D7BFF), // Blue
            Color(hex: 0xFF4B5C), // Red
            Color(hex: 0xFF7AB6)  // Pink accent
        ]

        var newParticles: [TapPixelParticle] = []
        newParticles.reserveCapacity(56)

        // Layer 1: Explosive radial popper burst around the tapped cube
        for _ in 0..<36 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 300...760)
            let jitterX = CGFloat.random(in: -18...18)
            let jitterY = CGFloat.random(in: -18...18)
            let shape: TapConfettiShape = Bool.random() ? .ribbon : .square

            newParticles.append(TapPixelParticle(
                x: point.x + jitterX,
                y: point.y + jitterY,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - CGFloat.random(in: 140...300),
                rotation: Double.random(in: 0...360),
                vr: Double.random(in: -280...280),
                tilt: Double.random(in: 0...(2 * .pi)),
                tiltSpeed: Double.random(in: 7...15),
                swayPhase: Double.random(in: 0...(2 * .pi)),
                swaySpeed: Double.random(in: 6...10),
                swayAmplitude: CGFloat.random(in: 18...42),
                drag: Double.random(in: 0.04...0.10),
                gravity: CGFloat.random(in: 480...680),
                size: CGFloat.random(in: 9...15),
                aspect: shape == .ribbon ? CGFloat.random(in: 0.42...0.58) : 0.85,
                shape: shape,
                color: palette.randomElement() ?? color,
                lifetime: Double.random(in: 1.05...1.55)
            ))
        }

        // Layer 2: High upward canopy fountain ribbons
        for _ in 0..<14 {
            let spreadAngle = Double.random(in: (-0.82)...(0.82)) - (.pi / 2)
            let speed = CGFloat.random(in: 520...860)

            newParticles.append(TapPixelParticle(
                x: point.x + CGFloat.random(in: -14...14),
                y: point.y + CGFloat.random(in: -14...14),
                vx: cos(spreadAngle) * speed,
                vy: sin(spreadAngle) * speed,
                rotation: Double.random(in: 0...360),
                vr: Double.random(in: -320...320),
                tilt: Double.random(in: 0...(2 * .pi)),
                tiltSpeed: Double.random(in: 8...16),
                swayPhase: Double.random(in: 0...(2 * .pi)),
                swaySpeed: Double.random(in: 5...9),
                swayAmplitude: CGFloat.random(in: 24...50),
                drag: Double.random(in: 0.05...0.11),
                gravity: CGFloat.random(in: 420...580),
                size: CGFloat.random(in: 10...16),
                aspect: CGFloat.random(in: 0.4...0.55),
                shape: .ribbon,
                color: palette.randomElement() ?? color,
                lifetime: Double.random(in: 1.2...1.65)
            ))
        }

        // Layer 3: Crisp diamond sparkle glints
        for _ in 0..<8 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 240...540)

            newParticles.append(TapPixelParticle(
                x: point.x,
                y: point.y,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed - CGFloat.random(in: 80...180),
                rotation: Double.random(in: 0...360),
                vr: Double.random(in: -200...200),
                tilt: Double.random(in: 0...(2 * .pi)),
                tiltSpeed: Double.random(in: 10...18),
                swayPhase: 0,
                swaySpeed: 6,
                swayAmplitude: 10,
                drag: 0.07,
                gravity: 340,
                size: CGFloat.random(in: 6...10),
                aspect: 1.0,
                shape: .diamond,
                color: Bool.random() ? .white : Color(hex: 0xFFC83D),
                lifetime: Double.random(in: 0.55...0.85)
            ))
        }

        particles.append(contentsOf: newParticles)
        if particles.count > 180 {
            particles.removeFirst(particles.count - 180)
        }
    }

    private func finishGame() {
        guard !hasSubmittedScoreForCurrentEnding else { return }
        hasSubmittedScoreForCurrentEnding = true
        let sc = max(0, round - 1)
        ScoreManager.shared.updateHighScore(for: .tap, score: sc)
        highScore = ScoreManager.shared.highScore(for: .tap)
        GameCenterManager.shared.submitScore(sc, for: .tap)
        HapticsManager.shared.heavyImpact()
    }
}
