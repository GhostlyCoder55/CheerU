import SpriteKit
import UIKit

/// Global toggles and palette definitions for CheerUp! Chess visual effects.
/// Haptics synchronize with `HapticsManager.shared.isEnabled` so the app's
/// Settings screen always controls tactile feedback in Chess too.
public enum FXSettings {
    public static var screenShakeEnabled: Bool = true
    public static var hapticsEnabled: Bool = true
    public static var particlesEnabled: Bool = true
    public static var reduceMotion: Bool = false

    public static var effectiveReduceMotion: Bool {
        reduceMotion || UIAccessibility.isReduceMotionEnabled
    }

    public static var shakeAllowed: Bool { screenShakeEnabled && !effectiveReduceMotion }
    public static var hitstopAllowed: Bool { !effectiveReduceMotion }
    public static var particleScale: CGFloat {
        guard particlesEnabled else { return 0 }
        return effectiveReduceMotion ? 0.3 : 1.0
    }
}

public enum PieceKind: String, CaseIterable, Codable, Hashable, Sendable {
    case pawn, knight, bishop, rook, queen, king

    /// Controls capture punch: shard count, hitstop duration, screen shake intensity.
    public var impact: CGFloat {
        switch self {
        case .pawn:   return 0.65
        case .knight: return 0.90
        case .bishop: return 0.90
        case .rook:   return 1.15
        case .queen:  return 1.45
        case .king:   return 1.60
        }
    }

    public var isSlider: Bool {
        self == .bishop || self == .rook || self == .queen
    }

    /// Standard centipawn-style material weight for captured-tray advantage.
    public var value: Int {
        switch self {
        case .pawn:   return 1
        case .knight: return 3
        case .bishop: return 3
        case .rook:   return 5
        case .queen:  return 9
        case .king:   return 0
        }
    }

    public var fenSymbol: Character {
        switch self {
        case .pawn:   return "P"
        case .knight: return "N"
        case .bishop: return "B"
        case .rook:   return "R"
        case .queen:  return "Q"
        case .king:   return "K"
        }
    }

    public static var promotableKinds: [PieceKind] {
        [.queen, .rook, .bishop, .knight]
    }
}

public enum PieceColor: String, Codable, Hashable, Sendable {
    case light, dark

    public var opponent: PieceColor {
        self == .light ? .dark : .light
    }
}

public enum PixelPalette {
    // Cream (light) piece tones
    public static let creamLight  = UIColor(red: 0.97, green: 0.89, blue: 0.72, alpha: 1)
    public static let creamMid    = UIColor(red: 0.89, green: 0.77, blue: 0.57, alpha: 1)
    public static let creamDark   = UIColor(red: 0.72, green: 0.56, blue: 0.36, alpha: 1)

    // Brown (dark) piece tones
    public static let brownLight  = UIColor(red: 0.56, green: 0.35, blue: 0.24, alpha: 1)
    public static let brownMid    = UIColor(red: 0.43, green: 0.26, blue: 0.18, alpha: 1)
    public static let brownDark   = UIColor(red: 0.26, green: 0.14, blue: 0.09, alpha: 1)

    // Outlines, board & highlights
    public static let outline     = UIColor(red: 0.14, green: 0.07, blue: 0.04, alpha: 1)
    public static let boardLight  = UIColor(red: 0.93, green: 0.83, blue: 0.66, alpha: 1) // #EDD3A8
    public static let boardDark   = UIColor(red: 0.48, green: 0.29, blue: 0.18, alpha: 1) // #7B4A2E
    public static let woodFrame   = UIColor(red: 0.27, green: 0.16, blue: 0.11, alpha: 1) // #45291B
    public static let woodBevel   = UIColor(red: 0.43, green: 0.26, blue: 0.16, alpha: 1) // #6E4229

    public static let gold        = UIColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 1)
    public static let goldBright  = UIColor(red: 1.00, green: 0.94, blue: 0.61, alpha: 1)
    public static let moveAmber   = UIColor(red: 0.82, green: 0.62, blue: 0.30, alpha: 1)
    public static let dust        = UIColor(red: 0.82, green: 0.70, blue: 0.54, alpha: 1)
    public static let checkRed    = UIColor(red: 0.86, green: 0.26, blue: 0.22, alpha: 1)

    public static func shardColors(for color: PieceColor) -> [UIColor] {
        switch color {
        case .light: return [creamLight, creamMid, creamDark, outline]
        case .dark:  return [brownLight, brownMid, brownDark, outline]
        }
    }
}

public enum Haptics {
    public static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard FXSettings.hapticsEnabled, HapticsManager.shared.isEnabled else { return }
        switch style {
        case .heavy:
            HapticsManager.shared.heavyImpact()
        case .medium:
            HapticsManager.shared.mediumImpact()
        default:
            HapticsManager.shared.lightTap()
        }
    }

    public static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard FXSettings.hapticsEnabled, HapticsManager.shared.isEnabled else { return }
        switch type {
        case .success:
            HapticsManager.shared.success()
        case .warning:
            HapticsManager.shared.warning()
        case .error:
            HapticsManager.shared.error()
        @unknown default:
            HapticsManager.shared.warning()
        }
    }

    public static func selection() {
        guard FXSettings.hapticsEnabled, HapticsManager.shared.isEnabled else { return }
        HapticsManager.shared.selection()
    }
}

public extension CGPoint {
    static func + (a: CGPoint, b: CGPoint) -> CGPoint {
        CGPoint(x: a.x + b.x, y: a.y + b.y)
    }

    static func - (a: CGPoint, b: CGPoint) -> CGPoint {
        CGPoint(x: a.x - b.x, y: a.y - b.y)
    }
}
