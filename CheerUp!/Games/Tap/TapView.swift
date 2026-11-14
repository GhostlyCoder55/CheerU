import SwiftUI
import Combine

// MARK: - TAP View
// Full native implementation of the CheerUp! game vision:
// Mascot speech bubble stage, instruction card with live countdown bar,
// tactile 3D cube buttons, pixel explosion confetti, and milestone banners.

struct TapView: View {
    let onExit: () -> Void
    @Environment(\.scenePhase) private var scenePhase
    @State private var engine = TapEngine()
    @State private var pausedByScenePhase = false
    @State private var hasStartedSession = false
    private let timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Background: Dark Slate Gradient Palette (#253745 -> #11212D -> #06141B)
            LinearGradient(
                colors: CheerUpColors.Tap.bgGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 12) {
                // Header: Hearts (Lives), Round Pill, Close
                topHeader
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.xs)

                // Stage: App Mascot Cube + Speech Bubble
                mascotStage
                    .padding(.horizontal, Spacing.screenPadding)

                // Instruction Card with Countdown Bar
                instructionCard
                    .padding(.horizontal, Spacing.screenPadding)

                // 2x2 Tactile 3D Cube Grid
                GeometryReader { geo in
                    let side = min((geo.size.width - 48) / 2, (geo.size.height - 48) / 2)

                    VStack(spacing: 14) {
                        HStack(spacing: 14) {
                            if engine.cubeOrder.count > 0 {
                                cubeTile(cube: engine.cubeOrder[0], size: side, in: geo)
                            }
                            if engine.cubeOrder.count > 1 {
                                cubeTile(cube: engine.cubeOrder[1], size: side, in: geo)
                            }
                        }

                        HStack(spacing: 14) {
                            if engine.cubeOrder.count > 2 {
                                cubeTile(cube: engine.cubeOrder[2], size: side, in: geo)
                            }
                            if engine.cubeOrder.count > 3 {
                                cubeTile(cube: engine.cubeOrder[3], size: side, in: geo)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.bottom, 20)
            }

            // Milestone "NEW RULE!" Banner
            if engine.showBanner, let txt = engine.bannerText {
                VStack(spacing: 8) {
                    Text(LanguageManager.shared.tr("NEW RULE!", "NOUVELLE RÈGLE !", "¡NUEVA REGLA!"))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundStyle(CheerUpColors.Tap.red)

                    Text(txt)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(CheerUpColors.deepNavy)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(CheerUpColors.lightGrey)
                        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)
                )
                .rotationEffect(.degrees(-2))
                .padding(.horizontal, 28)
                .transition(.scale.combined(with: .opacity))
            }

            // Canvas: Wheels-style Confetti Explosion
            if !engine.particles.isEmpty {
                Canvas { context, _ in
                    for p in engine.particles {
                        var copy = context
                        copy.opacity = p.opacity
                        copy.translateBy(x: p.x, y: p.y)
                        copy.rotate(by: Angle(degrees: p.rotation))
                        let rect = CGRect(x: -p.size / 2, y: -p.size * 0.325, width: p.size, height: p.size * 0.65)
                        copy.fill(Path(rect), with: .color(p.color))
                    }
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }

            // Game Over Result Overlay
            if engine.isOver {
                GameResultView(
                    gameTitle: "TAP",
                    score: max(0, engine.round - 1),
                    highScore: engine.highScore,
                    accentColor: CheerUpColors.Tap.yellow,
                    onReplay: {
                        engine.startGame()
                    },
                    onExit: onExit,
                    onWatchAdContinue: engine.hasUsedRewardedContinue ? nil : {
                        engine.continueAfterReward()
                    }
                )
            }
        }
        .onAppear {
            guard !hasStartedSession else { return }
            hasStartedSession = true
            engine.startGame()
        }
        .onReceive(timer) { _ in
            guard scenePhase == .active else { return }
            guard !engine.isOver || !engine.particles.isEmpty else { return }
            engine.tick(dt: 0.05)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                if engine.isLive {
                    pausedByScenePhase = true
                    engine.isLive = false
                }
            } else if pausedByScenePhase && !engine.isOver {
                pausedByScenePhase = false
                engine.isLive = true
            } else {
                pausedByScenePhase = false
            }
        }
    }

    // MARK: - Top Header (Exit Button on Left, Hearts on Right)
    private var topHeader: some View {
        HStack(alignment: .center) {
            // Exit Button (Left)
            Button(action: {
                HapticsManager.shared.selection()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.Tap.ink.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(CheerUpColors.Tap.pill)
                    .clipShape(Circle())
            }
            .frame(minWidth: 90, alignment: .leading)

            Spacer()

            // Round Badge Pill (Center)
            Text("\(LanguageManager.shared.tr("Round", "Tour", "Ronda")) \(max(1, engine.round))")
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(CheerUpColors.Tap.ink)
                .padding(.horizontal, 16)
                .padding(.vertical, 5)
                .background(CheerUpColors.Tap.pill)
                .clipShape(Capsule())

            Spacer()

            // Pixel Hearts (Lives) (Right)
            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { i in
                    PixelHeartView(isFilled: i < engine.lives, size: 22)
                }
            }
            .frame(minWidth: 90, alignment: .trailing)
        }
    }

    // MARK: - Mascot Stage & Speech Bubble
    private var mascotStage: some View {
        HStack(spacing: 12) {
            // CheerUp! Mascot Cube (Replaces emoji from HTML)
            CheerUpMascotView(mood: engine.mascotMood, size: 68)

            // Cheery's Speech Bubble
            HStack {
                Text(engine.speechText)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.deepNavy)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .background(
                SpeechBubbleShape()
                    .fill(CheerUpColors.lightGrey)
                    .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 3)
            )
        }
    }

    // MARK: - Instruction Card with Live Countdown Bar
    private var instructionCard: some View {
        VStack(spacing: 8) {
            // Instruction Line with Colored Target Word
            HStack(spacing: 6) {
                Text(engine.instructionPrefix)
                    .font(.system(size: 27, weight: .black, design: .rounded))
                    .foregroundStyle(CheerUpColors.Tap.ink)

                if !engine.instructionWord.isEmpty {
                    Text(engine.instructionWord)
                        .font(.system(size: 27, weight: .black, design: .rounded))
                        .foregroundStyle(engine.instructionColor)
                }
            }
            .minimumScaleFactor(0.65)
            .lineLimit(1)
            .scaleEffect(engine.isPsychAnimation ? 1.08 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: engine.isPsychAnimation)

            // Tag / Subtext
            if !engine.instructionTag.isEmpty {
                Text(engine.instructionTag)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(CheerUpColors.Tap.yellow)
                    .frame(height: 16)
            } else {
                Spacer().frame(height: 16)
            }

            // Countdown Progress Bar
            GeometryReader { barGeo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .frame(height: 10)

                    Capsule()
                        .fill(engine.progress < 0.3 ? CheerUpColors.Tap.red : CheerUpColors.Tap.yellow)
                        .frame(width: max(0, barGeo.size.width * CGFloat(engine.progress)), height: 10)
                }
            }
            .frame(height: 10)
            .padding(.horizontal, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 110)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(CheerUpColors.Tap.panel)
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - 3D Tactile Cube Button
    private func cubeTile(cube: TapCube, size: CGFloat, in geo: GeometryProxy) -> some View {
        Button(action: {
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            engine.selectCube(cube, tapPoint: center)
        }) {
            ZStack {
                // Bottom 3D shadow block
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .offset(y: 7)

                // Main vibrant cube face
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(cube.color)
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1.5)
                    )
            }
            .frame(width: size, height: size)
        }
        .buttonStyle(CubeButtonStyle())
        .accessibilityLabel("\(cube.name) cube")
    }
}

// MARK: - Speech Bubble Shape (Rounded with left pointer)
struct SpeechBubbleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r: CGFloat = 16
        path.addRoundedRect(in: CGRect(x: 4, y: 0, width: rect.width - 4, height: rect.height), cornerSize: CGSize(width: r, height: r))
        // Pointer tail toward mascot
        path.move(to: CGPoint(x: 4, y: rect.midY - 6))
        path.addLine(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: 4, y: rect.midY + 6))
        path.closeSubpath()
        return path
    }
}

// MARK: - 3D Cube Press Button Style
struct CubeButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 6 : 0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
