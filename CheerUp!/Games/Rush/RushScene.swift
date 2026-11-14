import SpriteKit
import UIKit

// MARK: - RUSH Pixel Art Texture Generator
// Crisp nearest-neighbor 2D indie pixel art:
// - Tiny starfighter spaceship
// - Uniform pixel meteor obstacles (all looking identical)
// - Little glowing power-up orbs (Shield & Slow Speed)

final class RushPixelArt {
    static let shared = RushPixelArt()

    private var cache: [String: SKTexture] = [:]

    private init() {}

    func spaceshipTexture(isHyperRush: Bool) -> SKTexture {
        let key = "rush_ship_\(isHyperRush)"
        if let cached = cache[key] { return cached }

        // 12x12 crisp pixel starfighter
        let grid = [
            ".....11.....",
            "....1221....",
            "....1221....",
            "...123321...",
            "..12233221..",
            ".4122332214.",
            "441222222144",
            "411122221114",
            "11.115511.11",
            "1...1551...1",
            ".....55.....",
            "............"
        ]

        let hullHex: UInt = isHyperRush ? 0xFEF08A : 0xF8FAFC
        let wingTipHex: UInt = isHyperRush ? 0xFFC83D : 0xFF2E93

        let tex = renderPixelGrid(grid, pixelScale: 3, palette: [
            "1": skColor(hex: 0x0F172A),   // Dark outline
            "2": skColor(hex: hullHex),    // Crisp starfighter hull
            "3": skColor(hex: 0x22D3EE),   // Glowing cyan cockpit visor
            "4": skColor(hex: wingTipHex), // Neon magenta wing tips
            "5": skColor(hex: 0xF97316)    // Thruster nozzle glow
        ])
        cache[key] = tex
        return tex
    }

    /// Single uniform pixel-art meteor texture so every obstacle looks identical
    func meteorTexture() -> SKTexture {
        let key = "rush_uniform_meteor"
        if let cached = cache[key] { return cached }

        // 11x11 classic craggy pixel meteor with warm rocky shading & glowing ember core crack
        let grid = [
            "...11111...",
            "..1222441..",
            ".122332441.",
            "12235322221",
            "12233223321",
            "13222235321",
            "13322233231",
            "13332222331",
            ".133333331.",
            "..1333331..",
            "...11111..."
        ]

        let tex = renderPixelGrid(grid, pixelScale: 3, palette: [
            "1": skColor(hex: 0x090D16), // Crisp dark pixel outline
            "2": skColor(hex: 0x475569), // Mid meteor stone
            "3": skColor(hex: 0x1E293B), // Deep crater shadow
            "4": skColor(hex: 0x94A3B8), // Top-right rim highlight
            "5": skColor(hex: 0xFF2E93)  // Subtle glowing core ember
        ])
        cache[key] = tex
        return tex
    }

    /// Little glowing pixel power-up orbs (Shield = Cyan Orb, Slow = Violet Orb)
    func powerUpOrbTexture(for type: RushPowerUpType) -> SKTexture {
        let key = "rush_orb_\(type.rawValue)"
        if let cached = cache[key] { return cached }

        // 8x8 cute little glowing pixel orb
        let grid = [
            "..1111..",
            ".122321.",
            "12233221",
            "12332221",
            "12222221",
            "12222221",
            ".122221.",
            "..1111.."
        ]

        let palette: [Character: SKColor]
        switch type {
        case .shield:
            palette = [
                "1": skColor(hex: 0x0891B2),
                "2": skColor(hex: 0x22D3EE),
                "3": SKColor.white
            ]
        case .slowTime:
            palette = [
                "1": skColor(hex: 0x7E22CE),
                "2": skColor(hex: 0xA855F7),
                "3": skColor(hex: 0xF3E8FF)
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
            let cg = ctx.cgContext
            cg.interpolationQuality = .none
            for (rIdx, row) in grid.enumerated() {
                for (cIdx, ch) in row.enumerated() {
                    guard let color = palette[ch] else { continue }
                    cg.setFillColor(color.cgColor)
                    cg.fill(CGRect(x: cIdx * pixelScale, y: rIdx * pixelScale, width: pixelScale, height: pixelScale))
                }
            }
        }

        let tex = SKTexture(image: image)
        tex.filteringMode = .nearest
        return tex
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

// MARK: - Rush Scene Delegate

protocol RushSceneDelegate: AnyObject {
    func sceneDidUpdateState(
        score: Int,
        activeEffects: [ActiveRushEffect]
    )
    func sceneDidTriggerNearMiss(streak: Int)
    func sceneDidCollectPowerUp(_ type: RushPowerUpType)
    func sceneDidAbsorbHitWithShield()
    func sceneDidAnnounceSpecialEvent(_ kind: RushSpecialEventKind, isWarning: Bool)
    func sceneDidFinishGame(finalScore: Int, isNewBest: Bool)
}

// MARK: - RUSH SpriteKit Scene (Portrait 60 FPS)

final class RushScene: SKScene {

    weak var gameDelegate: RushSceneDelegate?

    private let engine = RushEngine()

    // Scene Layers
    private let worldNode = SKNode()
    private let starfieldLayer = SKNode()
    private let telegraphLayer = SKNode()
    private let collectibleLayer = SKNode()
    private let meteorLayer = SKNode()
    private let shipLayer = SKNode()
    private let fxLayer = SKNode()

    // Player Ship Nodes
    private let shipNode = SKSpriteNode()
    private let shieldRingNode = SKShapeNode(circleOfRadius: 24)
    private var thrusterTimer: Double = 0.0

    // Dynamic Node Maps
    private var meteorNodes: [UUID: SKSpriteNode] = [:]
    private var collectibleNodes: [UUID: SKSpriteNode] = [:]
    private var stars: [(node: SKSpriteNode, speed: CGFloat)] = []

    // Touch-and-drag state (1-finger intuitive movement)
    private var isTouching: Bool = false
    private var targetShipPosition: CGPoint? = nil
    private var dragOffset: CGPoint = .zero

    private var lastUpdateTime: TimeInterval?
    private var lastReportedEffectSeconds: [String: Int] = [:]

    var isCrashing: Bool { engine.isGameOver }

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
        backgroundColor = RushPixelArt.shared.skColor(hex: 0x090D16)
        setupSceneGraph()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func didMove(to view: SKView) {
        engine.updateWorldSize(width: size.width, height: size.height)
        rebuildStarfield()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        guard size.width > 100, size.height > 200 else { return }
        engine.updateWorldSize(width: size.width, height: size.height)
        if stars.isEmpty || abs(oldSize.width - size.width) > 20 {
            rebuildStarfield()
        }
    }

    // MARK: - Scene Setup

    private func setupSceneGraph() {
        addChild(worldNode)

        starfieldLayer.zPosition = 1
        telegraphLayer.zPosition = 5
        collectibleLayer.zPosition = 12
        meteorLayer.zPosition = 15
        shipLayer.zPosition = 20
        fxLayer.zPosition = 30

        worldNode.addChild(starfieldLayer)
        worldNode.addChild(telegraphLayer)
        worldNode.addChild(collectibleLayer)
        worldNode.addChild(meteorLayer)
        worldNode.addChild(shipLayer)
        worldNode.addChild(fxLayer)

        let tex = RushPixelArt.shared.spaceshipTexture(isHyperRush: false)
        shipNode.texture = tex
        shipNode.size = tex.size()
        shipLayer.addChild(shipNode)

        shieldRingNode.strokeColor = RushPixelArt.shared.skColor(hex: 0x22D3EE, alpha: 0.88)
        shieldRingNode.fillColor = RushPixelArt.shared.skColor(hex: 0x22D3EE, alpha: 0.14)
        shieldRingNode.lineWidth = 2.0
        shieldRingNode.isHidden = true
        shipNode.addChild(shieldRingNode)
    }

    private func rebuildStarfield() {
        starfieldLayer.removeAllChildren()
        stars.removeAll()
        let w = max(320.0, size.width)
        let h = max(600.0, size.height)

        let palette: [UInt] = [0xF8FAFC, 0x22D3EE, 0xFF2E93, 0xA855F7, 0x64748B]
        for i in 0..<42 {
            let depth = CGFloat(i % 3 + 1)
            let pixelSize = depth == 3 ? CGFloat(3.0) : CGFloat(2.0)
            let colorHex = palette[i % palette.count]
            let alpha: CGFloat = depth == 1 ? 0.28 : (depth == 2 ? 0.52 : 0.82)

            let star = SKSpriteNode(
                color: RushPixelArt.shared.skColor(hex: colorHex, alpha: alpha),
                size: CGSize(width: pixelSize, height: pixelSize)
            )
            star.position = CGPoint(
                x: CGFloat.random(in: 8...(w - 8)),
                y: CGFloat.random(in: 8...(h - 8))
            )
            starfieldLayer.addChild(star)
            stars.append((node: star, speed: depth * 48.0))
        }
    }

    // MARK: - Game Control

    func startNewGame() {
        removeAction(forKey: "crashSequence")
        engine.updateWorldSize(width: max(320, size.width), height: max(600, size.height))
        engine.reset()

        worldNode.removeAllActions()
        worldNode.position = .zero
        shipNode.removeAllActions()
        shipNode.isHidden = false
        shipNode.alpha = 1.0

        meteorLayer.removeAllChildren()
        meteorNodes.removeAll()
        collectibleLayer.removeAllChildren()
        collectibleNodes.removeAll()
        telegraphLayer.removeAllChildren()
        fxLayer.removeAllChildren()

        targetShipPosition = CGPoint(x: engine.shipX, y: engine.shipY)
        isTouching = false
        lastUpdateTime = nil
        lastReportedEffectSeconds.removeAll()
        isGamePaused = false

        syncVisuals(dt: 1.0 / 60.0)
        notifyStateChange()
    }

    func cancelPendingCrash() {
        removeAction(forKey: "crashSequence")
    }

    func continueAfterReward() {
        removeAction(forKey: "crashSequence")
        engine.continueAfterReward()

        worldNode.removeAllActions()
        worldNode.position = .zero
        shipNode.removeAllActions()
        shipNode.isHidden = false
        shipNode.alpha = 1.0

        // Prune only nodes whose meteors were cleared near the ship
        let activeIDs = Set(engine.asteroids.map { $0.id })
        for (id, node) in meteorNodes where !activeIDs.contains(id) {
            node.removeFromParent()
            meteorNodes.removeValue(forKey: id)
        }
        telegraphLayer.removeAllChildren()
        fxLayer.removeAllChildren()

        targetShipPosition = CGPoint(x: engine.shipX, y: engine.shipY)
        isTouching = false
        lastUpdateTime = nil
        isGamePaused = false

        syncVisuals(dt: 1.0 / 60.0)
        notifyStateChange()
    }

    // MARK: - Touch & Drag Input (One-Handed Portrait Play)

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isGamePaused, !engine.isGameOver else { return }
        let loc = touch.location(in: self)
        isTouching = true

        let dist = hypot(loc.x - engine.shipX, loc.y - engine.shipY)
        if dist < 64.0 {
            dragOffset = CGPoint(x: engine.shipX - loc.x, y: max(28.0, engine.shipY - loc.y))
        } else {
            dragOffset = CGPoint(x: engine.shipX - loc.x, y: engine.shipY - loc.y)
        }
        targetShipPosition = CGPoint(x: loc.x + dragOffset.x, y: loc.y + dragOffset.y)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isTouching, !isGamePaused, !engine.isGameOver else { return }
        let loc = touch.location(in: self)
        targetShipPosition = CGPoint(x: loc.x + dragOffset.x, y: loc.y + dragOffset.y)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        isTouching = false
    }

    // MARK: - 60 FPS Frame Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused, !engine.isGameOver else {
            lastUpdateTime = currentTime
            return
        }

        let dt: Double
        if let last = lastUpdateTime {
            dt = min(max(currentTime - last, 0.0), 1.0 / 20.0)
        } else {
            dt = 1.0 / 60.0
        }
        lastUpdateTime = currentTime

        let events = engine.update(dt: dt, targetShipPosition: targetShipPosition)
        syncVisuals(dt: dt)

        if !events.isEmpty {
            processEvents(events)
        }

        syncActiveEffectsCountdown()
    }

    // MARK: - Visual Synchronization

    private func syncVisuals(dt: Double) {
        // 1. Scroll parallax pixel starfield
        let starMult: CGFloat = engine.isSlowTimeActive ? 0.45 : 1.0
        let h = max(600.0, size.height)
        let w = max(320.0, size.width)
        for item in stars {
            item.node.position.y -= item.speed * starMult * CGFloat(dt)
            if item.node.position.y < -6 {
                item.node.position.y = h + 6
                item.node.position.x = CGFloat.random(in: 8...(w - 8))
            }
        }

        // 2. Ship position, tilt, shield & pixel thruster particles
        shipNode.position = CGPoint(x: engine.shipX, y: engine.shipY)
        shipNode.zRotation = -engine.shipTilt * 0.28
        let shipTex = RushPixelArt.shared.spaceshipTexture(isHyperRush: false)
        if shipNode.texture !== shipTex {
            shipNode.texture = shipTex
        }
        shieldRingNode.isHidden = !engine.hasShield

        thrusterTimer += dt
        if thrusterTimer >= 0.045 {
            thrusterTimer = 0
            spawnThrusterPixel()
        }

        // 3. Sync Uniform Meteors (50% larger: 50x50pt)
        let sharedMeteorTex = RushPixelArt.shared.meteorTexture()
        let meteorSize = CGSize(width: 50, height: 50)
        var activeMeteorIDs = Set<UUID>()
        for meteor in engine.asteroids {
            activeMeteorIDs.insert(meteor.id)
            let node: SKSpriteNode
            if let existing = meteorNodes[meteor.id] {
                node = existing
                if node.size != meteorSize {
                    node.size = meteorSize
                }
            } else {
                let created = SKSpriteNode(texture: sharedMeteorTex, size: meteorSize)
                meteorLayer.addChild(created)
                meteorNodes[meteor.id] = created
                node = created
            }
            node.position = CGPoint(x: meteor.x, y: meteor.y)
            node.zRotation = meteor.rotation
        }

        for (id, node) in meteorNodes where !activeMeteorIDs.contains(id) {
            node.removeFromParent()
            meteorNodes.removeValue(forKey: id)
        }

        // 4. Sync Little Power-Up Orbs
        var activeCollectibleIDs = Set<UUID>()
        for col in engine.collectibles {
            activeCollectibleIDs.insert(col.id)
            let node: SKSpriteNode
            if let existing = collectibleNodes[col.id] {
                node = existing
            } else {
                let tex = RushPixelArt.shared.powerUpOrbTexture(for: col.type)
                let created = SKSpriteNode(texture: tex, size: tex.size())

                // Soft pulsing orb aura
                let aura = SKShapeNode(circleOfRadius: 15)
                aura.strokeColor = RushPixelArt.shared.skColor(hex: col.type.colorHex, alpha: 0.65)
                aura.fillColor = RushPixelArt.shared.skColor(hex: col.type.colorHex, alpha: 0.16)
                aura.lineWidth = 1.5
                created.addChild(aura)

                aura.run(.repeatForever(.sequence([
                    .scale(to: 1.18, duration: 0.55),
                    .scale(to: 0.92, duration: 0.55)
                ])))

                collectibleLayer.addChild(created)
                collectibleNodes[col.id] = created
                node = created
            }
            node.position = CGPoint(x: col.x, y: col.y)
        }

        for (id, node) in collectibleNodes where !activeCollectibleIDs.contains(id) {
            node.removeFromParent()
            collectibleNodes.removeValue(forKey: id)
        }
    }

    // MARK: - Event Handling & Pixel FX

    private func processEvents(_ events: [RushEvent]) {
        for event in events {
            switch event {
            case .scoreChanged:
                notifyStateChange()

            case .nearMiss(let x, let y, let streak):
                HapticsManager.shared.lightTap()
                RushAudioController.shared.playNearMiss()
                spawnPixelBurst(at: CGPoint(x: x, y: y), colorHex: 0x22D3EE, count: 9)
                spawnFloatingText(
                    LanguageManager.shared.tr("CLOSE CALL!", "C'ÉTAIT JUSTE !", "¡POR POCO!"),
                    at: CGPoint(x: engine.shipX, y: engine.shipY + 26),
                    colorHex: 0x22D3EE
                )
                gameDelegate?.sceneDidTriggerNearMiss(streak: streak)
                notifyStateChange()

            case .powerUpCollected(let type, let x, let y):
                HapticsManager.shared.mediumImpact()
                AudioManager.shared.play(.nextLevel)
                spawnPixelBurst(at: CGPoint(x: x, y: y), colorHex: type.colorHex, count: 14)
                spawnFloatingText(
                    "\(type.badgeTitle)",
                    at: CGPoint(x: x, y: y + 18),
                    colorHex: type.colorHex
                )
                gameDelegate?.sceneDidCollectPowerUp(type)
                notifyStateChange()

            case .shieldAbsorbedHit(let x, let y):
                HapticsManager.shared.heavyImpact()
                RushAudioController.shared.playShieldBreak()
                playShieldImpactAnimation(at: CGPoint(x: x, y: y))
                spawnFloatingText(
                    LanguageManager.shared.tr("SHIELD SAVED!", "BOUCLIER !", "¡ESCUDO!"),
                    at: CGPoint(x: engine.shipX, y: engine.shipY + 28),
                    colorHex: 0x22D3EE
                )
                gameDelegate?.sceneDidAbsorbHitWithShield()
                notifyStateChange()

            case .specialEventWarning(let kind, let safeCorridorX):
                HapticsManager.shared.selection()
                RushAudioController.shared.playWarning()
                showWarningTelegraph(for: kind, safeCorridorX: safeCorridorX)
                gameDelegate?.sceneDidAnnounceSpecialEvent(kind, isWarning: true)

            case .specialEventStarted(let kind):
                gameDelegate?.sceneDidAnnounceSpecialEvent(kind, isWarning: false)

            case .gameOver(let finalScore, let isNewBest, let impactX, let impactY):
                HapticsManager.shared.error()
                AudioManager.shared.play(isNewBest ? .win : .error)
                playRocketCrashAnimation(
                    shipPos: CGPoint(x: engine.shipX, y: engine.shipY),
                    meteorPos: CGPoint(x: impactX, y: impactY)
                ) { [weak self] in
                    self?.gameDelegate?.sceneDidFinishGame(finalScore: finalScore, isNewBest: isNewBest)
                }
            }
        }
    }

    private func showWarningTelegraph(for kind: RushSpecialEventKind, safeCorridorX: CGFloat?) {
        telegraphLayer.removeAllChildren()
        let topY = size.height - 155.0

        if kind == .twinGate, let safeX = safeCorridorX {
            let safeZone = SKShapeNode(rectOf: CGSize(width: 96, height: 18), cornerRadius: 6)
            safeZone.position = CGPoint(x: safeX, y: topY)
            safeZone.fillColor = RushPixelArt.shared.skColor(hex: 0x22D3EE, alpha: 0.25)
            safeZone.strokeColor = RushPixelArt.shared.skColor(hex: 0x22D3EE, alpha: 0.85)
            safeZone.lineWidth = 2.0
            telegraphLayer.addChild(safeZone)

            let pulse = SKAction.sequence([
                .repeat(.sequence([
                    .fadeAlpha(to: 0.35, duration: 0.18),
                    .fadeAlpha(to: 1.0, duration: 0.18)
                ]), count: 3),
                .fadeOut(withDuration: 0.18),
                .removeFromParent()
            ])
            safeZone.run(pulse)
        } else if kind == .meteorShower {
            let count = 4
            let step = size.width / CGFloat(count + 1)
            for i in 1...count {
                let marker = SKSpriteNode(
                    color: RushPixelArt.shared.skColor(hex: 0xFF2E93, alpha: 0.85),
                    size: CGSize(width: 14, height: 6)
                )
                marker.position = CGPoint(x: step * CGFloat(i), y: topY)
                telegraphLayer.addChild(marker)
                marker.run(.sequence([
                    .repeat(.sequence([
                        .fadeAlpha(to: 0.2, duration: 0.16),
                        .fadeAlpha(to: 0.95, duration: 0.16)
                    ]), count: 3),
                    .fadeOut(withDuration: 0.15),
                    .removeFromParent()
                ]))
            }
        }
    }

    // MARK: - Rocket Crash & Meteor Impact Animations

    private func playRocketCrashAnimation(
        shipPos: CGPoint,
        meteorPos: CGPoint,
        completion: @escaping () -> Void
    ) {
        let collisionMid = CGPoint(
            x: (shipPos.x + meteorPos.x) * 0.5,
            y: (shipPos.y + meteorPos.y) * 0.5
        )

        // Hide intact rocket & kick off heavy camera shake
        shipNode.isHidden = true
        triggerScreenShake(intensity: 9.5)

        // 1. Brief Crimson/Orange Impact Flash Overlay across screen
        let flash = SKSpriteNode(
            color: RushPixelArt.shared.skColor(hex: 0xFF2E93, alpha: 0.28),
            size: CGSize(width: max(450, size.width), height: max(950, size.height))
        )
        flash.anchorPoint = .zero
        flash.zPosition = 25
        fxLayer.addChild(flash)
        flash.run(.sequence([
            .fadeOut(withDuration: 0.26),
            .removeFromParent()
        ]))

        // 2. Expanding Shockwave Rings (Bright white core ring + glowing orange outer ring)
        spawnShockwaveRing(at: collisionMid, radius: 14, targetScale: 4.8, colorHex: 0xFFFFFF, lineWidth: 3.0, duration: 0.36)
        spawnShockwaveRing(at: collisionMid, radius: 16, targetScale: 6.2, colorHex: 0xF97316, lineWidth: 2.5, duration: 0.52)

        // 3. Shattered Meteor Chunks flying off from the hit meteor
        let meteorChunkPalette: [UInt] = [0x475569, 0x94A3B8, 0x1E293B, 0xFF2E93]
        for i in 0..<14 {
            let chunkSize = CGFloat((i % 2 == 0) ? 7 : 5)
            let chunk = SKSpriteNode(
                color: RushPixelArt.shared.skColor(hex: meteorChunkPalette[i % meteorChunkPalette.count]),
                size: CGSize(width: chunkSize, height: chunkSize)
            )
            chunk.position = meteorPos
            fxLayer.addChild(chunk)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 35...115)
            let spin = CGFloat.random(in: -8...8)
            chunk.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist - 25, duration: 0.68),
                    .rotate(byAngle: spin, duration: 0.68),
                    .fadeOut(withDuration: 0.68)
                ]),
                .removeFromParent()
            ]))
        }

        // 4. Spinning Broken Rocket Debris Parts (Hull nose, wings, visor)
        let rocketParts: [(color: UInt, w: CGFloat, h: CGFloat, angle: CGFloat)] = [
            (0xF8FAFC, 10, 12, .pi * 0.45),  // White hull nosecone
            (0xFF2E93, 12, 6,  .pi * 0.85),  // Left magenta wing
            (0xFF2E93, 12, 6,  .pi * 0.15),  // Right magenta wing
            (0x22D3EE, 7,  7,  .pi * 0.65),  // Cyan cockpit shard
            (0xF8FAFC, 8,  8,  -.pi * 0.40)  // Aft hull chunk
        ]
        for part in rocketParts {
            let shard = SKSpriteNode(
                color: RushPixelArt.shared.skColor(hex: part.color),
                size: CGSize(width: part.w, height: part.h)
            )
            shard.position = shipPos
            fxLayer.addChild(shard)

            let dist = CGFloat.random(in: 52...110)
            let dx = cos(part.angle) * dist
            let dy = sin(part.angle) * dist - 30
            shard.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.78),
                    .rotate(byAngle: CGFloat.random(in: -10...10), duration: 0.78),
                    .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.43)])
                ]),
                .removeFromParent()
            ]))
        }

        // 5. Fiery Pixel Fireball & Smoke Cloud Plumes
        let firePalette: [UInt] = [0xFEF08A, 0xFFC83D, 0xF97316, 0xFF2E93]
        for i in 0..<26 {
            let pxSize = CGFloat.random(in: 5...9)
            let p = SKSpriteNode(
                color: RushPixelArt.shared.skColor(hex: firePalette[i % firePalette.count]),
                size: CGSize(width: pxSize, height: pxSize)
            )
            p.position = collisionMid
            fxLayer.addChild(p)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 18...92)
            let dur = Double.random(in: 0.32...0.62)
            p.run(.sequence([
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: dur),
                    .scale(to: 0.15, duration: dur),
                    .fadeOut(withDuration: dur)
                ]),
                .removeFromParent()
            ]))
        }

        for i in 0..<10 {
            let sSize = CGFloat.random(in: 8...13)
            let smoke = SKSpriteNode(
                color: RushPixelArt.shared.skColor(hex: (i % 2 == 0) ? 0x64748B : 0x334155, alpha: 0.75),
                size: CGSize(width: sSize, height: sSize)
            )
            smoke.position = CGPoint(
                x: shipPos.x + CGFloat.random(in: -12...12),
                y: shipPos.y + CGFloat.random(in: -12...12)
            )
            fxLayer.addChild(smoke)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 16...55)
            smoke.run(.sequence([
                .wait(forDuration: 0.08),
                .group([
                    .moveBy(x: cos(angle) * dist, y: sin(angle) * dist + 14, duration: 0.72),
                    .scale(to: 1.6, duration: 0.72),
                    .fadeOut(withDuration: 0.72)
                ]),
                .removeFromParent()
            ]))
        }

        // 6. Wait for crash explosion beat before presenting Game Over card
        removeAction(forKey: "crashSequence")
        run(.sequence([
            .wait(forDuration: 0.85),
            .run { completion() }
        ]), withKey: "crashSequence")
    }

    private func playShieldImpactAnimation(at meteorPos: CGPoint) {
        let shipPos = CGPoint(x: engine.shipX, y: engine.shipY)
        triggerScreenShake(intensity: 5.5)

        // Shatter shield aura outward from rocket
        spawnShockwaveRing(at: shipPos, radius: 22, targetScale: 3.4, colorHex: 0x22D3EE, lineWidth: 2.5, duration: 0.34)
        spawnPixelBurst(at: meteorPos, colorHex: 0x22D3EE, count: 16)
        spawnPixelBurst(at: meteorPos, colorHex: 0x94A3B8, count: 10)

        // Brief invulnerability blink on rocket
        shipNode.removeAction(forKey: "shieldBlink")
        shipNode.run(.repeat(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.08),
            .fadeAlpha(to: 1.0, duration: 0.08)
        ]), count: 4), withKey: "shieldBlink")
    }

    private func spawnShockwaveRing(
        at pos: CGPoint,
        radius: CGFloat,
        targetScale: CGFloat,
        colorHex: UInt,
        lineWidth: CGFloat,
        duration: TimeInterval
    ) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = pos
        ring.strokeColor = RushPixelArt.shared.skColor(hex: colorHex, alpha: 0.92)
        ring.fillColor = .clear
        ring.lineWidth = lineWidth
        fxLayer.addChild(ring)

        ring.run(.sequence([
            .group([
                .scale(to: targetScale, duration: duration),
                .fadeOut(withDuration: duration)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnThrusterPixel() {
        let colorHex: UInt = engine.isSlowTimeActive ? 0x22D3EE : 0xFF2E93
        let p = SKSpriteNode(
            color: RushPixelArt.shared.skColor(hex: colorHex, alpha: 0.85),
            size: CGSize(width: 4, height: 4)
        )
        p.position = CGPoint(
            x: engine.shipX + CGFloat.random(in: -3...3),
            y: engine.shipY - 16
        )
        fxLayer.addChild(p)
        p.run(.sequence([
            .group([
                .moveBy(x: CGFloat.random(in: -6...6), y: -26, duration: 0.22),
                .fadeOut(withDuration: 0.22),
                .scale(to: 0.3, duration: 0.22)
            ]),
            .removeFromParent()
        ]))
    }

    private func spawnPixelBurst(at pos: CGPoint, colorHex: UInt, count: Int) {
        let baseColor = RushPixelArt.shared.skColor(hex: colorHex)
        for _ in 0..<count {
            let p = SKSpriteNode(color: baseColor, size: CGSize(width: 5, height: 5))
            p.position = pos
            fxLayer.addChild(p)

            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 18...56)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist

            p.run(.sequence([
                .group([
                    .moveBy(x: dx, y: dy, duration: 0.32),
                    .fadeOut(withDuration: 0.32),
                    .scale(to: 0.2, duration: 0.32)
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnFloatingText(_ text: String, at pos: CGPoint, colorHex: UInt) {
        let label = SKLabelNode(fontNamed: "AvenirNext-Heavy")
        label.text = text
        label.fontSize = 13
        label.fontColor = RushPixelArt.shared.skColor(hex: colorHex)
        label.position = pos
        fxLayer.addChild(label)

        label.run(.sequence([
            .group([
                .moveBy(x: 0, y: 26, duration: 0.55),
                .fadeOut(withDuration: 0.55)
            ]),
            .removeFromParent()
        ]))
    }

    private func triggerScreenShake(intensity: CGFloat) {
        let shake = SKAction.sequence([
            .moveBy(x: -intensity, y: intensity * 0.5, duration: 0.03),
            .moveBy(x: intensity * 2, y: -intensity, duration: 0.03),
            .moveBy(x: -intensity, y: intensity * 0.5, duration: 0.03),
            .move(to: .zero, duration: 0.03)
        ])
        worldNode.run(shake)
    }

    private func syncActiveEffectsCountdown() {
        let active = engine.activeEffects
        if active.isEmpty {
            if !lastReportedEffectSeconds.isEmpty {
                notifyStateChange()
            }
            return
        }

        var didChangeSecond = false
        for effect in active {
            let sec = max(1, Int(ceil(effect.remaining)))
            if lastReportedEffectSeconds[effect.id] != sec {
                didChangeSecond = true
                break
            }
        }

        if didChangeSecond || active.count != lastReportedEffectSeconds.count {
            notifyStateChange()
        }
    }

    private func notifyStateChange() {
        var currentSeconds: [String: Int] = [:]
        for effect in engine.activeEffects {
            currentSeconds[effect.id] = max(1, Int(ceil(effect.remaining)))
        }
        lastReportedEffectSeconds = currentSeconds

        gameDelegate?.sceneDidUpdateState(
            score: engine.score,
            activeEffects: engine.activeEffects
        )
    }
}
