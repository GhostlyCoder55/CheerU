import SwiftUI

// MARK: - TAP Models
// Models reflecting the CheerUp!.html vision

struct TapCube: Identifiable, Equatable {
    let id: Int // 0: Red, 1: Blue, 2: Green, 3: Yellow
    let name: String
    let color: Color
    let hex: UInt

    static func == (lhs: TapCube, rhs: TapCube) -> Bool {
        lhs.id == rhs.id
    }
}

enum TapRuleType: String {
    case tap = "tap"
    case not = "not"
    case ink = "ink"
    case prev = "prev"
    case lie = "lie"
    case speed = "speed"
}

struct MilestoneInfo {
    let round: Int
    let rule: TapRuleType
    let message: String
}

struct TapPixelParticle: Identifiable {
    let id: UUID = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var size: CGFloat
    var color: Color
    var opacity: Double
}
