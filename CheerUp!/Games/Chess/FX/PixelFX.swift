import SpriteKit

/// Pooled pixel-snapped particle effects tuned for a flat 2D brown-and-cream chessboard.
public final class PixelFX {
    private static var squareCache: [String: SKTexture] = [:]
    private static var activeCount = 0
    private static let maxActive = 96

    public static func snap(_ v: CGFloat, to unit: CGFloat) -> CGFloat {
        (v / unit).rounded() * unit
    }

    public static func snap(_ p: CGPoint, to unit: CGFloat) -> CGPoint {
        CGPoint(x: snap(p.x, to: unit), y: snap(p.y, to: unit))
    }

    private static func pixelTexture(color: UIColor) -> SKTexture {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let key = "\(Int(r * 255))-\(Int(g * 255))-\(Int(b * 255))-\(Int(a * 255))"
        if let cached = squareCache[key] { return cached }
        let tex = SKTexture(image: make1x1Image(color))
        tex.filteringMode = .nearest
        squareCache[key] = tex
        return tex
    }

    private static func make1x1Image(_ color: UIColor) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    /// Explodes a captured piece into crisp pixel shards aligned to `pixelUnit`.
    public static func shatter(
        at origin: CGPoint,
        color: PieceColor,
        intensity: CGFloat,
        pixelUnit: CGFloat,
        in parent: SKNode
    ) {
        let scale = FXSettings.particleScale
        guard scale > 0 else { return }

        let count = max(4, Int(round(CGFloat.random(in: 12...18) * intensity * scale)))
        let palette = PixelPalette.shardColors(for: color)

        for i in 0..<count {
            guard activeCount < maxActive else { break }
            activeCount += 1

            let shardColor = palette[i % palette.count]
            let px = (Bool.random() ? 2 : 3) * pixelUnit
            let node = SKSpriteNode(texture: pixelTexture(color: shardColor),
                                    size: CGSize(width: px, height: px))
            node.zPosition = 50
            node.position = snap(origin + CGPoint(x: CGFloat.random(in: -4...4) * pixelUnit,
                                                  y: CGFloat.random(in: -2...6) * pixelUnit),
                                 to: pixelUnit)
            parent.addChild(node)

            let angle = CGFloat.random(in: 0..<(.pi * 2))
            let speed = CGFloat.random(in: 24...66) * pixelUnit * (0.75 + 0.35 * intensity)
            let dx = cos(angle) * speed * 0.42
            let dy = sin(angle) * speed * 0.36 + CGFloat.random(in: 8...22) * pixelUnit
            let drop = CGFloat.random(in: 12...28) * pixelUnit
            let life = TimeInterval.random(in: 0.30...0.48)

            let peak = snap(node.position + CGPoint(x: dx * 0.55, y: dy), to: pixelUnit)
            let rest = snap(node.position + CGPoint(x: dx, y: dy - drop), to: pixelUnit)

            let rise = SKAction.move(to: peak, duration: life * 0.45)
            rise.timingMode = .easeOut
            let fall = SKAction.move(to: rest, duration: life * 0.55)
            fall.timingMode = .easeIn

            let spin: SKAction = Bool.random()
                ? .rotate(byAngle: .pi * 0.5 * (Bool.random() ? 1 : -1), duration: life)
                : .wait(forDuration: life)

            let fade = SKAction.sequence([
                .wait(forDuration: life * 0.65),
                .fadeOut(withDuration: life * 0.35)
            ])

            let done = SKAction.run {
                activeCount = max(0, activeCount - 1)
                node.removeFromParent()
            }

            node.run(.sequence([.group([.sequence([rise, fall]), spin, fade]), done]))
        }
    }

    /// Tiny cream/sand dust puff on piece landings and castling settles.
    public static func dust(at foot: CGPoint, count: Int = 5, pixelUnit: CGFloat, in parent: SKNode) {
        let scale = FXSettings.particleScale
        guard scale > 0 else { return }
        let n = max(2, Int(round(CGFloat(count) * scale)))

        for i in 0..<n {
            guard activeCount < maxActive else { break }
            activeCount += 1

            let px = 2 * pixelUnit
            let node = SKSpriteNode(texture: pixelTexture(color: PixelPalette.dust),
                                    size: CGSize(width: px, height: px))
            node.zPosition = 25
            node.alpha = 0.85
            let side: CGFloat = (i % 2 == 0) ? -1 : 1
            node.position = snap(foot + CGPoint(x: side * CGFloat.random(in: 2...6) * pixelUnit,
                                                y: pixelUnit), to: pixelUnit)
            parent.addChild(node)

            let drift = CGPoint(x: side * CGFloat.random(in: 5...11) * pixelUnit,
                                y: CGFloat.random(in: 3...7) * pixelUnit)
            let dur = TimeInterval.random(in: 0.22...0.34)
            let move = SKAction.move(to: snap(node.position + drift, to: pixelUnit), duration: dur)
            move.timingMode = .easeOut
            let shrink = SKAction.scale(to: 0.25, duration: dur)
            let fade = SKAction.fadeOut(withDuration: dur)
            let done = SKAction.run {
                activeCount = max(0, activeCount - 1)
                node.removeFromParent()
            }
            node.run(.sequence([.group([move, shrink, fade]), done]))
        }
    }

    /// Brief gold pixel cross flash at a capture collision point.
    public static func impactPlus(at p: CGPoint, pixelUnit: CGFloat, in parent: SKNode) {
        guard !FXSettings.effectiveReduceMotion else { return }
        let c = pixelTexture(color: PixelPalette.goldBright)
        let len = 6 * pixelUnit
        let thick = 2 * pixelUnit

        let container = SKNode()
        container.zPosition = 60
        container.position = snap(p, to: pixelUnit)

        let h = SKSpriteNode(texture: c, size: CGSize(width: len, height: thick))
        let v = SKSpriteNode(texture: c, size: CGSize(width: thick, height: len))
        container.addChild(h)
        container.addChild(v)
        parent.addChild(container)

        container.run(.sequence([
            .wait(forDuration: 0.06),
            .group([.fadeOut(withDuration: 0.09), .scale(to: 1.35, duration: 0.09)]),
            .removeFromParent()
        ]))
    }

    /// Subtle sliding pixel swoosh droplets for Bishop diagonal glides and Queen sweeps.
    public static func swooshTrail(
        from start: CGPoint,
        to end: CGPoint,
        color: UIColor,
        pixelUnit: CGFloat,
        duration: TimeInterval,
        in parent: SKNode
    ) {
        let scale = FXSettings.particleScale
        guard scale > 0, !FXSettings.effectiveReduceMotion else { return }

        let steps = max(3, min(7, Int(round(5 * scale))))
        let tex = pixelTexture(color: color)

        for i in 1...steps {
            guard activeCount < maxActive else { break }
            activeCount += 1

            let t = CGFloat(i) / CGFloat(steps + 1)
            let pt = snap(CGPoint(
                x: start.x + (end.x - start.x) * t,
                y: start.y + (end.y - start.y) * t
            ), to: pixelUnit)

            let sizePx = (i % 2 == 0 ? 2 : 3) * pixelUnit
            let dot = SKSpriteNode(texture: tex, size: CGSize(width: sizePx, height: sizePx))
            dot.position = pt
            dot.zPosition = 18
            dot.alpha = 0
            parent.addChild(dot)

            let appearDelay = duration * TimeInterval(t) * 0.85
            let done = SKAction.run {
                activeCount = max(0, activeCount - 1)
                dot.removeFromParent()
            }
            dot.run(.sequence([
                .wait(forDuration: appearDelay),
                .fadeAlpha(to: 0.65, duration: 0.03),
                .group([
                    .fadeOut(withDuration: 0.22),
                    .scale(to: 0.2, duration: 0.22)
                ]),
                done
            ]))
        }
    }

    /// Pixel exclamation mark above a checked king.
    public static func exclamation(above head: CGPoint, pixelUnit: CGFloat, in parent: SKNode) {
        let container = SKNode()
        container.zPosition = 70
        container.position = snap(head, to: pixelUnit)

        let px = pixelUnit
        let body = SKSpriteNode(texture: pixelTexture(color: PixelPalette.checkRed),
                                size: CGSize(width: 2 * px, height: 5 * px))
        body.position = CGPoint(x: 0, y: 4 * px)

        let dot = SKSpriteNode(texture: pixelTexture(color: PixelPalette.goldBright),
                               size: CGSize(width: 2 * px, height: 2 * px))
        dot.position = CGPoint(x: 0, y: 0)

        container.addChild(body)
        container.addChild(dot)
        parent.addChild(container)

        let rise = SKAction.moveBy(x: 0, y: 6 * px, duration: 0.14)
        rise.timingMode = .easeOut
        container.run(.sequence([
            rise,
            .wait(forDuration: 0.35),
            .fadeOut(withDuration: 0.18),
            .removeFromParent()
        ]))
    }

    /// Expanding square pixel ring highlight around a square (check, mate, promotion).
    public static func ring(
        at center: CGPoint,
        tileSize: CGFloat,
        color: UIColor,
        pixelUnit: CGFloat,
        in parent: SKNode
    ) {
        let shape = SKShapeNode(rectOf: CGSize(width: tileSize * 0.92, height: tileSize * 0.92))
        shape.strokeColor = color
        shape.fillColor = .clear
        shape.lineWidth = max(2, 2 * pixelUnit)
        shape.position = snap(center, to: pixelUnit)
        shape.zPosition = 45
        parent.addChild(shape)

        let grow = SKAction.scale(to: 1.32, duration: 0.28)
        grow.timingMode = .easeOut
        shape.run(.sequence([
            .group([grow, .fadeOut(withDuration: 0.28)]),
            .removeFromParent()
        ]))
    }
}
