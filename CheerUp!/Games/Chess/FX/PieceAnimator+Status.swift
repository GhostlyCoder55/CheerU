import SpriteKit

extension PieceAnimator {

    // MARK: - Selection

    public func select(_ p: AnimatedPiece, at basePosition: CGPoint? = nil) {
        let n = p.node
        let anchorPos = basePosition ?? (selectedPieceNode === n ? CGPoint(x: n.position.x, y: idleBaseY) : n.position)

        // If this piece is already selected, keep it fixed in place on its square without levitating
        if selectedPieceNode === n {
            n.removeAction(forKey: "select")
            n.position = anchorPos
            n.setScale(1.0)
            if let frame = selectionFrameNode {
                frame.position = PixelFX.snap(anchorPos + squareCenterOffset, to: pixelUnit)
            }
            return
        }

        deselect()
        selectedPieceNode = n
        idleBaseY = anchorPos.y
        idleBaseZ = n.zPosition

        n.removeAction(forKey: "select")
        n.position = anchorPos
        n.zPosition = idleBaseZ + 20

        // Subtle grounded scale feedback while keeping piece position fixed on its square (no levitation)
        n.run(.sequence([
            .scaleX(to: 1.08, y: 0.94, duration: 0.05),
            .scaleX(to: 1.0, y: 1.0, duration: 0.08)
        ]), withKey: "select")

        if let world, let tex = selectionFrameTexture {
            tex.filteringMode = .nearest
            let frame = SKSpriteNode(texture: tex, size: CGSize(width: tileSize, height: tileSize))
            frame.position = PixelFX.snap(anchorPos + squareCenterOffset, to: pixelUnit)
            frame.zPosition = idleBaseZ - 1
            frame.alpha = 0
            world.addChild(frame)
            frame.run(.group([
                .fadeIn(withDuration: 0.10),
                .sequence([.scale(to: 1.06, duration: 0.07), .scale(to: 1.0, duration: 0.07)])
            ]))
            frame.run(.repeatForever(.sequence([
                .fadeAlpha(to: 0.72, duration: 0.45),
                .fadeAlpha(to: 1.0, duration: 0.45)
            ])), withKey: "pulse")
            selectionFrameNode = frame
        }

        Haptics.selection()
    }

    public func deselect() {
        if let frame = selectionFrameNode {
            frame.removeAllActions()
            frame.run(.sequence([.fadeOut(withDuration: 0.08), .removeFromParent()]))
            selectionFrameNode = nil
        }

        guard let n = selectedPieceNode else { return }
        selectedPieceNode = nil
        n.removeAction(forKey: "select")
        n.position.y = idleBaseY
        n.setScale(1.0)
        n.zPosition = idleBaseZ
    }

    internal func dropSelectionIfNeeded(for p: AnimatedPiece) {
        guard p.node === selectedPieceNode else { return }
        if let frame = selectionFrameNode {
            frame.removeAllActions()
            frame.removeFromParent()
            selectionFrameNode = nil
        }
        p.node.removeAction(forKey: "select")
        p.node.position.y = idleBaseY
        p.node.setScale(1.0)
        p.node.zPosition = idleBaseZ
        selectedPieceNode = nil
    }

    // MARK: - Check

    public func check(king: AnimatedPiece, completion: (() -> Void)? = nil) {
        let n = king.node
        let kingCenter = n.position + squareCenterOffset

        let wobble = SKAction.sequence([
            .rotate(toAngle: 0.14, duration: 0.05),
            .rotate(toAngle: -0.14, duration: 0.08),
            .rotate(toAngle: 0.08, duration: 0.07),
            .rotate(toAngle: 0, duration: 0.06)
        ])

        let flash = SKAction.sequence([
            .colorize(with: PixelPalette.checkRed, colorBlendFactor: 0.72, duration: 0.05),
            .colorize(withColorBlendFactor: 0, duration: 0.25)
        ])

        n.removeAction(forKey: "check")
        n.run(.sequence([
            .group([wobble, flash]),
            .run { completion?() }
        ]), withKey: "check")

        if let world {
            let head = CGPoint(x: n.position.x, y: n.position.y + n.size.height + 2 * pixelUnit)
            PixelFX.exclamation(above: head, pixelUnit: pixelUnit, in: world)
            PixelFX.ring(at: kingCenter, tileSize: tileSize, color: PixelPalette.checkRed,
                         pixelUnit: pixelUnit, in: world)
        }

        shake.shake(strength: 2.0 * pixelUnit, duration: 0.16)
        Haptics.notification(.warning)
    }

    // MARK: - Checkmate

    public func checkmate(king: AnimatedPiece, attacker: AnimatedPiece? = nil, completion: (() -> Void)? = nil) {
        deselect()
        let n = king.node
        let kingCenter = n.position + squareCenterOffset
        showDim(belowZ: n.zPosition)

        if let a = attacker {
            a.node.zPosition = n.zPosition - 1
            a.node.run(.sequence([
                .scale(to: 1.12, duration: 0.10),
                .scale(to: 1.0, duration: 0.14)
            ]))
        }

        let dir: CGFloat = (attacker?.node.position.x ?? n.position.x) <= n.position.x ? -1 : 1
        let shakeOut = SKAction.sequence([
            .moveBy(x: 2 * pixelUnit, y: 0, duration: 0.04),
            .moveBy(x: -4 * pixelUnit, y: 0, duration: 0.06),
            .moveBy(x: 2 * pixelUnit, y: 0, duration: 0.04)
        ])

        let toppleDur: TimeInterval = FXSettings.effectiveReduceMotion ? 0.15 : 0.42
        let tilt = SKAction.rotate(toAngle: dir * (.pi * 0.44), duration: toppleDur)
        tilt.timingMode = .easeIn
        let bounce = SKAction.rotate(byAngle: -dir * 0.08, duration: 0.07)
        let settle = SKAction.rotate(byAngle: dir * 0.08, duration: 0.08)

        let slow = FXSettings.effectiveReduceMotion ? 1.0 : 0.72
        world?.run(.sequence([
            .run { [weak self] in self?.world?.speed = slow },
            .wait(forDuration: 0.55),
            .run { [weak self] in self?.world?.speed = 1.0 }
        ]))

        n.removeAction(forKey: "checkmate")
        n.run(.sequence([
            .group([
                shakeOut,
                .colorize(with: PixelPalette.checkRed, colorBlendFactor: 0.55, duration: 0.14)
            ]),
            tilt,
            .run { [weak self] in
                guard let self, let world = self.world else { return }
                PixelFX.dust(at: n.position, count: 8, pixelUnit: self.pixelUnit, in: world)
                PixelFX.ring(at: kingCenter, tileSize: self.tileSize, color: PixelPalette.gold,
                             pixelUnit: self.pixelUnit, in: world)
                self.shake.shake(strength: 4.0 * self.pixelUnit, duration: 0.25)
                Haptics.notification(.error)
            },
            bounce,
            settle,
            .run { completion?() }
        ]), withKey: "checkmate")
    }

    // MARK: - Stalemate / Draw

    public func drawEffect(kings: [AnimatedPiece], completion: (() -> Void)? = nil) {
        deselect()
        showDim(belowZ: 30, alpha: 0.34)
        for k in kings {
            if let world {
                PixelFX.ring(
                    at: k.node.position + squareCenterOffset,
                    tileSize: tileSize,
                    color: PixelPalette.dust,
                    pixelUnit: pixelUnit,
                    in: world
                )
            }
            k.node.run(.sequence([
                .scaleX(to: 1.08, y: 0.92, duration: 0.12),
                .scaleX(to: 1.0, y: 1.0, duration: 0.14)
            ]))
        }
        Haptics.notification(.warning)
        world?.run(.sequence([
            .wait(forDuration: 0.28),
            .run { completion?() }
        ]))
    }

    // MARK: - Dim & Reset

    internal func showDim(belowZ z: CGFloat, alpha: CGFloat = 0.45) {
        guard let world else { return }
        dimNode?.removeFromParent()
        let rect = boardFrame ?? world.calculateAccumulatedFrame()
        let dim = SKSpriteNode(color: PixelPalette.outline, size: rect.size)
        dim.position = CGPoint(x: rect.midX, y: rect.midY)
        dim.zPosition = z - 2
        dim.alpha = 0
        world.addChild(dim)
        dim.run(.fadeAlpha(to: alpha, duration: 0.28))
        dimNode = dim
    }

    public func reset() {
        deselect()
        dimNode?.removeFromParent()
        dimNode = nil
        shake.stop()
        world?.speed = 1.0
    }
}
