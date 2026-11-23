import SpriteKit
import UIKit

// MARK: - Ping Pong Pixel Art Generator
// Generates crisp, nearest-neighbor 8-bit/16-bit pixel-art textures for paddles,
// ball, power-ups, and particle sparks without external asset bloat.

final class PingPongPixelArt {
    static let shared = PingPongPixelArt()

    private var cache: [String: SKTexture] = [:]
    private var imageCache: [String: UIImage] = [:]

    private init() {}

    func powerUpImage(for type: PingPongPowerUpType) -> UIImage {
        let key = "powerup_img_\(type.rawValue)"
        if let cached = imageCache[key] { return cached }
        let grid = powerUpGrid(for: type)
        let img = renderPixelGridImage(grid, pixelScale: 3, palette: powerUpPalette(for: type))
        imageCache[key] = img
        return img
    }

    func powerUpTexture(for type: PingPongPowerUpType) -> SKTexture {
        let key = "powerup_\(type.rawValue)"
        if let cached = cache[key] { return cached }

        let image = powerUpImage(for: type)
        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest
        cache[key] = tex
        return tex
    }

    private func powerUpPalette(for type: PingPongPowerUpType) -> [Character: SKColor] {
        let primary = skColor(hex: type.uiColorHex)
        let dark: SKColor
        let light: SKColor
        switch type {
        case .giantPaddle:
            dark = skColor(hex: 0x137A4B)
            light = skColor(hex: 0x8EF7C2)
        case .speedBoost:
            dark = skColor(hex: 0xA31628)
            light = skColor(hex: 0xFF9E80)
        case .slowMotion:
            dark = skColor(hex: 0x1B3FA8)
            light = skColor(hex: 0x99C2FF)
        case .stickyPaddle:
            dark = skColor(hex: 0xB87D0E)
            light = skColor(hex: 0xFFE680)
        case .doublePoints:
            dark = skColor(hex: 0xB8256E)
            light = skColor(hex: 0xFFD1E8)
        case .shield:
            dark = skColor(hex: 0x006B8F)
            light = skColor(hex: 0x8CEFFF)
        case .chaosBall:
            return [
                "1": skColor(hex: 0x5B21B6),
                "2": skColor(hex: 0x9333EA),
                "3": skColor(hex: 0xA855F7),
                "4": skColor(hex: 0xE9D5FF)
            ]
        case .doubleBall:
            return [
                "1": SKColor(red: 0.56, green: 0.67, blue: 0.78, alpha: 1.0),
                "2": SKColor(red: 0.72, green: 0.82, blue: 0.90, alpha: 1.0),
                "3": SKColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0),
                "4": SKColor.white
            ]
        }
        return [
            "1": dark,
            "2": primary,
            "3": light,
            "4": SKColor.white
        ]
    }

    private func powerUpGrid(for type: PingPongPowerUpType) -> [String] {
        switch type {
        case .giantPaddle:
            // Crisp 16x16 wide paddle with outward left/right arrows
            return [
                "................",
                "....3......3....",
                "...34......43...",
                "..342......243..",
                ".34221111112243.",
                "3422233443322243",
                "3444444444444443",
                "1222233443322221",
                ".12221111112221.",
                "..122......221..",
                "...12......21...",
                "....1......1....",
                "................",
                "................",
                "................",
                "................"
            ]
        case .speedBoost:
            // Crisp 16x16 multi-tone lightning bolt
            return [
                ".......333333...",
                "......3444422...",
                ".....3444322....",
                "....3443221.....",
                "...3443221......",
                "..34444444433...",
                ".344444444432...",
                ".111113443221...",
                ".....3443221....",
                "....344321......",
                "...343221.......",
                "..34221.........",
                ".3421...........",
                ".31.............",
                "................",
                "................"
            ]
        case .slowMotion:
            // Crisp 16x16 hourglass with falling sand grains
            return [
                "..333333333333..",
                "..122222222221..",
                "...1344444431...",
                "...1324444231...",
                "....13244231....",
                ".....134431.....",
                "......1331......",
                "......1341......",
                ".....13..31.....",
                "....13..4.31....",
                "...13..44..31...",
                "...1324444231...",
                "...1344444431...",
                "..122222222221..",
                "..333333333333..",
                "................"
            ]
        case .stickyPaddle:
            // Crisp 16x16 horseshoe magnet with white pole tips & sparks
            return [
                "....4......4....",
                "..4444....4444..",
                "..4444....4444..",
                "..3333....3333..",
                "..2221....1222..",
                "..2321....1232..",
                "..2321....1232..",
                "..2321....1232..",
                "..23211..11232..",
                "..232222222232..",
                "...2332222332...",
                "....12222221....",
                ".....111111.....",
                "................",
                "................",
                "................"
            ]
        case .doublePoints:
            // Crisp 16x16 "x2" multiplier icon with pixel highlights & shadow
            return [
                "................",
                "................",
                ".........34443..",
                "........3444443.",
                "........342.243.",
                "43...34.11..342.",
                "243.342....3421.",
                ".24342....3421..",
                "..242....3421...",
                ".34243..3421....",
                "342.243.3444443.",
                "21...12.2222222.",
                ".1...1..1111111.",
                "................",
                "................",
                "................"
            ]
        case .shield:
            // Proper 16x16 heraldic heater shield with curved top, metallic rim & central crest
            return [
                "......3443......",
                "..333324423333..",
                ".34442233224443.",
                ".34111244211143.",
                ".32122244222123.",
                ".32124444442123.",
                ".32124444442123.",
                ".32122244222123.",
                "..321124421123..",
                "..132124421231..",
                "...1322442231...",
                "....13244231....",
                ".....134431.....",
                "......1331......",
                ".......11.......",
                "................"
            ]
        case .chaosBall:
            // Crisp 16x16 purple question mark (?) with pixel highlights & shadow
            return [
                "................",
                ".....344443.....",
                "...3344333433...",
                "...3432112343...",
                "...3321..1233...",
                "...111...3432...",
                "........34321...",
                ".......34321....",
                "......34321.....",
                "......3322......",
                "......1221......",
                "................",
                "......3443......",
                "......3322......",
                "......1221......",
                "................"
            ]
        case .doubleBall:
            // Clean white-themed icon clearly showing two identical default balls
            return [
                "................",
                "...333..........",
                "..34433.........",
                ".3443333........",
                ".3333333........",
                ".3333322........",
                "..33322.........",
                "...322..........",
                "..........333...",
                ".........34433..",
                "........3443333.",
                "........3333333.",
                "........3333322.",
                ".........33322..",
                "..........322...",
                "................"
            ]
        }
    }

    func ballTexture() -> SKTexture {
        let key = "pixel_ball"
        if let cached = cache[key] { return cached }
        let grid = [
            "..1111..",
            ".122111.",
            "12211111",
            "11111111",
            "11111111",
            "11111133",
            ".111133.",
            "..1133.."
        ]
        let tex = renderPixelGrid(grid, pixelScale: 3, palette: [
            "1": SKColor(red: 0.96, green: 0.98, blue: 1.0, alpha: 1.0),
            "2": SKColor.white,
            "3": SKColor(red: 0.72, green: 0.82, blue: 0.90, alpha: 1.0)
        ])
        cache[key] = tex
        return tex
    }

    private func renderPixelGridImage(_ grid: [String], pixelScale: Int, palette: [Character: SKColor]) -> UIImage {
        let rows = grid.count
        let cols = grid.first?.count ?? 1
        let width = cols * pixelScale
        let height = rows * pixelScale

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        return renderer.image { ctx in
            let cgContext = ctx.cgContext
            cgContext.interpolationQuality = .none

            for (rIdx, row) in grid.enumerated() {
                for (cIdx, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    cgContext.setFillColor(color.cgColor)
                    let rect = CGRect(
                        x: cIdx * pixelScale,
                        y: rIdx * pixelScale,
                        width: pixelScale,
                        height: pixelScale
                    )
                    cgContext.fill(rect)
                }
            }
        }
    }

    private func renderPixelGrid(_ grid: [String], pixelScale: Int, palette: [Character: SKColor]) -> SKTexture {
        let image = renderPixelGridImage(grid, pixelScale: pixelScale, palette: palette)
        let texture = SKTexture(image: image)
        texture.filteringMode = .nearest
        return texture
    }

    func skColor(hex: UInt, alpha: CGFloat = 1.0) -> SKColor {
        SKColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}

// MARK: - Scene Delegate

protocol PingPongSceneDelegate: AnyObject {
    func sceneDidUpdateState(
        playerScore: Int,
        cpuScore: Int,
        rally: Int,
        activePowerUps: [ActivePowerUpState]
    )
    func sceneDidSpawnPowerUp(_ type: PingPongPowerUpType)
    func sceneDidCollectPowerUp(_ type: PingPongPowerUpType)
    func sceneDidTriggerCallout(text: String, colorHex: UInt)
    func sceneDidFinishGame(finalScore: Int, playerWon: Bool, isNewBest: Bool)
}

// MARK: - Ping Pong SpriteKit Scene

final class PingPongScene: SKScene {

    weak var gameDelegate: PingPongSceneDelegate?

    private let engine = PingPongEngine()

    // World container scaled to fit any portrait iPhone screen cleanly
    private let worldNode = SKNode()
    private let tableLayer = SKNode()
    private let powerUpLayer = SKNode()
    private let actorLayer = SKNode()
    private let fxLayer = SKNode()

    // Visual nodes
    private let playerPaddle = SKNode()
    private let playerPaddleBody = SKShapeNode()
    private let playerPaddleHighlight = SKShapeNode()
    private let stickyIndicator = SKShapeNode()

    private let cpuPaddle = SKNode()
    private let cpuPaddleBody = SKShapeNode()
    private let cpuEyeLeft = SKSpriteNode(color: .black, size: CGSize(width: 4, height: 6))
    private let cpuEyeRight = SKSpriteNode(color: .black, size: CGSize(width: 4, height: 6))

    private let ballNode = SKSpriteNode(texture: PingPongPixelArt.shared.ballTexture())
    private var trailNodes: [SKSpriteNode] = []
    private var trailHistory: [CGPoint] = []

    private let extraBallNode = SKSpriteNode(texture: PingPongPixelArt.shared.ballTexture())
    private var extraTrailNodes: [SKSpriteNode] = []
    private var extraTrailHistory: [CGPoint] = []

    private let shieldBarrierNode = SKShapeNode()
    private var powerUpNodes: [UUID: SKNode] = [:]
    private var activePowerUpIDs = Set<UUID>()

    // Input & timing
    private var activeTouch: UITouch?
    private var targetPlayerX: CGFloat?
    private var lastUpdateTime: TimeInterval?
    private var worldOrigin: CGPoint = .zero
    private var currentRenderedPaddleWidth: CGFloat = 0
    private var lastReportedPlayerScore: Int = -1
    private var lastReportedCpuScore: Int = -1
    private var lastReportedRally: Int = -1
    private var lastReportedPowerUpSeconds: [String: Int] = [:]

    var isGamePaused: Bool = false {
        didSet {
            isPaused = isGamePaused
            if !isGamePaused {
                lastUpdateTime = nil
            }
        }
    }

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        backgroundColor = PingPongPixelArt.shared.skColor(hex: 0x06141B)
        setupSceneGraph()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        view.isMultipleTouchEnabled = false
        layoutCourtForScreenSize()
        preloadTextures()
    }

    private func preloadTextures() {
        var textures: [SKTexture] = [PingPongPixelArt.shared.ballTexture()]
        for type in PingPongPowerUpType.allCases {
            textures.append(PingPongPixelArt.shared.powerUpTexture(for: type))
        }
        SKTexture.preload(textures) {}
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutCourtForScreenSize()
    }

    // MARK: - Scene Setup

    private func setupSceneGraph() {
        addChild(worldNode)

        tableLayer.zPosition = 0
        powerUpLayer.zPosition = 10
        actorLayer.zPosition = 20
        fxLayer.zPosition = 30

        worldNode.addChild(tableLayer)
        worldNode.addChild(powerUpLayer)
        worldNode.addChild(actorLayer)
        worldNode.addChild(fxLayer)

        buildArcadeTable()
        buildPaddlesAndBall()
        syncVisualsWithEngine()
    }

    private func buildArcadeTable() {
        let cw = PingPongEngine.courtWidth
        let ch = PingPongEngine.courtHeight
        let inset = PingPongEngine.wallInset

        // Outer table shadow
        let shadowRect = CGRect(x: inset - 4, y: 24, width: cw - (inset - 4) * 2, height: ch - 48)
        let shadowNode = SKShapeNode(rect: shadowRect, cornerRadius: 18)
        shadowNode.fillColor = SKColor(white: 0.0, alpha: 0.45)
        shadowNode.strokeColor = .clear
        shadowNode.position = CGPoint(x: 0, y: -6)
        tableLayer.addChild(shadowNode)

        // Main table surface (#11212D dark navy slate)
        let tableRect = CGRect(x: inset, y: 24, width: cw - inset * 2, height: ch - 48)
        let surfaceNode = SKShapeNode(rect: tableRect, cornerRadius: 16)
        surfaceNode.fillColor = PingPongPixelArt.shared.skColor(hex: 0x11212D)
        surfaceNode.strokeColor = PingPongPixelArt.shared.skColor(hex: 0x253745)
        surfaceNode.lineWidth = 4.0
        tableLayer.addChild(surfaceNode)

        // Inner court subtle pixel grid lines
        let centerLinePath = CGMutablePath()
        centerLinePath.move(to: CGPoint(x: cw * 0.5, y: 36))
        centerLinePath.addLine(to: CGPoint(x: cw * 0.5, y: ch - 36))
        let centerLine = SKShapeNode(path: centerLinePath)
        centerLine.strokeColor = PingPongPixelArt.shared.skColor(hex: 0x253745, alpha: 0.55)
        centerLine.lineWidth = 2.0
        tableLayer.addChild(centerLine)

        // Left & right neon arcade bumper rails
        for xPos in [inset, cw - inset] {
            let railPath = CGMutablePath()
            railPath.move(to: CGPoint(x: xPos, y: 44))
            railPath.addLine(to: CGPoint(x: xPos, y: ch - 44))
            let rail = SKShapeNode(path: railPath)
            rail.strokeColor = PingPongPixelArt.shared.skColor(hex: 0x4A5C6A, alpha: 0.85)
            rail.lineWidth = 3.5
            tableLayer.addChild(rail)
        }

        // Pixel-art Horizontal Dashed Net at center Y
        let netY = PingPongEngine.netY
        let dashWidth: CGFloat = 10.0
        let gapWidth: CGFloat = 6.0
        var curX = inset + 8.0
        while curX < cw - inset - 8.0 {
            let post = SKSpriteNode(
                color: PingPongPixelArt.shared.skColor(hex: 0x9BA8AB, alpha: 0.7),
                size: CGSize(width: dashWidth, height: 4)
            )
            post.position = CGPoint(x: curX + dashWidth * 0.5, y: netY)
            tableLayer.addChild(post)
            curX += dashWidth + gapWidth
        }

        // Net left/right posts
        for postX in [inset - 2, cw - inset + 2] {
            let post = SKSpriteNode(
                color: PingPongPixelArt.shared.skColor(hex: 0xCCD0CF),
                size: CGSize(width: 8, height: 14)
            )
            post.position = CGPoint(x: postX, y: netY)
            tableLayer.addChild(post)
        }

        // Shield Bottom Energy Barrier (hidden unless Shield power-up is active)
        let shieldPath = CGMutablePath()
        shieldPath.move(to: CGPoint(x: inset + 6, y: 34))
        shieldPath.addLine(to: CGPoint(x: cw - inset - 6, y: 34))
        shieldBarrierNode.path = shieldPath
        shieldBarrierNode.strokeColor = PingPongPixelArt.shared.skColor(hex: 0x00D2FF, alpha: 0.9)
        shieldBarrierNode.lineWidth = 4.0
        shieldBarrierNode.glowWidth = 4.0
        shieldBarrierNode.isHidden = true
        tableLayer.addChild(shieldBarrierNode)
    }

    private func buildPaddlesAndBall() {
        // Player Paddle (CheerUp signature teal #00A896)
        updatePlayerPaddleGeometry(width: PingPongEngine.basePaddleWidth)
        playerPaddle.addChild(playerPaddleBody)
        playerPaddle.addChild(playerPaddleHighlight)
        playerPaddle.addChild(stickyIndicator)
        actorLayer.addChild(playerPaddle)

        // CPU Opponent Paddle (Expressive Crimson #FF4B5C with little pixel eyes)
        let cpuW = PingPongEngine.cpuPaddleWidth
        let cpuH = PingPongEngine.paddleHeight
        let cpuRect = CGRect(x: -cpuW * 0.5, y: -cpuH * 0.5, width: cpuW, height: cpuH)
        cpuPaddleBody.path = CGPath(roundedRect: cpuRect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        cpuPaddleBody.fillColor = PingPongPixelArt.shared.skColor(hex: 0xFF4B5C)
        cpuPaddleBody.strokeColor = SKColor(white: 1.0, alpha: 0.35)
        cpuPaddleBody.lineWidth = 1.5
        cpuPaddle.addChild(cpuPaddleBody)

        cpuEyeLeft.position = CGPoint(x: -8, y: -1)
        cpuEyeRight.position = CGPoint(x: 8, y: -1)
        cpuPaddle.addChild(cpuEyeLeft)
        cpuPaddle.addChild(cpuEyeRight)
        actorLayer.addChild(cpuPaddle)

        // Motion Trail Nodes (6 pixel afterimages)
        for i in 0..<6 {
            let t = SKSpriteNode(texture: PingPongPixelArt.shared.ballTexture())
            t.size = CGSize(width: PingPongEngine.ballRadius * 2.0, height: PingPongEngine.ballRadius * 2.0)
            t.alpha = max(0.06, 0.36 - CGFloat(i) * 0.055)
            t.setScale(1.0 - CGFloat(i) * 0.11)
            t.zPosition = -1
            t.isHidden = true
            actorLayer.addChild(t)
            trailNodes.append(t)
        }

        // Main Pixel Ball
        ballNode.size = CGSize(width: PingPongEngine.ballRadius * 2.1, height: PingPongEngine.ballRadius * 2.1)
        actorLayer.addChild(ballNode)

        // Extra Ball Motion Trail & Node (for Double Ball Power-Up)
        for i in 0..<6 {
            let t = SKSpriteNode(texture: PingPongPixelArt.shared.ballTexture())
            t.size = CGSize(width: PingPongEngine.ballRadius * 2.0, height: PingPongEngine.ballRadius * 2.0)
            t.alpha = max(0.06, 0.36 - CGFloat(i) * 0.055)
            t.setScale(1.0 - CGFloat(i) * 0.11)
            t.zPosition = -1
            t.isHidden = true
            actorLayer.addChild(t)
            extraTrailNodes.append(t)
        }

        extraBallNode.size = CGSize(width: PingPongEngine.ballRadius * 2.1, height: PingPongEngine.ballRadius * 2.1)
        extraBallNode.isHidden = true
        actorLayer.addChild(extraBallNode)
    }

    private func updatePlayerPaddleGeometry(width: CGFloat) {
        guard abs(width - currentRenderedPaddleWidth) > 0.5 else { return }
        currentRenderedPaddleWidth = width

        let h = PingPongEngine.paddleHeight
        let rect = CGRect(x: -width * 0.5, y: -h * 0.5, width: width, height: h)
        playerPaddleBody.path = CGPath(roundedRect: rect, cornerWidth: 6, cornerHeight: 6, transform: nil)
        playerPaddleBody.fillColor = width > PingPongEngine.basePaddleWidth
            ? PingPongPixelArt.shared.skColor(hex: 0x2EDB8A)
            : PingPongPixelArt.shared.skColor(hex: 0x00A896)
        playerPaddleBody.strokeColor = SKColor(white: 1.0, alpha: 0.45)
        playerPaddleBody.lineWidth = 1.5

        let hiRect = CGRect(x: -width * 0.42, y: h * 0.1, width: width * 0.84, height: 3)
        playerPaddleHighlight.path = CGPath(roundedRect: hiRect, cornerWidth: 1.5, cornerHeight: 1.5, transform: nil)
        playerPaddleHighlight.fillColor = SKColor(white: 1.0, alpha: 0.35)
        playerPaddleHighlight.strokeColor = .clear

        let stickyRect = CGRect(x: -width * 0.46, y: h * 0.5 - 2, width: width * 0.92, height: 4)
        stickyIndicator.path = CGPath(roundedRect: stickyRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
        stickyIndicator.fillColor = PingPongPixelArt.shared.skColor(hex: 0xFFC83D)
        stickyIndicator.strokeColor = .clear
    }

    private func layoutCourtForScreenSize() {
        guard size.width > 0, size.height > 0 else { return }

        // Reserve space at top for header + MiniCheerUp! stage (~136pt) and bottom for power-up bar (~56pt)
        let topReserved: CGFloat = 136.0
        let bottomReserved: CGFloat = 56.0
        let availableHeight = max(300.0, size.height - topReserved - bottomReserved)
        let availableWidth = max(260.0, size.width - 12.0)

        let scaleX = availableWidth / PingPongEngine.courtWidth
        let scaleY = availableHeight / PingPongEngine.courtHeight
        let scale = min(scaleX, scaleY)

        worldNode.setScale(scale)

        let scaledW = PingPongEngine.courtWidth * scale
        let scaledH = PingPongEngine.courtHeight * scale
        let originX = (size.width - scaledW) * 0.5
        let originY = bottomReserved + (availableHeight - scaledH) * 0.5

        worldOrigin = CGPoint(x: originX, y: originY)
        if worldNode.action(forKey: "shake") == nil {
            worldNode.position = worldOrigin
        }
    }

    // MARK: - Game Control

    func startNewGame(mode: PingPongMode) {
        engine.reset(mode: mode)
        fxLayer.removeAllChildren()
        powerUpLayer.removeAllChildren()
        powerUpNodes.removeAll()
        trailHistory.removeAll()
        trailNodes.forEach { $0.isHidden = true }
        extraTrailHistory.removeAll()
        extraTrailNodes.forEach { $0.isHidden = true }
        extraBallNode.isHidden = true
        targetPlayerX = nil
        activeTouch = nil
        lastUpdateTime = nil
        isGamePaused = false
        lastReportedPlayerScore = -1
        lastReportedCpuScore = -1
        lastReportedRally = -1
        lastReportedPowerUpSeconds.removeAll()
        syncVisualsWithEngine()
        notifyStateChange(force: true)
    }

    func continueAfterReward() {
        engine.continueAfterReward()
        fxLayer.removeAllChildren()
        trailHistory.removeAll()
        trailNodes.forEach { $0.isHidden = true }
        extraTrailHistory.removeAll()
        extraTrailNodes.forEach { $0.isHidden = true }
        extraBallNode.isHidden = true
        targetPlayerX = nil
        activeTouch = nil
        lastUpdateTime = nil
        isGamePaused = false
        lastReportedPlayerScore = -1
        lastReportedCpuScore = -1
        lastReportedRally = -1
        lastReportedPowerUpSeconds.removeAll()
        syncVisualsWithEngine()
        notifyStateChange(force: true)
    }

    // MARK: - Frame Update Loop (60 FPS Delta-Time)

    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused else {
            lastUpdateTime = nil
            return
        }

        let dt: Double
        if let last = lastUpdateTime {
            dt = currentTime - last
        } else {
            dt = 1.0 / 60.0
        }
        lastUpdateTime = currentTime

        let events = engine.update(dt: dt, targetPlayerX: targetPlayerX)
        syncVisualsWithEngine()
        processEvents(events)
        notifyStateChange()
    }

    private func syncVisualsWithEngine() {
        updatePlayerPaddleGeometry(width: engine.currentPlayerPaddleWidth)
        stickyIndicator.isHidden = !engine.isPowerUpActive(.stickyPaddle)

        playerPaddle.position = CGPoint(x: engine.playerX, y: PingPongEngine.playerY)
        cpuPaddle.position = CGPoint(x: engine.cpuX, y: PingPongEngine.cpuY)

        // Subtle CPU eye tracking toward ball X
        let eyeShift = max(-3.0, min(3.0, (engine.ballPos.x - engine.cpuX) * 0.04))
        cpuEyeLeft.position.x = -8 + eyeShift
        cpuEyeRight.position.x = 8 + eyeShift

        // Ball position & color tint based on active power-up
        ballNode.position = engine.ballPos
        if engine.isChaosBall {
            ballNode.color = PingPongPixelArt.shared.skColor(hex: 0xA855F7)
            ballNode.colorBlendFactor = 0.75
        } else if engine.isPowerUpActive(.speedBoost) {
            ballNode.color = PingPongPixelArt.shared.skColor(hex: 0xFF4B5C)
            ballNode.colorBlendFactor = 0.7
        } else if engine.isPowerUpActive(.slowMotion) {
            ballNode.color = PingPongPixelArt.shared.skColor(hex: 0x3D7BFF)
            ballNode.colorBlendFactor = 0.65
        } else {
            ballNode.colorBlendFactor = 0.0
        }

        // Motion trail at higher speeds
        let speed = hypot(engine.ballVel.dx, engine.ballVel.dy)
        if let prevPos = trailHistory.last,
           hypot(engine.ballPos.x - prevPos.x, engine.ballPos.y - prevPos.y) > 90 {
            if !extraTrailHistory.isEmpty && !engine.hasExtraBall {
                trailHistory = extraTrailHistory
                extraTrailHistory.removeAll()
            } else {
                trailHistory.removeAll()
            }
        }
        trailHistory.append(engine.ballPos)
        if trailHistory.count > 18 {
            trailHistory.removeFirst()
        }

        let showTrail = speed > 280 && !engine.isGameOver && engine.serveDelayTimer <= 0
        for (i, node) in trailNodes.enumerated() {
            let historyIdx = trailHistory.count - 1 - (i + 1) * 2
            if showTrail && historyIdx >= 0 {
                node.position = trailHistory[historyIdx]
                node.color = ballNode.color
                node.colorBlendFactor = ballNode.colorBlendFactor
                node.isHidden = false
            } else {
                node.isHidden = true
            }
        }

        // Sync Extra Ball (Double Ball Power-Up) — identical visual properties to default ball
        if engine.hasExtraBall && !engine.isGameOver && engine.serveDelayTimer <= 0 {
            extraBallNode.isHidden = false
            extraBallNode.position = engine.extraBallPos
            extraBallNode.color = ballNode.color
            extraBallNode.colorBlendFactor = ballNode.colorBlendFactor

            let extraSpeed = hypot(engine.extraBallVel.dx, engine.extraBallVel.dy)
            extraTrailHistory.append(engine.extraBallPos)
            if extraTrailHistory.count > 18 {
                extraTrailHistory.removeFirst()
            }

            let showExtraTrail = extraSpeed > 280
            for (i, node) in extraTrailNodes.enumerated() {
                let historyIdx = extraTrailHistory.count - 1 - (i + 1) * 2
                if showExtraTrail && historyIdx >= 0 {
                    node.position = extraTrailHistory[historyIdx]
                    node.color = ballNode.color
                    node.colorBlendFactor = ballNode.colorBlendFactor
                    node.isHidden = false
                } else {
                    node.isHidden = true
                }
            }
        } else {
            extraBallNode.isHidden = true
            extraTrailHistory.removeAll()
            for node in extraTrailNodes {
                node.isHidden = true
            }
        }

        // Shield barrier visibility
        shieldBarrierNode.isHidden = !engine.hasShieldActive

        // Sync spawned field power-up nodes (zero allocation when idle)
        if !powerUpNodes.isEmpty || !engine.spawnedPowerUps.isEmpty {
            activePowerUpIDs.removeAll(keepingCapacity: true)
            for item in engine.spawnedPowerUps {
                activePowerUpIDs.insert(item.id)
            }
            for (id, node) in powerUpNodes where !activePowerUpIDs.contains(id) {
                node.removeFromParent()
                powerUpNodes.removeValue(forKey: id)
            }

            for item in engine.spawnedPowerUps {
                if let existing = powerUpNodes[item.id] {
                    existing.position = item.position
                    // Blink warning when about to despawn
                    let remaining = item.lifetime - item.age
                    if remaining < 2.0 {
                        existing.alpha = (Int(remaining * 8) % 2 == 0) ? 0.45 : 1.0
                    }
                } else {
                    let node = createPowerUpNode(for: item)
                    powerUpLayer.addChild(node)
                    powerUpNodes[item.id] = node
                }
            }
        }
    }

    private func createPowerUpNode(for item: SpawnedPowerUp) -> SKNode {
        let container = SKNode()
        container.position = item.position

        let bgCircle = SKShapeNode(circleOfRadius: item.radius)
        bgCircle.fillColor = PingPongPixelArt.shared.skColor(hex: 0x06141B, alpha: 0.92)
        bgCircle.strokeColor = PingPongPixelArt.shared.skColor(hex: item.type.uiColorHex)
        bgCircle.lineWidth = 2.5
        container.addChild(bgCircle)

        let iconSprite = SKSpriteNode(texture: PingPongPixelArt.shared.powerUpTexture(for: item.type))
        iconSprite.size = CGSize(width: 22, height: 22)
        container.addChild(iconSprite)

        container.setScale(0.2)
        let popIn = SKAction.scale(to: 1.0, duration: 0.22)
        popIn.timingMode = .easeOut
        let pulse = SKAction.repeatForever(
            .sequence([
                .scale(to: 1.08, duration: 0.55),
                .scale(to: 0.94, duration: 0.55)
            ])
        )
        container.run(.sequence([popIn, pulse]))
        return container
    }

    // MARK: - Event Handling (Audio, Haptics, Particles & Shake)

    private func processEvents(_ events: [PingPongEvent]) {
        for event in events {
            switch event {
            case .paddleHit(let isPlayer, let position, _, let isSmash):
                AudioManager.shared.play(.tap)
                if isPlayer {
                    if isSmash {
                        HapticsManager.shared.mediumImpact()
                        triggerScreenShake(intensity: 5.0)
                    } else {
                        HapticsManager.shared.lightTap()
                    }
                    animatePaddleBump(playerPaddle, dy: -4.0)
                } else {
                    animatePaddleBump(cpuPaddle, dy: 4.0)
                }
                spawnPixelSparks(
                    at: position,
                    color: PingPongPixelArt.shared.skColor(hex: isPlayer ? 0x00A896 : 0xFF4B5C),
                    count: isSmash ? 12 : 7
                )

            case .wallBounce(let position):
                AudioManager.shared.play(.bounce)
                spawnPixelSparks(at: position, color: PingPongPixelArt.shared.skColor(hex: 0x9BA8AB), count: 5)

            case .shieldSaved(let position):
                AudioManager.shared.play(.switchToggle)
                HapticsManager.shared.mediumImpact()
                triggerScreenShake(intensity: 6.0)
                spawnPixelSparks(at: position, color: PingPongPixelArt.shared.skColor(hex: 0x00D2FF), count: 16)

            case .powerUpSpawned(let item):
                AudioManager.shared.play(.pop)
                gameDelegate?.sceneDidSpawnPowerUp(item.type)

            case .powerUpCollected(let type, let position):
                AudioManager.shared.play(.nextLevel)
                HapticsManager.shared.mediumImpact()
                spawnPixelSparks(at: position, color: PingPongPixelArt.shared.skColor(hex: type.uiColorHex), count: 16)
                gameDelegate?.sceneDidCollectPowerUp(type)

            case .playerScored(let pointsAdded, _, let position):
                HapticsManager.shared.lightTap()
                let clampedY = min(PingPongEngine.courtHeight - 50, max(70, position.y))
                spawnFloatingText("+\(pointsAdded)", at: CGPoint(x: position.x, y: clampedY), colorHex: 0x2EDB8A)

            case .cpuScored(_, let position):
                AudioManager.shared.play(.error)
                HapticsManager.shared.heavyImpact()
                triggerScreenShake(intensity: 8.5)
                spawnPixelSparks(at: CGPoint(x: position.x, y: 36), color: PingPongPixelArt.shared.skColor(hex: 0xFF4B5C), count: 18)

            case .ballMissedLine(let position, let byPlayer):
                AudioManager.shared.play(.pop)
                spawnSubtleConfetti(at: position, missedByPlayer: byPlayer)

            case .stickyCaught(let position):
                AudioManager.shared.play(.slimeStick)
                HapticsManager.shared.lightTap()
                spawnFloatingText("CAUGHT!", at: CGPoint(x: position.x, y: position.y + 18), colorHex: 0xFFC83D)

            case .stickyLaunched(let position):
                AudioManager.shared.play(.tap)
                HapticsManager.shared.mediumImpact()
                spawnPixelSparks(at: position, color: PingPongPixelArt.shared.skColor(hex: 0xFFC83D), count: 10)

            case .callout(let text, let colorHex):
                gameDelegate?.sceneDidTriggerCallout(text: text, colorHex: colorHex)

            case .difficultyIncreased:
                AudioManager.shared.play(.nextLevel)

            case .gameOver(let finalScore, let playerWon, let isNewBest):
                if isNewBest || playerWon {
                    AudioManager.shared.play(.win)
                    HapticsManager.shared.success()
                } else {
                    AudioManager.shared.play(.error)
                    HapticsManager.shared.error()
                }
                gameDelegate?.sceneDidFinishGame(
                    finalScore: finalScore,
                    playerWon: playerWon,
                    isNewBest: isNewBest
                )
            }
        }
    }

    private func notifyStateChange(force: Bool = false) {
        var currentSeconds: [String: Int] = [:]
        for powerUp in engine.activePowerUps {
            currentSeconds[powerUp.id] = max(1, Int(ceil(powerUp.remaining)))
        }

        let playerScoreChanged = engine.playerScore != lastReportedPlayerScore
        let cpuScoreChanged = engine.cpuScore != lastReportedCpuScore
        let rallyChanged = engine.currentRally != lastReportedRally
        let powerUpsChanged = currentSeconds != lastReportedPowerUpSeconds

        guard force || playerScoreChanged || cpuScoreChanged || rallyChanged || powerUpsChanged else { return }

        lastReportedPlayerScore = engine.playerScore
        lastReportedCpuScore = engine.cpuScore
        lastReportedRally = engine.currentRally
        lastReportedPowerUpSeconds = currentSeconds

        gameDelegate?.sceneDidUpdateState(
            playerScore: engine.playerScore,
            cpuScore: engine.cpuScore,
            rally: engine.currentRally,
            activePowerUps: engine.activePowerUps
        )
    }

    // MARK: - Visual Effects (Pixel Sparks, Floating Labels, Screen Shake)

    private func animatePaddleBump(_ node: SKNode, dy: CGFloat) {
        node.removeAction(forKey: "bump")
        let move = SKAction.sequence([
            .moveBy(x: 0, y: dy, duration: 0.04),
            .moveBy(x: 0, y: -dy, duration: 0.08)
        ])
        node.run(move, withKey: "bump")
    }

    private func spawnPixelSparks(at pos: CGPoint, color: SKColor, count: Int) {
        for _ in 0..<count {
            let side = CGFloat.random(in: 4.0...7.0)
            let spark = SKSpriteNode(color: color, size: CGSize(width: side, height: side))
            spark.position = pos
            fxLayer.addChild(spark)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 18...52)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist

            spark.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.24),
                    .fadeOut(withDuration: 0.24),
                    .scale(to: 0.2, duration: 0.24)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnSubtleConfetti(at pos: CGPoint, missedByPlayer: Bool) {
        let confettiPalette: [UInt] = [
            0x00A896, // CheerUp Teal
            0x2EDB8A, // Emerald
            0xFFC83D, // Gold
            0xFF7AB6, // Neon Pink
            0x00D2FF, // Cyan
            0xA855F7, // Purple
            0xF5F8FC  // Crisp White
        ]

        // Subtle expanding pop ring where the ball crossed the line
        let ring = SKShapeNode(circleOfRadius: 6)
        ring.position = pos
        ring.strokeColor = PingPongPixelArt.shared.skColor(hex: 0xF5F8FC, alpha: 0.65)
        ring.fillColor = .clear
        ring.lineWidth = 1.5
        fxLayer.addChild(ring)
        ring.run(.sequence([
            .group([
                .scale(to: 2.6, duration: 0.24),
                .fadeOut(withDuration: 0.24)
            ]),
            .removeFromParent()
        ]))

        // Satisfying subtle pixel confetti pieces fluttering outward
        let pieceCount = 16
        for i in 0..<pieceCount {
            let colorHex = confettiPalette[i % confettiPalette.count]
            let w: CGFloat = (i % 2 == 0) ? 5.0 : 3.5
            let h: CGFloat = (i % 3 == 0) ? 3.5 : 6.0
            let piece = SKSpriteNode(
                color: PingPongPixelArt.shared.skColor(hex: colorHex, alpha: 0.92),
                size: CGSize(width: w, height: h)
            )
            piece.position = pos
            piece.zRotation = CGFloat.random(in: 0...(2 * .pi))
            fxLayer.addChild(piece)

            // Fan confetti nicely into the court from the passed line
            let baseAngle: CGFloat = missedByPlayer ? (.pi * 0.5) : (-.pi * 0.5)
            let spread = CGFloat.random(in: -(.pi * 0.44)...(.pi * 0.44))
            let angle = baseAngle + spread
            let dist = CGFloat.random(in: 22...58)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let dur = TimeInterval.random(in: 0.36...0.52)

            piece.run(.sequence([
                .group([
                    .sequence([
                        .moveBy(x: dx * 0.72, y: dy * 0.72, duration: dur * 0.45),
                        .moveBy(x: dx * 0.28, y: dy * 0.28 - 10.0, duration: dur * 0.55)
                    ]),
                    .rotate(byAngle: CGFloat.random(in: -5.0...5.0), duration: dur),
                    .sequence([
                        .wait(forDuration: dur * 0.35),
                        .fadeOut(withDuration: dur * 0.65)
                    ]),
                    .scale(to: 0.35, duration: dur)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnFloatingText(_ text: String, at pos: CGPoint, colorHex: UInt) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 18
        label.fontColor = PingPongPixelArt.shared.skColor(hex: colorHex)
        label.position = pos
        label.zPosition = 40
        fxLayer.addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 32, duration: 0.55),
                .sequence([
                    .scale(to: 1.2, duration: 0.1),
                    .scale(to: 1.0, duration: 0.12),
                    .wait(forDuration: 0.15),
                    .fadeOut(withDuration: 0.18)
                ])
            ]),
            .removeFromParent()
        ]))
    }

    private func triggerScreenShake(intensity: CGFloat) {
        let base = worldOrigin
        let shakeSeq = SKAction.sequence([
            .move(to: CGPoint(x: base.x + intensity, y: base.y - intensity * 0.6), duration: 0.035),
            .move(to: CGPoint(x: base.x - intensity * 0.8, y: base.y + intensity * 0.7), duration: 0.035),
            .move(to: CGPoint(x: base.x + intensity * 0.5, y: base.y + intensity * 0.3), duration: 0.035),
            .move(to: base, duration: 0.04)
        ])
        worldNode.run(shakeSeq, withKey: "shake")
    }

    // MARK: - Touch Controls (One-Handed Portrait Horizontal Dragging)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        activeTouch = touch
        let locInWorld = touch.location(in: worldNode)
        targetPlayerX = locInWorld.x

        // If Sticky Paddle caught the ball, tapping launches it immediately
        if engine.isBallStuckToPlayer {
            let launchEvents = engine.releaseStuckBall()
            processEvents(launchEvents)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = activeTouch, touches.contains(touch) else { return }
        let locInWorld = touch.location(in: worldNode)
        targetPlayerX = locInWorld.x
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            activeTouch = nil
            if engine.isBallStuckToPlayer {
                let launchEvents = engine.releaseStuckBall()
                processEvents(launchEvents)
            }
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = activeTouch, touches.contains(touch) {
            activeTouch = nil
        }
    }
}
