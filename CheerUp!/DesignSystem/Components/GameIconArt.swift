import SwiftUI

// MARK: - Game Icon Art
// Custom vector artwork for Tap and Trade Off, matching the bold tactile sticker style.

struct GameIconArt: View {
    let game: GameIdentifier
    let size: CGFloat

    var body: some View {
        ZStack {
            switch game {
            case .tap:
                tapIconArtwork
            case .tradeOff:
                tradeOffIconArtwork
            case .wheels:
                wheelsIconArtwork
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - 1. TAP Icon: Canonical CheerUp! Mascot Cube
    private var tapIconArtwork: some View {
        CheerUpMascotView(mood: .happy, size: size * 0.82)
    }

    // MARK: - 2. TRADE OFF Icon: Dual mechanical sliders with glowing knobs
    private var tradeOffIconArtwork: some View {
        VStack(spacing: size * 0.12) {
            // Slider 1: Fast (Red, ON - right)
            HStack {
                Spacer()
                Circle()
                    .fill(CheerUpColors.TradeOff.fast)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .shadow(color: CheerUpColors.TradeOff.fast.opacity(0.6), radius: 6, x: 0, y: 1)
            }
            .padding(.horizontal, 4)
            .frame(width: size * 0.72, height: size * 0.28)
            .background(
                Capsule()
                    .fill(Color(hex: 0x2A3038))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1.5))
            )

            // Slider 2: Good (Green, ON - right)
            HStack {
                Spacer()
                Circle()
                    .fill(CheerUpColors.TradeOff.good)
                    .frame(width: size * 0.24, height: size * 0.24)
                    .shadow(color: CheerUpColors.TradeOff.good.opacity(0.6), radius: 6, x: 0, y: 1)
            }
            .padding(.horizontal, 4)
            .frame(width: size * 0.72, height: size * 0.28)
            .background(
                Capsule()
                    .fill(Color(hex: 0x2A3038))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1.5))
            )

            // Slider 3: Cheap (Sacrificed / OFF - left)
            HStack {
                Circle()
                    .fill(CheerUpColors.TradeOff.knobOff)
                    .frame(width: size * 0.24, height: size * 0.24)
                Spacer()
            }
            .padding(.horizontal, 4)
            .frame(width: size * 0.72, height: size * 0.28)
            .background(
                Capsule()
                    .fill(Color(hex: 0x1E242B))
                    .overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1.5))
            )
        }
    }

    // MARK: - 3. WHEELS Icon: Miniature Animated Spinning Wheel with Pointer & Hub
    private var wheelsIconArtwork: some View {
        ZStack {
            // Wheel outer shadow
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: size * 0.82, height: size * 0.82)
                .offset(y: size * 0.05)

            // Outer Wheel with Conic Angular Gradient
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(hex: 0xF4470B), Color(hex: 0xF7BD18),
                            Color(hex: 0x00919B), Color(hex: 0x7500C8),
                            Color(hex: 0xDF2955), Color(hex: 0x3B82F6),
                            Color(hex: 0x22C55E), Color(hex: 0xFF7AB6),
                            Color(hex: 0xF4470B)
                        ],
                        center: .center
                    )
                )
                .frame(width: size * 0.80, height: size * 0.80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.35), lineWidth: 2)
                )

            // Inner dark hub
            Circle()
                .fill(Color(hex: 0x242033))
                .frame(width: size * 0.28, height: size * 0.28)
                .overlay(
                    Circle()
                        .fill(Color(hex: 0xFF470B))
                        .frame(width: size * 0.12, height: size * 0.12)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 3)

            // Top Indicator Needle / Pointer
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: size * 0.22))
                .foregroundStyle(Color.white)
                .shadow(color: Color.black.opacity(0.4), radius: 2, y: 1)
                .offset(y: -size * 0.38)
        }
    }
}
