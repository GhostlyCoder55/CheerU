import SpriteKit
import UIKit

// MARK: - Gravity Pixel Art Generator
// Renders crisp, nearest-neighbor 2D pixel-art textures for the enchanted forest
// serpent (head, body, tail) and glowing elemental motes (Fire, Water, Earth, Wind).

final class GravityPixelArt {
    static let shared = GravityPixelArt()

    private var cache: [String: SKTexture] = [:]

    private init() {}

    func serpentHeadTexture(isWindPhase: Bool, isFireBoost: Bool, isWaterCalm: Bool = false) -> SKTexture {
        let key = "serpent_head_\(isWindPhase)_\(isFireBoost)_\(isWaterCalm)"
        if let cached = cache[key] { return cached }

        // 10x10 pixel serpent head facing UP with glowing eyes & cute forked tongue
        let grid = [
            "....44....",
            "....44....",
            "..111111..",
            ".11222211.",
            ".13322331.",
            ".13522531.",
            ".11222211.",
            ".11122111.",
            "..111111..",
            ".........."
        ]

        let primaryHex: UInt
        let highlightHex: UInt
        if isWindPhase {
            primaryHex = 0xBAE6FD
            highlightHex = 0xFFFFFF
        } else if isWaterCalm {
            // Calm Ocean Azure Serpent Head
            primaryHex = 0x0284C7 // Rich Ocean Azure Blue
            highlightHex = 0x7DD3FC // Luminous Water Glint
        } else if isFireBoost {
            primaryHex = 0xF59E0B
            highlightHex = 0xFDE68A
        } else {
            primaryHex = 0x10B981
            highlightHex = 0x6EE7B7
        }

        let tex = renderPixelGrid(grid, pixelScale: 3, palette: [
            "1": skColor(hex: primaryHex),
            "2": skColor(hex: highlightHex),
            "3": SKColor(white: 0.08, alpha: 1.0), // Dark eye socket
            "4": skColor(hex: 0xF43F5E),           // Little forked tongue
            "5": SKColor.white                     // Eye shine
        ])
        cache[key] = tex
        return tex
    }

    func serpentBodyTexture(isEven: Bool, isWindPhase: Bool, isFireBoost: Bool, isWaterCalm: Bool = false) -> SKTexture {
        let key = "serpent_body_\(isEven)_\(isWindPhase)_\(isFireBoost)_\(isWaterCalm)"
        if let cached = cache[key] { return cached }

        let grid = [
            "..........",
            "..111111..",
            ".11222211.",
            ".12233221.",
            ".12333321.",
            ".12333321.",
            ".12233221.",
            ".11222211.",
            "..111111..",
            ".........."
        ]

        let primaryHex: UInt
        let scalePatternHex: UInt
        let outlineHex: UInt
        if isWindPhase {
            primaryHex = isEven ? 0xBAE6FD : 0x7DD3FC
            scalePatternHex = 0xFFFFFF
            outlineHex = 0x062C1E
        } else if isWaterCalm {
            // Calm Ocean Azure Serpent Body
            primaryHex = isEven ? 0x0284C7 : 0x0369A1 // Ocean azure alternating with deep water blue
            scalePatternHex = 0x7DD3FC               // Glistening water scales
            outlineHex = 0x075985                    // Aquatic outline
        } else if isFireBoost {
            primaryHex = isEven ? 0xF59E0B : 0xD97706
            scalePatternHex = 0xFDE68A
            outlineHex = 0x062C1E
        } else {
            primaryHex = isEven ? 0x10B981 : 0x059669
            scalePatternHex = 0xA7F3D0
            outlineHex = 0x062C1E
        }

        let tex = renderPixelGrid(grid, pixelScale: 3, palette: [
            "1": skColor(hex: outlineHex),
            "2": skColor(hex: primaryHex),
            "3": skColor(hex: scalePatternHex)
        ])
        cache[key] = tex
        return tex
    }

    func moteTexture(for type: ElementalMoteType) -> SKTexture {
        let key = "mote_\(type.rawValue)"
        if let cached = cache[key] { return cached }

        let grid: [String]
        let palette: [Character: SKColor]

        switch type {
        case .fire:
            // Pixel Flame Spirit
            grid = [
                "....11....",
                "...1121...",
                "..112211..",
                ".11223211.",
                ".12233321.",
                ".12333321.",
                "..123321..",
                "...1111...",
                "..........",
                ".........."
            ]
            palette = [
                "1": skColor(hex: 0xEA580C),
                "2": skColor(hex: 0xF59E0B),
                "3": skColor(hex: 0xFEF08A)
            ]

        case .water:
            // Pixel Ocean Azure Dewdrop Crystal
            grid = [
                "....11....",
                "...1221...",
                "..122321..",
                ".12233221.",
                ".12332221.",
                ".12222221.",
                "..122221..",
                "...1111...",
                "..........",
                ".........."
            ]
            palette = [
                "1": skColor(hex: 0x075985), // Deep aquatic droplet border
                "2": skColor(hex: 0x0284C7), // Rich ocean azure crystal body
                "3": skColor(hex: 0xBAE6FD)  // Crisp glint highlight reflection
            ]

        case .earth:
            // Enchanted Acorn / Moss Gem
            grid = [
                "....33....",
                "..333333..",
                ".33444433.",
                "..112211..",
                ".11222211.",
                ".12222221.",
                "..122221..",
                "...1111...",
                "..........",
                ".........."
            ]
            palette = [
                "1": skColor(hex: 0x059669),
                "2": skColor(hex: 0x34D399),
                "3": skColor(hex: 0x78350F), // Earthy brown cap
                "4": skColor(hex: 0xA16207)
            ]

        case .wind:
            // Celestial Light Blue / Pure White Swirl
            grid = [
                "...1111...",
                "..122221..",
                ".1233311..",
                ".1231.....",
                "..123321..",
                "....1321..",
                "..112221..",
                "...1111...",
                "..........",
                ".........."
            ]
            palette = [
                "1": skColor(hex: 0x38BDF8),
                "2": skColor(hex: 0xBAE6FD),
                "3": SKColor.white
            ]
        }

        let tex = renderPixelGrid(grid, pixelScale: 3, palette: palette)
        cache[key] = tex
        return tex
    }

    private func renderPixelGrid(_ grid: [String], pixelScale: Int, palette: [Character: SKColor]) -> SKTexture {
        let rows = grid.count
        let cols = grid.first?.count ?? 1
        let width = cols * pixelScale
        let height = rows * pixelScale

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height))
        let image = renderer.image { ctx in
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

protocol GravitySceneDelegate: AnyObject {
    func sceneDidUpdateState(
        score: Int,
        orientation: GravityOrientation,
        activeEffects: [ActiveElementalEffect]
    )
    func sceneDidCollectMote(_ type: ElementalMoteType, pointsAdded: Int)
    func sceneDidShiftGravity(_ orientation: GravityOrientation)
    func sceneDidPhaseThroughSelf()
    func sceneDidFinishGame(finalScore: Int, isNewBest: Bool)
}

// MARK: - Gravity SpriteKit Scene

final class GravityScene: SKScene {

    weak var gameDelegate: GravitySceneDelegate?

    private let engine = GravityEngine()

    // Base board size in points (17 x 17 tiles at 20pt each = 340 x 340 square torus)
    private let tileSize: CGFloat = 20.0
    private var boardExtent: CGFloat {
        CGFloat(GravityEngine.gridColumns) * tileSize
    }

    // Scene Graph Nodes
    private let cameraPivotNode = SKNode() // Centered on screen; rotates smoothly when gravity shifts
    private let boardNode = SKNode()       // Origin at bottom-left of the 17x17 torus board
    private let groundLayer = SKNode()
    private let moteLayer = SKNode()
    private let serpentLayer = SKNode()
    private let fxLayer = SKNode()

    private var segmentNodes: [SKSpriteNode] = []
    private var moteNodes: [UUID: SKNode] = [:]
    private var fireflies: [SKSpriteNode] = []

    private var lastUpdateTime: TimeInterval?
    private var currentRenderedOrientation: GravityOrientation = .south
    private var lastReportedScore: Int = -1
    private var lastReportedOrientation: GravityOrientation? = nil
    private var lastReportedEffectSeconds: [String: Int] = [:]

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
        backgroundColor = GravityPixelArt.shared.skColor(hex: 0x07140E) // Deep enchanted forest charcoal
        setupSceneGraph()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        layoutBoardForScreenSize()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        layoutBoardForScreenSize()
    }

    // MARK: - Scene Setup

    private func setupSceneGraph() {
        addChild(cameraPivotNode)

        let half = boardExtent * 0.5
        boardNode.position = CGPoint(x: -half, y: -half)
        cameraPivotNode.addChild(boardNode)

        groundLayer.zPosition = 0
        moteLayer.zPosition = 10
        serpentLayer.zPosition = 20
        fxLayer.zPosition = 30

        boardNode.addChild(groundLayer)
        boardNode.addChild(moteLayer)
        boardNode.addChild(serpentLayer)
        boardNode.addChild(fxLayer)

        buildEnchantedForestTorusBoard()
        buildAtmosphericFireflies()
        syncVisualsWithEngine()
    }

    private func buildEnchantedForestTorusBoard() {
        let cols = GravityEngine.gridColumns
        let rows = GravityEngine.gridRows
        let ext = boardExtent

        // Outer earthy wooden/stone frame shadow
        let shadowFrame = SKShapeNode(rect: CGRect(x: -8, y: -8, width: ext + 16, height: ext + 16), cornerRadius: 16)
        shadowFrame.fillColor = SKColor(white: 0.0, alpha: 0.48)
        shadowFrame.strokeColor = .clear
        groundLayer.addChild(shadowFrame)

        // Checkerboard deep moss & earthy forest floor tiles
        let tileDark  = GravityPixelArt.shared.skColor(hex: 0x0B1E15) // Deep forest green
        let tileLight = GravityPixelArt.shared.skColor(hex: 0x10281C) // Moss slate green

        let baseBg = SKSpriteNode(color: tileDark, size: CGSize(width: ext, height: ext))
        baseBg.anchorPoint = .zero
        groundLayer.addChild(baseBg)

        for r in 0..<rows {
            for c in 0..<cols where (r + c) % 2 == 1 {
                let tile = SKSpriteNode(color: tileLight, size: CGSize(width: tileSize, height: tileSize))
                tile.anchorPoint = .zero
                tile.position = CGPoint(x: CGFloat(c) * tileSize, y: CGFloat(r) * tileSize)
                groundLayer.addChild(tile)
            }
        }

        //Glowing Torus Portal Border Lines (Crossing these shifts gravity!)
        // Top/Bottom (Mystical Purple / Cyan) & Left/Right (Warm Amber / Emerald)
        let borderRect = CGRect(x: -2, y: -2, width: ext + 4, height: ext + 4)
        let portalBorder = SKShapeNode(rect: borderRect, cornerRadius: 10)
        portalBorder.fillColor = .clear
        portalBorder.strokeColor = GravityPixelArt.shared.skColor(hex: 0x3E2C1C) // Earthy brown rune frame
        portalBorder.lineWidth = 4.0
        groundLayer.addChild(portalBorder)

        // Subtle glowing rune dashes along the 4 torus wrap edges
        let dashCount = 9
        let step = ext / CGFloat(dashCount)
        for i in 0..<dashCount where i % 2 == 0 {
            let offset = CGFloat(i) * step + step * 0.5
            // Left & Right gravity shift runes (Glowing Cyan)
            for xEdge in [CGFloat(1.5), ext - 1.5] {
                let rune = SKSpriteNode(
                    color: GravityPixelArt.shared.skColor(hex: 0x22D3EE, alpha: 0.55),
                    size: CGSize(width: 3, height: step * 0.55)
                )
                rune.position = CGPoint(x: xEdge, y: offset)
                groundLayer.addChild(rune)
            }
            // Top & Bottom gravity shift runes (Mystical Purple)
            for yEdge in [CGFloat(1.5), ext - 1.5] {
                let rune = SKSpriteNode(
                    color: GravityPixelArt.shared.skColor(hex: 0xA855F7, alpha: 0.55),
                    size: CGSize(width: step * 0.55, height: 3)
                )
                rune.position = CGPoint(x: offset, y: yEdge)
                groundLayer.addChild(rune)
            }
        }
    }

    private func buildAtmosphericFireflies() {
        let ext = boardExtent
        let colors: [UInt] = [0x10B981, 0xF59E0B, 0x0284C7, ElementalMoteType.wind.colorHex]
        for i in 0..<10 {
            let firefly = SKSpriteNode(
                color: GravityPixelArt.shared.skColor(hex: colors[i % colors.count], alpha: 0.45),
                size: CGSize(width: 3, height: 3)
            )
            firefly.position = CGPoint(
                x: CGFloat.random(in: 16...(ext - 16)),
                y: CGFloat.random(in: 16...(ext - 16))
            )
            fxLayer.addChild(firefly)
            fireflies.append(firefly)

            let drift = SKAction.repeatForever(
                .sequence([
                    .group([
                        .moveBy(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: -18...18), duration: Double.random(in: 2.2...3.6)),
                        .fadeAlpha(to: 0.18, duration: 1.6)
                    ]),
                    .group([
                        .moveBy(x: CGFloat.random(in: -18...18), y: CGFloat.random(in: -18...18), duration: Double.random(in: 2.2...3.6)),
                        .fadeAlpha(to: 0.65, duration: 1.6)
                    ])
                ])
            )
            firefly.run(drift)
        }
    }

    private func layoutBoardForScreenSize() {
        guard size.width > 0, size.height > 0 else { return }

        // Reserve space at top for header + MiniCheerUp! stage + quick orb rules (~166pt)
        // and at bottom for the cross (+) directional pad (~212pt)
        let topReserved: CGFloat = 166.0
        let bottomReserved: CGFloat = 212.0
        let availableH = max(220.0, size.height - topReserved - bottomReserved)
        let availableW = max(220.0, size.width - 28.0)

        let fitSide = min(availableW, availableH)
        let scale = fitSide / (boardExtent + 16.0)

        cameraPivotNode.setScale(scale)
        cameraPivotNode.position = CGPoint(
            x: size.width * 0.5,
            y: bottomReserved + availableH * 0.5
        )
    }

    // MARK: - Game Control

    func startNewGame() {
        engine.reset()
        moteLayer.removeAllChildren()
        moteNodes.removeAll()
        serpentLayer.removeAllChildren()
        segmentNodes.removeAll()

        currentRenderedOrientation = .south
        cameraPivotNode.removeAction(forKey: "gravityRotate")
        cameraPivotNode.zRotation = 0

        lastUpdateTime = nil
        isGamePaused = false
        lastReportedScore = -1
        lastReportedOrientation = nil
        lastReportedEffectSeconds.removeAll()
        syncVisualsWithEngine()
        notifyStateChange(force: true)
    }

    func continueAfterReward() {
        engine.continueAfterReward()
        // Preserves serpent segments, length, motes, and orientation upon resume!
        lastUpdateTime = nil
        isGamePaused = false
        lastReportedScore = -1
        lastReportedOrientation = nil
        lastReportedEffectSeconds.removeAll()
        syncVisualsWithEngine()
        notifyStateChange(force: true)
    }

    func handleSwipe(_ screenDirection: GravityDirection) {
        engine.queueScreenDirection(screenDirection)
        HapticsManager.shared.selection()
    }

    // MARK: - Frame Update (60 FPS)

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

        let events = engine.update(dt: dt)
        syncVisualsWithEngine()
        processEvents(events)
        notifyStateChange()
    }

    private func syncVisualsWithEngine() {
        let segs = engine.segments
        let prevSegs = engine.previousSegments
        let t = engine.stepProgress
        let windActive = engine.isWindPhaseActive
        let fireActive = engine.isFireBoostActive
        let waterActive = engine.isWaterCalmActive

        // Rebuild segment sprites if serpent grew
        while segmentNodes.count < segs.count {
            let sprite = SKSpriteNode()
            sprite.size = CGSize(width: tileSize * 1.05, height: tileSize * 1.05)
            serpentLayer.addChild(sprite)
            segmentNodes.append(sprite)
        }
        while segmentNodes.count > segs.count {
            segmentNodes.removeLast().removeFromParent()
        }

        for i in 0..<segs.count {
            let node = segmentNodes[i]
            let cur = segs[i]
            let prev = i < prevSegs.count ? prevSegs[i] : cur

            // Smoothly interpolate unless this segment just wrapped across the torus boundary
            let dx = abs(cur.x - prev.x)
            let dy = abs(cur.y - prev.y)
            let pos: CGPoint
            if dx <= 1 && dy <= 1 {
                let ix = CGFloat(prev.x) + CGFloat(cur.x - prev.x) * t
                let iy = CGFloat(prev.y) + CGFloat(cur.y - prev.y) * t
                pos = CGPoint(x: (ix + 0.5) * tileSize, y: (iy + 0.5) * tileSize)
            } else {
                pos = pointForCoord(cur)
            }

            node.position = pos
            node.alpha = windActive ? 0.65 : 1.0
            node.color = .white
            node.colorBlendFactor = windActive ? 0.45 : 0.0

            if i == 0 {
                // Serpent Head
                let headTex = GravityPixelArt.shared.serpentHeadTexture(
                    isWindPhase: windActive,
                    isFireBoost: fireActive,
                    isWaterCalm: waterActive
                )
                if node.texture !== headTex {
                    node.texture = headTex
                }
                node.size = CGSize(width: tileSize * 1.18, height: tileSize * 1.18)
                node.zPosition = 5
                switch engine.moveDirection {
                case .up:    node.zRotation = 0
                case .right: node.zRotation = -.pi * 0.5
                case .down:  node.zRotation = .pi
                case .left:  node.zRotation = .pi * 0.5
                }
            } else {
                // Serpent Body & Tail taper
                let bodyTex = GravityPixelArt.shared.serpentBodyTexture(
                    isEven: i % 2 == 0,
                    isWindPhase: windActive,
                    isFireBoost: fireActive,
                    isWaterCalm: waterActive
                )
                if node.texture !== bodyTex {
                    node.texture = bodyTex
                }
                let isTail = (i == segs.count - 1)
                let scaleFactor: CGFloat = isTail ? 0.78 : 0.96
                node.size = CGSize(width: tileSize * scaleFactor, height: tileSize * scaleFactor)
                node.zPosition = 2
                node.zRotation = 0
            }
        }

        // Sync Elemental Motes
        let activeIDs = Set(engine.spawnedMotes.map { $0.id })
        for (id, node) in moteNodes where !activeIDs.contains(id) {
            node.removeFromParent()
            moteNodes.removeValue(forKey: id)
        }

        for mote in engine.spawnedMotes {
            if let existing = moteNodes[mote.id] {
                existing.position = pointForCoord(mote.coord)
            } else {
                let node = createMoteNode(for: mote)
                moteLayer.addChild(node)
                moteNodes[mote.id] = node
            }
        }
    }

    private func createMoteNode(for mote: SpawnedMote) -> SKNode {
        let container = SKNode()
        container.position = pointForCoord(mote.coord)

        let aura = SKShapeNode(circleOfRadius: tileSize * 0.52)
        aura.fillColor = GravityPixelArt.shared.skColor(hex: mote.type.colorHex, alpha: 0.22)
        aura.strokeColor = GravityPixelArt.shared.skColor(hex: mote.type.colorHex, alpha: 0.65)
        aura.lineWidth = 1.5
        container.addChild(aura)

        let sprite = SKSpriteNode(texture: GravityPixelArt.shared.moteTexture(for: mote.type))
        sprite.size = CGSize(width: tileSize * 0.95, height: tileSize * 0.95)
        container.addChild(sprite)

        container.setScale(0.2)
        let popIn = SKAction.scale(to: 1.0, duration: 0.2)
        popIn.timingMode = .easeOut
        let pulse = SKAction.repeatForever(
            .sequence([
                .scale(to: 1.12, duration: 0.55),
                .scale(to: 0.92, duration: 0.55)
            ])
        )
        container.run(.sequence([popIn, pulse]))
        return container
    }

    private func pointForCoord(_ coord: GridCoord) -> CGPoint {
        CGPoint(
            x: (CGFloat(coord.x) + 0.5) * tileSize,
            y: (CGFloat(coord.y) + 0.5) * tileSize
        )
    }

    // MARK: - Events, Animations & Audio

    private func processEvents(_ events: [GravityEvent]) {
        for event in events {
            switch event {
            case .moved:
                break

            case .moteCollected(let type, let coord, let pointsAdded, _):
                GravityAudioController.shared.playMoteSound(type)
                HapticsManager.shared.lightTap()
                let pt = pointForCoord(coord)
                spawnElementalParticles(at: pt, colorHex: type.colorHex, count: 14)
                spawnFloatingScore("+\(pointsAdded)", at: pt, colorHex: type.colorHex)
                gameDelegate?.sceneDidCollectMote(type, pointsAdded: pointsAdded)

            case .gravityShifted(let newOrientation, _):
                GravityAudioController.shared.playGravityShiftSound()
                HapticsManager.shared.mediumImpact()
                animateGravityRotation(to: newOrientation)
                gameDelegate?.sceneDidShiftGravity(newOrientation)

            case .windPhasedThroughSelf(let coord):
                AudioManager.shared.play(.switchToggle)
                HapticsManager.shared.lightTap()
                let pt = pointForCoord(coord)
                spawnElementalParticles(at: pt, colorHex: ElementalMoteType.wind.colorHex, count: 12)
                gameDelegate?.sceneDidPhaseThroughSelf()

            case .gameOver(let finalScore, let isNewBest):
                GravityAudioController.shared.stopBackgroundMusic()
                if isNewBest {
                    AudioManager.shared.play(.win)
                    HapticsManager.shared.success()
                } else {
                    AudioManager.shared.play(.error)
                    HapticsManager.shared.heavyImpact()
                }
                if let head = engine.segments.first {
                    spawnElementalParticles(at: pointForCoord(head), colorHex: 0xF59E0B, count: 22)
                }
                gameDelegate?.sceneDidFinishGame(finalScore: finalScore, isNewBest: isNewBest)
            }
        }
    }

    private func animateGravityRotation(to newOrientation: GravityOrientation) {
        currentRenderedOrientation = newOrientation
        let targetAngle = newOrientation.zRotationRadians
        let rotateAction = SKAction.rotate(toAngle: targetAngle, duration: 0.42, shortestUnitArc: true)
        rotateAction.timingMode = .easeInEaseOut

        // Subtle pulse on the board during gravity shift
        let baseScale = cameraPivotNode.xScale
        let pulseAction = SKAction.sequence([
            .scale(to: baseScale * 0.94, duration: 0.18),
            .scale(to: baseScale, duration: 0.24)
        ])
        cameraPivotNode.run(.group([rotateAction, pulseAction]), withKey: "gravityRotate")
    }

    private func spawnElementalParticles(at pos: CGPoint, colorHex: UInt, count: Int) {
        let color = GravityPixelArt.shared.skColor(hex: colorHex)
        for _ in 0..<count {
            let side = CGFloat.random(in: 4.0...7.0)
            let p = SKSpriteNode(color: color, size: CGSize(width: side, height: side))
            p.position = pos
            fxLayer.addChild(p)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 14...42)
            p.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.28),
                    .fadeOut(withDuration: 0.28),
                    .scale(to: 0.2, duration: 0.28)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnFloatingScore(_ text: String, at pos: CGPoint, colorHex: UInt) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 15
        label.fontColor = GravityPixelArt.shared.skColor(hex: colorHex)
        label.position = pos
        label.zRotation = -cameraPivotNode.zRotation // Keep floating text upright relative to player!
        fxLayer.addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 22, duration: 0.5),
                .fadeOut(withDuration: 0.5)
            ]),
            .removeFromParent()
        ]))
    }

    private func notifyStateChange(force: Bool = false) {
        var currentSeconds: [String: Int] = [:]
        for effect in engine.activeEffects {
            currentSeconds[effect.id] = max(1, Int(ceil(effect.remaining)))
        }

        let scoreChanged = engine.score != lastReportedScore
        let orientationChanged = engine.orientation != lastReportedOrientation
        let effectsChanged = currentSeconds != lastReportedEffectSeconds

        guard force || scoreChanged || orientationChanged || effectsChanged else { return }

        lastReportedScore = engine.score
        lastReportedOrientation = engine.orientation
        lastReportedEffectSeconds = currentSeconds

        gameDelegate?.sceneDidUpdateState(
            score: engine.score,
            orientation: engine.orientation,
            activeEffects: engine.activeEffects
        )
    }
}
