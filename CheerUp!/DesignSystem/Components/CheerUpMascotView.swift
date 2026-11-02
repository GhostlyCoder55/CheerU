import SwiftUI

// MARK: - CheerUp! Mascot View
// Renders the iconic CheerUp! teal rounded cube mascot (from app icon)
// with expressive mood animations (happy, wow, sad).

enum MascotMood {
    case happy
    case wow
    case sad
    case party
    case sus
    case dizzy
    case gold
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
                        colors: mood == .gold
                            ? [Color(hex: 0xFFD84A), Color(hex: 0xF59E0B)]
                            : [Color(hex: 0x00A896), Color(hex: 0x028090)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                        .stroke(Color.white.opacity(mood == .gold ? 0.45 : 0.18), lineWidth: 1.5)
                )
                .shadow(
                    color: mood == .gold
                        ? Color(hex: 0xF59E0B).opacity(0.55)
                        : Color(hex: 0x00A896).opacity(0.4),
                    radius: mood == .gold ? 12 : 8,
                    x: 0,
                    y: 4
                )

            // Top-right glossy highlight
            MascotGlossCorner()
                .fill(Color.white.opacity(0.22))
                .frame(width: size * 0.32, height: size * 0.32)
                .offset(x: size * 0.24, y: -size * 0.24)

            // Mascot Face
            VStack(spacing: size * 0.08) {
                // Eyes
                eyeView

                // Smile / Expression
                mouthView
            }
            .offset(y: size * 0.02)

            // Accessories: Party Hat or Crown
            if mood == .party {
                partyHat
            } else if mood == .gold {
                goldenCrown
            }
        }
        .frame(width: size, height: size)
        .offset(y: hopOffset)
        .rotationEffect(.degrees(wobbleRotation))
        .onChange(of: mood) { _, newMood in
            triggerMoodAnimation(newMood)
        }
    }

    // MARK: - Eyes View
    @ViewBuilder
    private var eyeView: some View {
        switch mood {
        case .happy, .party, .gold:
            HStack(spacing: size * 0.14) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black)
                    .frame(width: size * 0.10, height: size * 0.22)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black)
                    .frame(width: size * 0.10, height: size * 0.22)
            }
        case .wow:
            HStack(spacing: size * 0.16) {
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .overlay(Circle().fill(Color.white).frame(width: size * 0.06).offset(x: -2, y: -2))
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.18, height: size * 0.18)
                    .overlay(Circle().fill(Color.white).frame(width: size * 0.06).offset(x: -2, y: -2))
            }
        case .sad:
            HStack(spacing: size * 0.14) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black)
                    .frame(width: size * 0.10, height: size * 0.22)
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.black)
                    .frame(width: size * 0.10, height: size * 0.22)
            }
        case .sus:
            HStack(spacing: size * 0.16) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: size * 0.15, height: size * 0.08)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.black)
                    .frame(width: size * 0.15, height: size * 0.08)
            }
        case .dizzy:
            HStack(spacing: size * 0.14) {
                Text("✕")
                    .font(.system(size: size * 0.20, weight: .black))
                    .foregroundStyle(Color.black)
                Text("✕")
                    .font(.system(size: size * 0.20, weight: .black))
                    .foregroundStyle(Color.black)
            }
        }
    }

    // MARK: - Mouth View
    @ViewBuilder
    private var mouthView: some View {
        switch mood {
        case .happy, .party, .gold:
            MascotSmileShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .square, lineJoin: .miter))
                .frame(width: size * 0.34, height: size * 0.12)
        case .wow:
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: size * 0.08)
                .frame(width: size * 0.18, height: size * 0.16)
        case .sad:
            MascotFrownShape()
                .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.09, lineCap: .square, lineJoin: .miter))
                .frame(width: size * 0.34, height: size * 0.12)
        case .sus:
            Rectangle()
                .fill(Color.black)
                .frame(width: size * 0.28, height: size * 0.07)
        case .dizzy:
            MascotWavyMouth()
                .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.08, lineCap: .round))
                .frame(width: size * 0.32, height: size * 0.08)
        }
    }

    // MARK: - Party Hat
    private var partyHat: some View {
        GeometryReader { _ in
            Path { p in
                p.move(to: CGPoint(x: size * 0.5, y: -size * 0.22))
                p.addLine(to: CGPoint(x: size * 0.35, y: 0))
                p.addLine(to: CGPoint(x: size * 0.65, y: 0))
                p.closeSubpath()
            }
            .fill(Color(hex: 0x7500C8))
            .overlay(
                Circle()
                    .fill(Color(hex: 0xFFC400))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .position(x: size * 0.5, y: -size * 0.22)
            )
        }
    }

    // MARK: - Golden Crown
    private var goldenCrown: some View {
        GeometryReader { _ in
            Path { p in
                p.move(to: CGPoint(x: size * 0.25, y: 0))
                p.addLine(to: CGPoint(x: size * 0.20, y: -size * 0.18))
                p.addLine(to: CGPoint(x: size * 0.38, y: -size * 0.08))
                p.addLine(to: CGPoint(x: size * 0.50, y: -size * 0.24))
                p.addLine(to: CGPoint(x: size * 0.62, y: -size * 0.08))
                p.addLine(to: CGPoint(x: size * 0.80, y: -size * 0.18))
                p.addLine(to: CGPoint(x: size * 0.75, y: 0))
                p.closeSubpath()
            }
            .fill(Color(hex: 0xFFD700))
            .shadow(color: Color.black.opacity(0.2), radius: 2, y: 1)
        }
    }

    private func triggerMoodAnimation(_ newMood: MascotMood) {
        switch newMood {
        case .happy, .wow, .party, .gold:
            withAnimation(.spring(response: 0.25, dampingFraction: 0.5)) {
                hopOffset = -12
                wobbleRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    hopOffset = 0
                }
            }
        case .sad, .sus, .dizzy:
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

struct MascotWavyMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addQuadCurve(to: CGPoint(x: rect.midX, y: rect.midY), control: CGPoint(x: rect.minX + rect.width * 0.25, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.midY), control: CGPoint(x: rect.minX + rect.width * 0.75, y: rect.maxY))
        return path
    }
}
