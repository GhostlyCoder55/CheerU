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

    // MARK: - Tap Palette
    enum Tap {
        static let red    = Color(hex: 0xFF4B5C) // #ff4b5c
        static let blue   = Color(hex: 0x3D7BFF) // #3d7bff
        static let green  = Color(hex: 0x2EDB8A) // #2edb8a
        static let yellow = Color(hex: 0xFFC83D) // #ffc83d

        static let bgGradient: [Color] = CheerUpColors.backgroundGradient
        static let bg    = Color(hex: 0x06141B)
        static let panel = Color(hex: 0x11212D)
        static let pill  = Color(hex: 0x253745)
        static let ink   = Color(hex: 0xCCD0CF)
    }

    // MARK: - Rush Palette (Hyper Light Drifter / Celeste Indie Pixel Palette)
    enum Rush {
        static let magenta = Color(hex: 0xFF2E93)
        static let cyan    = Color(hex: 0x22D3EE)
        static let gold    = Color(hex: 0xFFC83D)
        static let deep    = Color(hex: 0x090D16)
    }

    // MARK: - Wheels Palette
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
    }

    // MARK: - Game Gradients (Unified Luminance & Depth across all Arcade Cards)
    enum GameGradient {
        static let tap: [Color] = [
            Color(hex: 0x73A9AB), Color(hex: 0x9E6B6A)
        ]
        static let pingPong: [Color] = [
            Color(hex: 0x00A896), Color(hex: 0x253745)
        ]
        static let gravity: [Color] = [
            Color(hex: 0x0EA371), Color(hex: 0x163B2C)
        ]
        static let rush: [Color] = [
            Color(hex: 0xFF3396), Color(hex: 0x3D2356)
        ]
        static let wheels: [Color] = [
            Color(hex: 0xF75C22), Color(hex: 0x432357)
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
