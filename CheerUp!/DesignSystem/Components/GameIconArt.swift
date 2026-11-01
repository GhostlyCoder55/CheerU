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
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - 1. TAP Icon: Tactile CheerUp! Mascot Cube with Sparkles
    private var tapIconArtwork: some View {
        ZStack {
            // Mascot Cube Background
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x00A896), Color(hex: 0x028090)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.78, height: size * 0.78)
                .shadow(color: Color(hex: 0x00A896).opacity(0.4), radius: 6, x: 0, y: 3)

            // Top specular shine
            RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                .fill(Color.white.opacity(0.25))
                .frame(width: size * 0.22, height: size * 0.12)
                .offset(x: size * 0.20, y: -size * 0.24)

            // Mascot Face: Two vertical rectangular pill eyes & smile
            VStack(spacing: size * 0.08) {
                HStack(spacing: size * 0.12) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                        .frame(width: size * 0.10, height: size * 0.22)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                        .frame(width: size * 0.10, height: size * 0.22)
                }

                // Square smile path
                MascotSmileShape()
                    .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .square, lineJoin: .miter))
                    .frame(width: size * 0.32, height: size * 0.12)
            }
            .offset(y: size * 0.02)
        }
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
}

// MARK: - Mascot Smile Shape
struct MascotSmileShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
