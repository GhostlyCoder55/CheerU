import SpriteKit

/// Pixel-snapped screen shake updated on a ~30Hz cadence so pixel borders never look muddy.
public final class ScreenShake {
    private weak var target: SKNode?
    private let pixelUnit: CGFloat
    private let basePosition: CGPoint
    private var timer: TimeInterval = 0
    private var duration: TimeInterval = 0
    private var strength: CGFloat = 0

    public init(target: SKNode, pixelUnit: CGFloat) {
        self.target = target
        self.pixelUnit = pixelUnit
        self.basePosition = target.position
    }

    public func shake(strength: CGFloat, duration: TimeInterval) {
        guard FXSettings.shakeAllowed, let target else { return }
        let s = max(pixelUnit, strength)
        self.strength = max(self.strength, s)
        self.duration = max(self.duration - self.timer, duration)
        self.timer = 0

        target.removeAction(forKey: "screenShake")
        let stepDuration = 1.0 / 30.0
        let totalSteps = max(1, Int((duration / stepDuration).rounded(.up)))
        var actions: [SKAction] = []
        actions.reserveCapacity(totalSteps + 1)

        for i in 0..<totalSteps {
            let progress = CGFloat(i) / CGFloat(totalSteps)
            let amp = s * (1 - progress)
            let dx = snap(CGFloat.random(in: -amp...amp))
            let dy = snap(CGFloat.random(in: -amp...amp))
            let p = CGPoint(x: basePosition.x + dx, y: basePosition.y + dy)
            actions.append(SKAction.move(to: p, duration: stepDuration))
        }
        actions.append(SKAction.move(to: basePosition, duration: 0.02))
        target.run(.sequence(actions), withKey: "screenShake")
    }

    public func stop() {
        target?.removeAction(forKey: "screenShake")
        target?.position = basePosition
        strength = 0
        duration = 0
        timer = 0
    }

    private func snap(_ v: CGFloat) -> CGFloat {
        (v / pixelUnit).rounded() * pixelUnit
    }
}
