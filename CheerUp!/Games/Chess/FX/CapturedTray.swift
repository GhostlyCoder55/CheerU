import SpriteKit

/// Renders a row of captured mini pieces sorted highest-value-first (Queen -> Rook -> Bishop -> Knight -> Pawn)
/// and reports material advantage. Coordinates directly with `PieceAnimator.capture(attacker:victim:trays:)`.
public final class CapturedTray: SKNode {
    public let capturedColor: PieceColor
    private let iconSize: CGSize
    private let overlap: CGFloat
    private let pixelUnit: CGFloat
    private let iconProvider: (PieceKind, PieceColor) -> SKTexture?

    private var entries: [(kind: PieceKind, node: SKSpriteNode)] = []

    public var materialValue: Int {
        entries.reduce(0) { $0 + $1.kind.value }
    }

    public init(
        capturedColor: PieceColor,
        iconSize: CGSize,
        overlap: CGFloat = 0.6,
        pixelUnit: CGFloat,
        iconProvider: @escaping (PieceKind, PieceColor) -> SKTexture?
    ) {
        self.capturedColor = capturedColor
        self.iconSize = iconSize
        self.overlap = overlap
        self.pixelUnit = pixelUnit
        self.iconProvider = iconProvider
        super.init()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func add(
        _ kind: PieceKind,
        from worldPoint: CGPoint,
        in world: SKNode,
        delay: TimeInterval = 0.08
    ) {
        guard let tex = iconProvider(kind, capturedColor) else { return }
        tex.filteringMode = .nearest

        let flyer = SKSpriteNode(texture: tex, size: iconSize)
        flyer.position = worldPoint
        flyer.zPosition = 85
        world.addChild(flyer)

        let slotNode = SKSpriteNode(texture: tex, size: iconSize)
        slotNode.alpha = 0
        entries.append((kind, slotNode))
        addChild(slotNode)
        relayout(animated: true, excluding: slotNode)

        let destInWorld = convert(slotNode.position, to: world)
        let flyDur: TimeInterval = FXSettings.effectiveReduceMotion ? 0.14 : 0.34

        let mid = CGPoint(
            x: (worldPoint.x + destInWorld.x) * 0.5,
            y: max(worldPoint.y, destInWorld.y) + iconSize.height * 0.65
        )
        let path = CGMutablePath()
        path.move(to: worldPoint)
        path.addQuadCurve(to: destInWorld, control: mid)

        let fly = SKAction.follow(path, asOffset: false, orientToPath: false, duration: flyDur)
        fly.timingMode = .easeInEaseOut

        flyer.run(.sequence([
            .wait(forDuration: delay),
            fly,
            .run { [weak flyer, weak slotNode] in
                flyer?.removeFromParent()
                slotNode?.alpha = 1
                slotNode?.run(.sequence([
                    .scale(to: 1.25, duration: 0.06),
                    .scale(to: 1.0, duration: 0.08)
                ]))
            }
        ]))
    }

    public func restore(_ kinds: [PieceKind]) {
        removeAllChildren()
        entries.removeAll()
        for k in kinds {
            guard let tex = iconProvider(k, capturedColor) else { continue }
            tex.filteringMode = .nearest
            let node = SKSpriteNode(texture: tex, size: iconSize)
            entries.append((k, node))
            addChild(node)
        }
        relayout(animated: false, excluding: nil)
    }

    public func reset() {
        removeAllChildren()
        entries.removeAll()
    }

    private func sortOrder(_ k: PieceKind) -> Int {
        switch k {
        case .queen:  return 0
        case .rook:   return 1
        case .bishop: return 2
        case .knight: return 3
        case .pawn:   return 4
        case .king:   return 5
        }
    }

    private func relayout(animated: Bool, excluding fresh: SKSpriteNode?) {
        entries.sort { sortOrder($0.kind) < sortOrder($1.kind) }
        let step = PixelFX.snap(iconSize.width * overlap, to: pixelUnit)
        for (i, entry) in entries.enumerated() {
            let target = CGPoint(x: CGFloat(i) * step, y: 0)
            entry.node.zPosition = CGFloat(i)
            if animated && entry.node !== fresh {
                entry.node.run(.move(to: target, duration: 0.14))
            } else {
                entry.node.position = target
            }
        }
    }
}
