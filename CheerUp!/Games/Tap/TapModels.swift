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
}

enum TapConfettiShape: Int, CaseIterable {
    case ribbon = 0
    case square = 1
    case diamond = 2
}

struct TapPixelParticle: Identifiable {
    let id: UUID = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var rotation: Double
    var vr: Double
    var tilt: Double = 0
    var tiltSpeed: Double = 9.0
    var swayPhase: Double = 0
    var swaySpeed: Double = 7.5
    var swayAmplitude: CGFloat = 26
    var drag: Double = 0.06
    var gravity: CGFloat = 580
    var size: CGFloat
    var aspect: CGFloat = 0.52
    var shape: TapConfettiShape = .ribbon
    var color: Color
    var age: Double = 0
    var lifetime: Double = 1.35
    var opacity: Double = 1.0
}

struct TapBurstRing: Identifiable {
    let id: UUID = UUID()
    let x: CGFloat
    let y: CGFloat
    let color: Color
    var radius: CGFloat = 18
    var maxRadius: CGFloat = 135
    var age: Double = 0
    var duration: Double = 0.36
    var opacity: Double = 0.85
}
