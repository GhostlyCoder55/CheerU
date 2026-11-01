import SwiftUI

// MARK: - Typography System
// Consistent font styles used throughout CheerUp! Arcade.

enum CheerUpFont {
    // MARK: Headings
    static let largeTitle = Font.system(size: 34, weight: .heavy, design: .rounded)
    static let title      = Font.system(size: 28, weight: .heavy, design: .rounded)
    static let title2     = Font.system(size: 24, weight: .bold, design: .rounded)
    static let title3     = Font.system(size: 20, weight: .bold, design: .rounded)

    // MARK: Body
    static let headline   = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body       = Font.system(size: 15, weight: .medium, design: .rounded)
    static let callout    = Font.system(size: 14, weight: .medium, design: .rounded)
    static let caption    = Font.system(size: 12, weight: .semibold, design: .rounded)
    static let caption2   = Font.system(size: 11, weight: .medium, design: .rounded)

    // MARK: Game-specific
    static let scoreDisplay = Font.system(size: 52, weight: .black, design: .rounded)
    static let gameInstruction = Font.system(size: 30, weight: .black, design: .rounded)
    static let gameStat   = Font.system(size: 22, weight: .heavy, design: .rounded)
    static let gameLabel  = Font.system(size: 13, weight: .bold, design: .rounded)
}

// MARK: - Text Style Modifiers

struct GameTitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CheerUpFont.title)
            .foregroundStyle(CheerUpColors.lightGrey)
    }
}

struct GameSubtitleStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(CheerUpFont.body)
            .foregroundStyle(CheerUpColors.mutedSilver)
    }
}

extension View {
    func gameTitle() -> some View { modifier(GameTitleStyle()) }
    func gameSubtitle() -> some View { modifier(GameSubtitleStyle()) }
}
