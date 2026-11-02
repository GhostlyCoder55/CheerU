import SwiftUI

// MARK: - Centralized Color System
// All colors for CheerUp! Arcade are defined here.

enum CheerUpColors {

    // MARK: Main App Palette (Dark Slate Gradient)
    static let deepNavy      = Color(hex: 0x06141B) // #06141B
    static let darkBlue      = Color(hex: 0x11212D) // #11212D
    static let blueGrey      = Color(hex: 0x253745) // #253745
    static let slate         = Color(hex: 0x4A5C6A) // #4A5C6A
    static let mutedSilver   = Color(hex: 0x9BA8AB) // #9BA8AB
    static let lightGrey     = Color(hex: 0xCCD0CF) // #CCD0CF

    // Official Unified Background Gradient for all Games & Exhibits
    static let backgroundGradient: [Color] = [
        Color(hex: 0x253745),
        Color(hex: 0x11212D),
        Color(hex: 0x06141B)
    ]

    // MARK: - Tap Palette (Authentic CheerUp! Cube Colors & Slate Theme)
    enum Tap {
        // Authentic Cube Colors
        static let red    = Color(hex: 0xFF4B5C) // #ff4b5c
        static let blue   = Color(hex: 0x3D7BFF) // #3d7bff
        static let green  = Color(hex: 0x2EDB8A) // #2edb8a
        static let yellow = Color(hex: 0xFFC83D) // #ffc83d

        // Gradient & Surfaces from provided Palette
        static let bgGradient: [Color] = CheerUpColors.backgroundGradient
        static let bg    = Color(hex: 0x06141B)
        static let panel = Color(hex: 0x11212D) // Dark blue slate panel
        static let pill  = Color(hex: 0x253745) // Slate accent pill
        static let ink   = Color(hex: 0xCCD0CF) // Light silver grey text

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

        static let trackOff = Color(hex: 0x253745)
        static let trackOn  = Color(hex: 0x4A5C6A)
        static let knobOff  = Color(hex: 0x9BA8AB)
        static let knobOn   = Color(hex: 0xCCD0CF)

        static let background  = Color(hex: 0x06141B)
        static let surfaceCard = Color(hex: 0x11212D)
    }

    // MARK: - Wheels Palette (Happy & Chaos Wheel)
    enum Wheels {
        static let orange   = Color(hex: 0xF4470B)
        static let amber    = Color(hex: 0xF7BD18)
        static let teal     = Color(hex: 0x00919B)
        static let purple   = Color(hex: 0x7500C8)
        static let crimson  = Color(hex: 0xDF2955)
        static let blue     = Color(hex: 0x3B82F6)
        static let green    = Color(hex: 0x22C55E)
        static let pink     = Color(hex: 0xFF7AB6)
        static let gold     = Color(hex: 0xFFC400)

        static let darkNavy = Color(hex: 0x06141B)
        static let cardBg   = Color(hex: 0x11212D)
        static let pointer  = Color(hex: 0x06141B)

        static let segmentColors: [Color] = [
            Color(hex: 0xF4470B), Color(hex: 0xA85400), Color(hex: 0xF7BD18),
            Color(hex: 0x00919B), Color(hex: 0xF58311), Color(hex: 0x7500C8),
            Color(hex: 0xDF2955), Color(hex: 0x005C66), Color(hex: 0xA6AB00),
            Color(hex: 0xFF7AB6), Color(hex: 0x3B82F6), Color(hex: 0x22C55E)
        ]
    }

    // MARK: - Game Gradients
    enum GameGradient {
        static let tap: [Color] = [
            Color(hex: 0xB0D7D8), Color(hex: 0xF7CBCA)
        ]
        static let tradeOff: [Color] = [
            Color(hex: 0x66BB6A), Color(hex: 0x42A5F5)
        ]
        static let wheels: [Color] = [
            Color(hex: 0xF4470B), Color(hex: 0x7500C8)
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
