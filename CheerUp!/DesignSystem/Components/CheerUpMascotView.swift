import SwiftUI

// MARK: - CheerUp! Mascot View
// Renders the iconic CheerUp! teal rounded cube mascot (from app icon)
// with expressive mood animations (happy, wow, sad).

enum MascotMood {
    case happy
    case wow
    case sad
}

struct CheerUpMascotView: View {
    var mood: MascotMood = .happy
    var size: CGFloat = 68

    @State private var hopOffset: CGFloat = 0
    @State private var wobbleRotation: Double = 0

    var body: some View {
        ZStack {
            // Main Cube Body
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: 0x00A896), Color(hex: 0x028090)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                )
                .shadow(color: Color(hex: 0x00A896).opacity(0.4), radius: 8, x: 0, y: 4)

            // Top-right glossy highlight
            MascotGlossCorner()
                .fill(Color.white.opacity(0.22))
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(x: size * 0.24, y: -size * 0.24)

            // Mascot Face
            VStack(spacing: size * 0.08) {
                // Two Vertical Pill Eyes
                HStack(spacing: size * 0.14) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                        .frame(width: size * 0.10, height: mood == .wow ? size * 0.26 : size * 0.22)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black)
                        .frame(width: size * 0.10, height: mood == .wow ? size * 0.26 : size * 0.22)
                }

                // Smile / Expression
                Group {
                    switch mood {
                    case .happy:
                        MascotSmileShape()
                            .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .square, lineJoin: .miter))
                            .frame(width: size * 0.34, height: size * 0.12)
                    case .wow:
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black, lineWidth: size * 0.08)
                            .frame(width: size * 0.22, height: size * 0.20)
                    case .sad:
                        MascotFrownShape()
                            .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .square, lineJoin: .miter))
                            .frame(width: size * 0.34, height: size * 0.12)
                    }
                }
            }
            .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
        .offset(y: hopOffset)
        .rotationEffect(.degrees(wobbleRotation))
        .onChange(of: mood) { _, newMood in
            triggerMoodAnimation(newMood)
        }
    }

    private func triggerMoodAnimation(_ newMood: MascotMood) {
        switch newMood {
        case .happy, .wow:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                hopOffset = -12
                wobbleRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    hopOffset = 0
                }
            }
        case .sad:
            withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                wobbleRotation = -8
                hopOffset = 4
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.15, dampingFraction: 0.3)) {
                    wobbleRotation = 8
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    wobbleRotation = 0
                    hopOffset = 0
                }
            }
        }
    }
}

// MARK: - Mascot Shapes
struct MascotGlossCorner: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.45, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.45, y: rect.minY + rect.height * 0.45))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.45))
        path.closeSubpath()
        return path
    }
}

struct MascotFrownShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}
