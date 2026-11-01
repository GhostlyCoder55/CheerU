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

    private let cheers = [
        "Nice!", "Boom!", "Smooth.", "Yes yes yes!", "Look at you go.",
        "Chef's kiss.", "Easy peasy.", "You're on fire!", "Wheee!", "Brain: activated."
    ]

    private let oopsMessages = [
        "Oof.", "Colours are hard, okay?", "I believed in you.",
        "That's a no from me.", "Plot twist: wrong.", "Almost! (Not really.)"
    ]

    private let milestones: [Int: (rule: TapRuleType, text: String)] = [
        5: (.not, "Plot twist: some colours are now banned."),
        7: (.ink, "Words can lie about their colour. Rude."),
        10: (.prev, "Memory test. Don't blink."),
        15: (.lie, "The instructions have started lying to you."),
        20: (.speed, "Everything speeds up. Good luck, legend.")
    ]

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
        speechText = "Let's go! Tap fast, think faster."
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
        var pool: [TapRuleType] = [.tap, .tap]
        if round >= 5 { pool.append(.not) }
        if round >= 7 { pool.append(.ink) }
        if round >= 10 && lastTargetColorId != nil { pool.append(.prev) }
        if round >= 15 { pool.append(.lie) }

        var rule = forcedRule ?? (round == 1 ? .tap : pool.randomElement()!)
        if rule == .speed { rule = pool.randomElement()! }
        if rule == .prev && lastTargetColorId == nil { rule = .tap }

        // Shuffle grid order if round >= 12
        if round >= 12 {
            cubeOrder = cubes.shuffled()
        } else {
            cubeOrder = cubes
        }

        let targetId = Int.random(in: 0..<4)
        var extraTime: Double = 0
        var lieFakeId: Int? = nil

        switch rule {
        case .tap:
            instructionPrefix = "Tap"
            instructionWord = cubes[targetId].name
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { [weak self] c in c == targetId }
            lastTargetColorId = targetId

        case .not:
            instructionPrefix = "Anything but"
            instructionWord = cubes[targetId].name
            instructionColor = cubes[targetId].color
            isCorrectAnswer = { [weak self] c in c != targetId }
            lastTargetColorId = targetId
            extraTime = 0.5

        case .ink:
            let inkId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            instructionPrefix = "Tap the ink:"
            instructionWord = cubes[targetId].name
            instructionColor = cubes[inkId].color
            isCorrectAnswer = { [weak self] c in c == inkId }
            lastTargetColorId = inkId
            extraTime = 0.7

        case .prev:
            let prevId = lastTargetColorId ?? targetId
            instructionPrefix = "Tap last round's"
            instructionWord = "COLOUR"
            instructionColor = .white
            instructionTag = "(No peeking. There's nothing to peek at.)"
            isCorrectAnswer = { [weak self] c in c == prevId }
            extraTime = 0.9

        case .lie:
            lieFakeId = (targetId + 1 + Int.random(in: 0..<3)) % 4
            isCorrectAnswer = { [weak self] c in c == targetId }
            lastTargetColorId = targetId
            extraTime = 0.6

        case .speed:
            break
        }

        // Calculate time limit
        var lim = round == 1 ? 5.0 : max(1.25, 3.6 - Double(round) * 0.07) + extraTime
        if round >= 20 {
            lim = max(0.85, lim * 0.75 - Double(round - 20) * 0.03)
        }
        timeLimit = lim
        timeElapsed = 0
        progress = 1.0

        if let fakeId = lieFakeId {
            // Psych-out mechanic!
            instructionPrefix = "Tap"
            instructionWord = cubes[fakeId].name
            instructionColor = cubes[fakeId].color
            isLive = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) { [weak self] in
                guard let self, !self.isOver else { return }
                self.instructionWord = self.cubes[targetId].name
                self.instructionColor = self.cubes[targetId].color
                self.instructionTag = "Psych! 😜"
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

        spawnPixelBurst(at: tapPoint, color: cube.color)

        if let isCorrect = isCorrectAnswer, isCorrect(cube.id) {
            // Correct!
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
            // Wrong!
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
        // Update pixel particles
        for i in particles.indices {
            particles[i].x += particles[i].vx * CGFloat(dt)
            particles[i].y += particles[i].vy * CGFloat(dt)
            particles[i].vy += 450 * CGFloat(dt) // gravity
            particles[i].opacity -= dt * 1.8
        }
        particles.removeAll(where: { $0.opacity <= 0 })

        guard isLive, !isOver else { return }

        timeElapsed += dt
        progress = max(0, 1.0 - (timeElapsed / timeLimit))

        if progress <= 0 {
            isLive = false
            handleMistake(say: "Too slow! The colours got bored.")
        }
    }

    private func spawnPixelBurst(at point: CGPoint, color: Color) {
        var newParticles: [TapPixelParticle] = []
        for _ in 0..<32 {
            let angle = Double.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 90...320)
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed - CGFloat.random(in: 40...100)

            newParticles.append(TapPixelParticle(
                x: point.x,
                y: point.y,
                vx: vx,
                vy: vy,
                size: CGFloat.random(in: 6...12),
                color: Bool.random() ? color : .white,
                opacity: 1.0
            ))
        }
        particles.append(contentsOf: newParticles)
    }

    private func finishGame() {
        let sc = max(0, round - 1)
        ScoreManager.shared.updateHighScore(for: .tap, score: sc)
        highScore = ScoreManager.shared.highScore(for: .tap)
        AudioManager.shared.play(.lose)
        HapticsManager.shared.heavyImpact()
    }
}
