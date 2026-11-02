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

    private func cubeName(for id: Int) -> String {
        LanguageManager.shared.isFrench ? cubesFr[id] : cubes[id].name
    }

    private var cheers: [String] {
        LanguageManager.shared.isFrench
            ? ["Bravo !", "Top !", "Super !", "Génial !", "Parfait !"]
            : ["Nice!", "Boom!", "Smooth.", "Yes yes yes!", "Look at you go."]
    }

    private var oopsMessages: [String] {
        LanguageManager.shared.isFrench
            ? ["Oups.", "Pas facile !", "Presque !", "Aïe."]
            : ["Oof.", "Colours are hard, okay?", "I believed in you.", "That's a no from me."]
    }

    private var milestones: [Int: (rule: TapRuleType, text: String)] {
        [
            6: (.ink, LanguageManager.shared.tr("Follow the ink color!", "Suivez la couleur de l'encre !")),
            12: (.not, LanguageManager.shared.tr("Some colors are now banned!", "Des couleurs sont bannies !")),
            18: (.prev, LanguageManager.shared.tr("Memory test. Don't blink!", "Test mémoire. Attention !")),
            25: (.lie, LanguageManager.shared.tr("Watch out for psychs!", "Attention aux pièges !"))
        ]
    }

    init() {
        self.highScore = ScoreManager.shared.highScore(for: .tap)
        self.cubeOrder = cubes
    }

    func startGame() {
        lives = 3
        round = 0
        streak = 0
        isOver = false
        isLive = false
        lastTargetColorId = nil
        particles = []
        mascotMood = .happy
        speechText = LanguageManager.shared.tr("Let's go! Tap fast, think faster.", "C'est parti ! Touchez vite.")
        AudioManager.shared.play(.pop)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.nextRound()
        }
    }

    func nextRound() {
        guard !isOver else { return }
        round += 1
        instructionTag = ""

        if let milestone = milestones[round] {
            AudioManager.shared.play(.nextLevel)
            bannerText = milestone.text
            showBanner = true
            mascotMood = .wow

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                guard let self, !self.isOver else { return }
                self.showBanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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

        var rule = forcedRule ?? (round == 1 ? .tap : pool.randomElement()!)
        if rule == .speed { rule = pool.randomElement()! }
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
            instructionPrefix = LanguageManager.shared.tr("Tap", "Touchez")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { [weak self] c in c == targetId }
            lastTargetColorId = targetId

        case .not:
            instructionPrefix = LanguageManager.shared.tr("Anything but", "Sauf")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { [weak self] c in c != targetId }
            lastTargetColorId = targetId
            extraTime = 0.5

        case .ink:
            let inkId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            instructionPrefix = LanguageManager.shared.tr("Tap the ink:", "L'encre :")
            instructionWord = cubeName(for: targetId)
            instructionColor = cubes[inkId].color
            isCorrectAnswer = { [weak self] c in c == inkId }
            lastTargetColorId = inkId
            extraTime = 0.6

        case .prev:
            let prevId = lastTargetColorId ?? targetId
            instructionPrefix = LanguageManager.shared.tr("Tap last round's", "Dernière")
            instructionWord = LanguageManager.shared.tr("COLOR", "COULEUR")
            instructionColor = .white
            instructionTag = ""
            isCorrectAnswer = { [weak self] c in c == prevId }
            extraTime = 2.0

        case .lie:
            lieFakeId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            isCorrectAnswer = { [weak self] c in c == targetId }
            lastTargetColorId = targetId
            extraTime = 0.6

        case .speed:
            break
        }

        // Calculate time limit — gentler curve, difficulty rises slower, and higher levels retain comfortable time
        let baseTime = round == 1 ? 5.5 : max(2.0, 4.4 - Double(round) * 0.04)
        timeLimit = baseTime + extraTime
        timeElapsed = 0
        progress = 1.0

        if let fakeId = lieFakeId {
            // Psych-out mechanic!
            instructionPrefix = LanguageManager.shared.tr("Tap", "Touchez")
            instructionWord = cubeName(for: fakeId)
            instructionColor = cubes[fakeId].color
            isLive = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                guard let self, !self.isOver else { return }
                self.instructionWord = self.cubeName(for: targetId)
                self.instructionColor = self.cubes[targetId].color
                self.instructionTag = LanguageManager.shared.tr("Psych!", "Raté !")
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
                speechText = cheers.randomElement()!
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) { [weak self] in
                self?.nextRound()
            }
        } else {
            // Wrong! No confetti when picking the wrong color
            handleMistake(say: oopsMessages.randomElement()!)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                self?.finishGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                self?.nextRound()
            }
        }
    }

    func tick(dt: Double = 0.05) {
        // Update confetti particles with rotation & gravity matching Wheels style
        for i in particles.indices {
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
            particles[i].vy += 420 * CGFloat(dt) // gravity
            particles[i].rotation += particles[i].vr * 28 * dt
            particles[i].opacity -= dt * 1.5
        }
        particles.removeAll(where: { $0.opacity <= 0 })

        guard isLive, !isOver else { return }

        timeElapsed += dt
        progress = max(0, 1.0 - (timeElapsed / timeLimit))

        if progress <= 0 {
            isLive = false
            handleMistake(say: LanguageManager.shared.tr("Too slow! The colours got bored.", "Trop lent ! Les couleurs s'ennuient."))
        }
    }

    private func spawnConfetti(at point: CGPoint, color: Color) {
        let palette = [
            color,
            color,
            Color.white,
            Color(hex: 0xFFC83D), // Yellow
            Color(hex: 0x2EDB8A), // Green
            Color(hex: 0x3D7BFF), // Blue
            Color(hex: 0xFF4B5C)  // Red
        ]
        var newParticles: [TapPixelParticle] = []
        for _ in 0..<36 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 120...360)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed - CGFloat.random(in: 60...160)

            newParticles.append(TapPixelParticle(
                x: point.x,
                y: point.y,
                vx: vx,
                vy: vy,
                rotation: Double.random(in: 0...360),
                vr: Double.random(in: -10...10),
                size: CGFloat.random(in: 8...15),
                color: palette.randomElement() ?? color,
                opacity: 1.0
            ))
        }
        particles.append(contentsOf: newParticles)
    }

    private func finishGame() {
        let sc = max(0, round - 1)
        ScoreManager.shared.updateHighScore(for: .tap, score: sc)
        highScore = ScoreManager.shared.highScore(for: .tap)
        HapticsManager.shared.heavyImpact()
    }
}
