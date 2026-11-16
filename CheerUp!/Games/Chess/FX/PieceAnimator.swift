import SpriteKit

/// Pair a board `SKSpriteNode` with its `PieceKind` and `PieceColor`.
/// **Important**: `node.anchorPoint` MUST be `(0.5, 0)` so squash & stretch stays
/// planted on the bottom-center of its square rather than floating upward.
public struct AnimatedPiece {
    public let node: SKSpriteNode
    public let kind: PieceKind
    public let color: PieceColor

    public init(node: SKSpriteNode, kind: PieceKind, color: PieceColor) {
        self.node = node
        self.kind = kind
        self.color = color
    }
}

/// Orchestrates 2D pixel-art chess animations: distinct movement personalities,
/// castling choreography, promotion transforms, captures with hitstop/shards/shake,
/// check/checkmate alerts, and draw settles.
public final class PieceAnimator {
    internal weak var world: SKNode?
    internal let tileSize: CGFloat
    internal let pixelUnit: CGFloat
    internal let shake: ScreenShake
    internal weak var selectedPieceNode: SKSpriteNode?
    internal var selectionFrameNode: SKSpriteNode?
    internal var dimNode: SKSpriteNode?
    internal var idleBaseY: CGFloat = 0
    internal var idleBaseZ: CGFloat = 12

    /// Offset from a piece's bottom-center `position` to the visual center of its square.
    public var squareCenterOffset: CGPoint
    /// Gold selection frame texture placed over the selected square.
    public var selectionFrameTexture: SKTexture?
    /// Board bounds used to size checkmate / stalemate dim overlays cleanly.
    public var boardFrame: CGRect?

    public init(world: SKNode, tileSize: CGFloat, pixelUnit: CGFloat) {
        self.world = world
        self.tileSize = tileSize
        self.pixelUnit = pixelUnit
        self.shake = ScreenShake(target: world, pixelUnit: pixelUnit)
        self.squareCenterOffset = CGPoint(x: 0, y: tileSize * 0.5)
    }

    // MARK: - Move

    public func move(_ p: AnimatedPiece, to dest: CGPoint, completion: (() -> Void)? = nil) {
        dropSelectionIfNeeded(for: p)
        let n = p.node
        n.removeAction(forKey: "move")
        let baseZ = n.zPosition
        n.zPosition = 40

        let start = n.position
        let distSquares = hypot(dest.x - start.x, dest.y - start.y) / max(1, tileSize)
        let swooshColor = (p.color == .light) ? PixelPalette.creamLight : PixelPalette.goldBright

        if p.kind == .knight {
            // Knight ALWAYS arcs proudly over intervening pieces and lands with dust.
            let dur = FXSettings.effectiveReduceMotion ? 0.14 : 0.28
            let peak = max(tileSize * 0.56, 16 * pixelUnit)
            let rise = arc(from: start, to: dest, peakHeight: peak, duration: dur)
            let tilt = SKAction.sequence([
                .rotate(toAngle: (dest.x >= start.x ? -0.10 : 0.10), duration: dur * 0.35),
                .rotate(toAngle: 0, duration: dur * 0.65)
            ])
            n.run(.sequence([
                .group([rise, tilt]),
                .run { [weak self] in
                    guard let self else { return }
                    n.zPosition = baseZ
                    self.landing(n, squashX: 1.15, squashY: 0.84, dustCount: 6, at: dest)
                    Haptics.impact(.light)
                    completion?()
                }
            ]), withKey: "move")
            return
        }

        if p.kind == .pawn {
            // Pawn makes a nimble forward hop with subtle landing dust.
            let dur = FXSettings.effectiveReduceMotion ? 0.10 : 0.17
            let peak = max(pixelUnit * 3, tileSize * 0.14)
            let hop = arc(from: start, to: dest, peakHeight: peak, duration: dur)
            n.run(.sequence([
                hop,
                .run { [weak self] in
                    guard let self else { return }
                    n.zPosition = baseZ
                    self.landing(n, squashX: 1.07, squashY: 0.93, dustCount: 3, at: dest)
                    Haptics.impact(.light)
                    completion?()
                }
            ]), withKey: "move")
            return
        }

        if p.kind == .rook {
            // Rook glides firmly and lands with heavier grounded squash & dust.
            let dur = FXSettings.effectiveReduceMotion
                ? 0.12
                : TimeInterval(min(0.28, 0.14 + 0.025 * distSquares))
            let slide = SKAction.move(to: dest, duration: dur)
            slide.timingMode = .easeInEaseOut
            let stretch = SKAction.sequence([
                .scaleX(to: 1.06, y: 0.94, duration: dur * 0.25),
                .scaleX(to: 1.0, y: 1.0, duration: dur * 0.75)
            ])
            n.run(.sequence([
                .group([slide, stretch]),
                .run { [weak self] in
                    guard let self else { return }
                    n.zPosition = baseZ
                    self.landing(n, squashX: 1.18, squashY: 0.82, dustCount: 7, at: dest)
                    Haptics.impact(.medium)
                    completion?()
                }
            ]), withKey: "move")
            return
        }

        if p.kind == .bishop || p.kind == .queen {
            // Bishop / Queen glide effortlessly with a subtle pixel swoosh trail.
            let dur = FXSettings.effectiveReduceMotion
                ? 0.12
                : TimeInterval(min(0.30, 0.14 + 0.026 * distSquares))
            if let world, distSquares > 1.1 {
                PixelFX.swooshTrail(
                    from: start + squareCenterOffset,
                    to: dest + squareCenterOffset,
                    color: swooshColor,
                    pixelUnit: pixelUnit,
                    duration: dur,
                    in: world
                )
            }
            let glide = SKAction.move(to: dest, duration: dur)
            glide.timingMode = .easeOut
            let stretch = SKAction.sequence([
                .scaleX(to: 0.95, y: 1.06, duration: dur * 0.3),
                .scaleX(to: 1.0, y: 1.0, duration: dur * 0.7)
            ])
            n.run(.sequence([
                .group([glide, stretch]),
                .run { [weak self] in
                    guard let self else { return }
                    n.zPosition = baseZ
                    self.landing(n, squashX: 1.09, squashY: 0.91, dustCount: 4, at: dest)
                    Haptics.impact(.light)
                    completion?()
                }
            ]), withKey: "move")
            return
        }

        // King: deliberate, measured royal step.
        let dur = FXSettings.effectiveReduceMotion ? 0.12 : 0.21
        let slide = SKAction.move(to: dest, duration: dur)
        slide.timingMode = .easeInEaseOut
        n.run(.sequence([
            slide,
            .run { [weak self] in
                guard let self else { return }
                n.zPosition = baseZ
                self.landing(n, squashX: 1.10, squashY: 0.90, dustCount: 4, at: dest)
                Haptics.impact(.light)
                completion?()
            }
        ]), withKey: "move")
    }

    // MARK: - Coordinated Castling

    public func castle(
        king: AnimatedPiece,
        kingDest: CGPoint,
        rook: AnimatedPiece,
        rookDest: CGPoint,
        completion: (() -> Void)? = nil
    ) {
        dropSelectionIfNeeded(for: king)
        let kNode = king.node
        let rNode = rook.node
        let kBaseZ = kNode.zPosition
        let rBaseZ = rNode.zPosition
        kNode.zPosition = 40
        rNode.zPosition = 42

        let dur = FXSettings.effectiveReduceMotion ? 0.16 : 0.30
        let kSlide = SKAction.move(to: kingDest, duration: dur)
        kSlide.timingMode = .easeInEaseOut

        let rPeak = max(tileSize * 0.36, 10 * pixelUnit)
        let rArc = arc(from: rNode.position, to: rookDest, peakHeight: rPeak, duration: dur)

        let group = DispatchGroup()
        group.enter()
        kNode.run(.sequence([
            kSlide,
            .run { [weak self] in
                guard let self else { group.leave(); return }
                kNode.zPosition = kBaseZ
                self.landing(kNode, squashX: 1.12, squashY: 0.88, dustCount: 4, at: kingDest)
                group.leave()
            }
        ]), withKey: "move")

        group.enter()
        rNode.run(.sequence([
            .wait(forDuration: FXSettings.effectiveReduceMotion ? 0 : 0.04),
            rArc,
            .run { [weak self] in
                guard let self else { group.leave(); return }
                rNode.zPosition = rBaseZ
                self.landing(rNode, squashX: 1.16, squashY: 0.84, dustCount: 6, at: rookDest)
                group.leave()
            }
        ]), withKey: "move")

        group.notify(queue: .main) { [weak self] in
            if let self, let world = self.world {
                PixelFX.ring(
                    at: kingDest + self.squareCenterOffset,
                    tileSize: self.tileSize,
                    color: PixelPalette.goldBright,
                    pixelUnit: self.pixelUnit,
                    in: world
                )
            }
            Haptics.impact(.medium)
            completion?()
        }
    }

    // MARK: - Pawn Promotion Transform

    public func promote(
        _ piece: AnimatedPiece,
        toTexture newTexture: SKTexture,
        completion: (() -> Void)? = nil
    ) {
        let node = piece.node
        newTexture.filteringMode = .nearest
        let center = node.position + squareCenterOffset
        let dur = FXSettings.effectiveReduceMotion ? 0.12 : 0.24

        node.run(.sequence([
            .scaleX(to: 0.82, y: 1.20, duration: dur * 0.35),
            .colorize(with: PixelPalette.goldBright, colorBlendFactor: 0.85, duration: 0.04),
            .run { [weak self] in
                node.texture = newTexture
                if let self, let world = self.world {
                    PixelFX.ring(
                        at: center,
                        tileSize: self.tileSize,
                        color: PixelPalette.gold,
                        pixelUnit: self.pixelUnit,
                        in: world
                    )
                    PixelFX.dust(at: node.position, count: 6, pixelUnit: self.pixelUnit, in: world)
                }
            },
            .colorize(withColorBlendFactor: 0, duration: 0.08),
            .scaleX(to: 1.16, y: 0.86, duration: dur * 0.30),
            .scaleX(to: 1.0, y: 1.0, duration: dur * 0.35),
            .run {
                Haptics.notification(.success)
                completion?()
            }
        ]), withKey: "promote")
    }

    // MARK: - Capture

    public func capture(
        attacker a: AnimatedPiece,
        victim v: AnimatedPiece,
        destination: CGPoint? = nil,
        trays: [CapturedTray] = [],
        completion: (() -> Void)? = nil
    ) {
        dropSelectionIfNeeded(for: a)
        let nA = a.node, nV = v.node
        let start = nA.position, target = destination ?? nV.position
        let impactCenter = target + squareCenterOffset
        let baseZ = nA.zPosition
        nA.zPosition = 45

        let dir = CGPoint(x: target.x - start.x, y: target.y - start.y)
        let len = max(1, hypot(dir.x, dir.y))
        let unit = CGPoint(x: dir.x / len, y: dir.y / len)

        let wind = FXSettings.effectiveReduceMotion ? 0.02 : 0.07
        let lunge = FXSettings.effectiveReduceMotion ? 0.10 : (a.kind == .knight ? 0.24 : 0.14)
        let settle = FXSettings.effectiveReduceMotion ? 0.04 : 0.10

        let pullPos = start - CGPoint(x: unit.x * tileSize * 0.14, y: unit.y * tileSize * 0.14)
        let pullAction = SKAction.move(to: pullPos, duration: wind)
        pullAction.timingMode = .easeOut

        let strikeAction: SKAction
        if a.kind == .knight {
            let peak = max(tileSize * 0.62, 18 * pixelUnit)
            strikeAction = arc(from: pullPos, to: target, peakHeight: peak, duration: lunge)
        } else if a.kind == .pawn {
            let peak = max(pixelUnit * 4, tileSize * 0.18)
            strikeAction = arc(from: pullPos, to: target, peakHeight: peak, duration: lunge)
        } else {
            if let world, (a.kind == .queen || a.kind == .bishop) {
                PixelFX.swooshTrail(
                    from: start + squareCenterOffset,
                    to: impactCenter,
                    color: PixelPalette.goldBright,
                    pixelUnit: pixelUnit,
                    duration: lunge,
                    in: world
                )
            }
            let s = SKAction.move(to: target, duration: lunge)
            s.timingMode = .easeIn
            strikeAction = s
        }

        let impact = SKAction.run { [weak self] in
            guard let self, let world = self.world else { return }

            let intensity = a.kind.impact

            let flash = SKAction.sequence([
                .colorize(with: .white, colorBlendFactor: 0.9, duration: 0.02),
                .wait(forDuration: FXSettings.hitstopAllowed ? 0.045 * TimeInterval(intensity) : 0.01),
                .colorize(withColorBlendFactor: 0, duration: 0.04)
            ])
            nV.run(flash)

            let hitstop = FXSettings.hitstopAllowed ? 0.045 * TimeInterval(intensity) : 0.0
            let dieDelay = max(0.02, hitstop)

            nV.run(.sequence([
                .wait(forDuration: dieDelay),
                .run { [weak self] in
                    guard let self else { return }
                    nV.isHidden = true
                    PixelFX.shatter(at: impactCenter, color: v.color, intensity: intensity,
                                    pixelUnit: self.pixelUnit, in: world)
                    PixelFX.dust(at: target, count: a.kind == .rook ? 8 : 5, pixelUnit: self.pixelUnit, in: world)
                    PixelFX.impactPlus(at: impactCenter, pixelUnit: self.pixelUnit, in: world)
                    if a.kind == .queen {
                        PixelFX.ring(at: impactCenter, tileSize: self.tileSize, color: PixelPalette.goldBright,
                                     pixelUnit: self.pixelUnit, in: world)
                    }
                    self.shake.shake(strength: 2.2 * intensity * self.pixelUnit,
                                     duration: 0.14 * TimeInterval(intensity))
                    Haptics.impact(intensity > 1.1 ? .heavy : .medium)
                    if let tray = trays.first(where: { $0.capturedColor == v.color }) {
                        tray.add(v.kind, from: impactCenter, in: world)
                    }
                },
                .removeFromParent()
            ]))
        }

        let squash = SKAction.sequence([
            .scaleX(to: 1.20, y: 0.80, duration: settle * 0.45),
            .scaleX(to: 1.0, y: 1.0, duration: settle * 0.55)
        ])

        nA.run(.sequence([
            pullAction,
            strikeAction,
            impact,
            squash,
            .run {
                nA.zPosition = baseZ
                completion?()
            }
        ]), withKey: "move")
    }

    // MARK: - Helpers

    internal func arc(from a: CGPoint, to b: CGPoint, peakHeight: CGFloat, duration: TimeInterval) -> SKAction {
        SKAction.customAction(withDuration: duration) { node, elapsed in
            let t = min(1, max(0, CGFloat(elapsed / CGFloat(duration))))
            let ease = t * (2 - t)
            let x = a.x + (b.x - a.x) * ease
            let y = a.y + (b.y - a.y) * ease + 4 * peakHeight * t * (1 - t)
            node.position = CGPoint(x: x, y: y)
        }
    }

    internal func landing(_ n: SKSpriteNode, squashX: CGFloat, squashY: CGFloat, dustCount: Int, at foot: CGPoint) {
        if let world { PixelFX.dust(at: foot, count: dustCount, pixelUnit: pixelUnit, in: world) }
        n.run(.sequence([
            .scaleX(to: squashX, y: squashY, duration: 0.06),
            .scaleX(to: 1.0, y: 1.0, duration: 0.08)
        ]))
    }
}
