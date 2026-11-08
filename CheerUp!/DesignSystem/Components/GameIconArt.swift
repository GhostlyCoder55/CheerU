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
            case .pingPong:
                pingPongIconArtwork
            case .gravity:
                gravityIconArtwork
            case .rush:
                rushIconArtwork
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

    // MARK: - 1B. PING PONG Icon: Pixel Arcade Paddles, Net & Motion Ball
    private var pingPongIconArtwork: some View {
        ZStack {
            // Mini Table Surface
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color(hex: 0x11212D))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color.white.opacity(0.22), lineWidth: 1.5)
                )
                .frame(width: size * 0.80, height: size * 0.80)

            // Dashed Net
            HStack(spacing: size * 0.04) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: size * 0.08, height: size * 0.03)
                }
            }

            // Top CPU Paddle (Crimson)
            Capsule()
                .fill(Color(hex: 0xFF4B5C))
                .frame(width: size * 0.34, height: size * 0.09)
                .offset(x: size * 0.10, y: -size * 0.25)

            // Bottom Player Paddle (Teal)
            Capsule()
                .fill(Color(hex: 0x00A896))
                .frame(width: size * 0.38, height: size * 0.09)
                .offset(x: -size * 0.08, y: size * 0.25)

            // Pixel Ball Trail + Ball
            Circle()
                .fill(Color(hex: 0xFFC83D).opacity(0.35))
                .frame(width: size * 0.10, height: size * 0.10)
                .offset(x: -size * 0.05, y: size * 0.11)

            Circle()
                .fill(Color(hex: 0xFFC83D))
                .frame(width: size * 0.14, height: size * 0.14)
                .shadow(color: Color(hex: 0xFFC83D).opacity(0.7), radius: 4)
                .offset(x: size * 0.04, y: -size * 0.03)
        }
    }

    // MARK: - 1C. GRAVITY Icon: Enchanted Pixel Serpent & Elemental Motes
    private var gravityIconArtwork: some View {
        ZStack {
            // Enchanted Forest Torus Frame
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color(hex: 0x0B1E15))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color(hex: 0x22D3EE).opacity(0.45), lineWidth: 1.5)
                )
                .frame(width: size * 0.80, height: size * 0.80)

            // Pixel Serpent Body Segments (L-shaped coil)
            let seg = size * 0.15
            Group {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: 0x059669))
                    .frame(width: seg, height: seg)
                    .offset(x: -seg * 1.1, y: seg * 1.1)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: 0x10B981))
                    .frame(width: seg, height: seg)
                    .offset(x: -seg * 1.1, y: 0)

                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: 0x059669))
                    .frame(width: seg, height: seg)
                    .offset(x: -seg * 1.1, y: -seg * 1.1)

                // Serpent Head
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: 0x34D399))
                    .frame(width: seg * 1.12, height: seg * 1.12)
                    .offset(x: 0, y: -seg * 1.1)
            }

            // Glowing Fire & Mystical Wind Motes (same size)
            Circle()
                .fill(Color(hex: 0xF59E0B))
                .frame(width: size * 0.14, height: size * 0.14)
                .shadow(color: Color(hex: 0xF59E0B).opacity(0.8), radius: 5)
                .offset(x: size * 0.19, y: -size * 0.16)

            Circle()
                .fill(Color(hex: 0xA855F7))
                .frame(width: size * 0.14, height: size * 0.14)
                .shadow(color: Color(hex: 0xA855F7).opacity(0.8), radius: 5)
                .offset(x: size * 0.16, y: size * 0.17)
        }
    }

    // MARK: - 2. RUSH Icon: Contained Box with Only the Same Pixel Spaceship Boosting
    private var rushIconArtwork: some View {
        ZStack {
            // Contained Square Box matching TAP, PING PONG, and GRAVITY
            RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                .fill(Color(hex: 0x090D16))
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.18, style: .continuous)
                        .stroke(Color(hex: 0xFF2E93).opacity(0.45), lineWidth: 1.5)
                )
                .frame(width: size * 0.80, height: size * 0.80)

            // Exact same 12-column pixel spaceship from RushScene, boosting with pixel flame plume
            Canvas { context, canvasSize in
                let grid: [String] = [
                    ".....11.....",
                    "....1221....",
                    "....1221....",
                    "...123321...",
                    "..12233221..",
                    ".4122332214.",
                    "441222222144",
                    "411122221114",
                    "11.115511.11",
                    "1...1551...1",
                    "....5665....",
                    "....5665....",
                    ".....55.....",
                    ".....44....."
                ]

                let cols = 12
                let rows = grid.count
                let px = floor(min(canvasSize.width, canvasSize.height) / CGFloat(max(cols, rows)))
                let totalW = px * CGFloat(cols)
                let totalH = px * CGFloat(rows)
                let originX = (canvasSize.width - totalW) * 0.5
                let originY = (canvasSize.height - totalH) * 0.5

                func color(for ch: Character) -> Color? {
                    switch ch {
                    case "1": return Color(hex: 0x0F172A) // Dark outline
                    case "2": return Color(hex: 0xF8FAFC) // Crisp starfighter hull
                    case "3": return Color(hex: 0x22D3EE) // Glowing cyan cockpit visor
                    case "4": return Color(hex: 0xFF2E93) // Neon magenta wing tips & boost spark
                    case "5": return Color(hex: 0xF97316) // Thruster flame outer orange
                    case "6": return Color(hex: 0xFFC83D) // Boosting inner golden core
                    default:  return nil
                    }
                }

                for (r, row) in grid.enumerated() {
                    for (c, ch) in row.enumerated() {
                        guard let fill = color(for: ch) else { continue }
                        let rect = CGRect(
                            x: originX + CGFloat(c) * px,
                            y: originY + CGFloat(r) * px,
                            width: px + 0.35,
                            height: px + 0.35
                        )
                        context.fill(Path(rect), with: .color(fill))
                    }
                }
            }
            .frame(width: size * 0.58, height: size * 0.62)
            .shadow(color: Color(hex: 0xFF2E93).opacity(0.45), radius: 5, y: 2)
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
