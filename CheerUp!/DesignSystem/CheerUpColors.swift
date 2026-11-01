import SwiftUI

// MARK: - Centralized Color System
// All colors for CheerUp! Arcade are defined here.

enum CheerUpColors {

    // MARK: Main App Palette (Dark)
    static let deepNavy      = Color(hex: 0x06141B)
    static let darkBlue      = Color(hex: 0x11212D)
    static let blueGrey      = Color(hex: 0x253745)
    static let slate         = Color(hex: 0x4A5C6A)
    static let mutedSilver   = Color(hex: 0x9BA8AB)
    static let lightGrey     = Color(hex: 0xCCD0CF)

    // MARK: - Tap Palette (Authentic CheerUp! Cube Colors & Pastel Sky Palette)
    enum Tap {
        // Authentic Cube Colors
        static let red    = Color(hex: 0xFF4B5C) // #ff4b5c
        static let blue   = Color(hex: 0x3D7BFF) // #3d7bff
        static let green  = Color(hex: 0x2EDB8A) // #2edb8a
        static let yellow = Color(hex: 0xFFC83D) // #ffc83d

        // Pastel Palette
        static let softPink       = Color(hex: 0xF7CBCA) // #F7CBCA
        static let taupe          = Color(hex: 0xDDD3D3) // #DDD3D3
        static let iceWhite       = Color(hex: 0xF1F7F7) // #F1F7F7
        static let paleIceBlue    = Color(hex: 0xD5E5E5) // #D5E5E5
        static let softTurquoise  = Color(hex: 0xB0D7D8) // #B0D7D8
        static let slateCharcoal  = Color(hex: 0x5D6B6B) // #5D6B6B

        // Gradient & Surfaces
        static let bgGradient: [Color] = [
            Color(hex: 0xB0D7D8),
            Color(hex: 0xD5E5E5),
            Color(hex: 0xF7CBCA)
        ]
        static let bg    = Color(hex: 0xB0D7D8)
        static let panel = Color(hex: 0x5D6B6B) // High contrast slate panel
        static let ink   = Color(hex: 0xF1F7F7) // Ice white text on slate panel

        struct CubeColor: Identifiable {
            let id: Int
            let name: String
            let color: Color
            let hex: UInt
        }

        static let cubes: [CubeColor] = [
            CubeColor(id: 0, name: "RED", color: red, hex: 0xFF4B5C),
            CubeColor(id: 1, name: "BLUE", color: blue, hex: 0x3D7BFF),
            CubeColor(id: 2, name: "GREEN", color: green, hex: 0x2EDB8A),
            CubeColor(id: 3, name: "YELLOW", color: yellow, hex: 0xFFC83D)
        ]
    }

    // MARK: - Trade Off Palette (Tactile Sliders)
    enum TradeOff {
        static let fast  = Color(hex: 0xEF5350) // Red
        static let good  = Color(hex: 0x66BB6A) // Green
        static let cheap = Color(hex: 0x42A5F5) // Blue

        static let trackOff = Color(hex: 0x2A3038)
        static let trackOn  = Color(hex: 0x3E4753)
        static let knobOff  = Color(hex: 0x8B95A2)
        static let knobOn   = Color(hex: 0xF4F6F8)

        static let background  = Color(hex: 0x0E1217)
        static let surfaceCard = Color(hex: 0x181F28)
    }

    // MARK: - Game Gradients
    enum GameGradient {
        static let tap: [Color] = [
            Color(hex: 0xB0D7D8), Color(hex: 0xF7CBCA)
        ]
        static let tradeOff: [Color] = [
            Color(hex: 0x66BB6A), Color(hex: 0x42A5F5)
        ]
    }
}

// MARK: - Color Hex Initializer
extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: opacity
        )
    }
}
