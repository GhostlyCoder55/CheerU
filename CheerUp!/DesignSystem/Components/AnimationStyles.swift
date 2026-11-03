import SwiftUI

// MARK: - Shared Animation Styles

enum CheerUpAnimation {
    static let springSnappy = Animation.spring(response: 0.35, dampingFraction: 0.7)
    static let springSoft   = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let fadeQuick    = Animation.easeInOut(duration: 0.2)
    static let fadeMedium   = Animation.easeInOut(duration: 0.4)
    static let fadeSlow     = Animation.easeInOut(duration: 0.6)
}

// MARK: - Pop Scale Effect

struct PopEffect: ViewModifier {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
            }
    }
}

extension View {
    func popIn() -> some View { modifier(PopEffect()) }
}
