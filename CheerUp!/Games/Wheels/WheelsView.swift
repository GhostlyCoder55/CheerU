import SwiftUI

// MARK: - Wheels View
// The unpredictable Happy & Chaos Wheel experience for CheerUp! Arcade.
// Features a clean 12-segment rotating wheel (no emojis), VSync-synchronized
// quartic ease-out spinning physics, tactile needle ticks, mini CheerUp!
// mascot reactions, and prominent app-aesthetic SPIN controls.

struct WheelsView: View {
    let onExit: () -> Void

    @State private var engine = WheelsEngine()

    var body: some View {
        TimelineView(.animation(paused: !engine.isSpinning && engine.particles.isEmpty && !engine.isTimerActive)) { timeline in
            contentView
                .onChange(of: timeline.date) { _, newDate in
                    engine.update(currentDate: newDate)
                }
        }
    }

    // MARK: - Main Content Hierarchy
    private var contentView: some View {
        ZStack {
            // Background: Dark Slate Gradient Palette (#253745 -> #11212D -> #06141B)
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Top Header (Title & Exit Button)
                topHeader
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.xs)

                // Mascot Stage: Cheery Cube + Speech Bubble
                mascotStage
                    .padding(.horizontal, Spacing.screenPadding)

                Spacer(minLength: 8)

                // Spinning Wheel Stage
                wheelStage
                    .rotationEffect(.degrees(engine.isFlipped ? 180 : 0))
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: engine.isFlipped)

                Spacer(minLength: 12)

                // Bottom Controls: Prominent SPIN Button matching App Aesthetic
                bottomControls
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.bottom, 28)
            }

            // Confetti Particle Explosion Layer
            Canvas { context, _ in
                for p in engine.particles {
                    var copy = context
                    copy.opacity = p.opacity
                    copy.translateBy(x: p.x, y: p.y)
                    copy.rotate(by: Angle(degrees: p.rotation))
                    let rect = CGRect(
                        x: -p.size / 2,
                        y: -p.size * 0.325,
                        width: p.size,
                        height: p.size * 0.65
                    )
                    copy.fill(Path(rect), with: .color(p.color))
                }
            }
            .ignoresSafeArea()
            .allowsHitTesting(false)

            // Result Reveal Overlay Card
            if engine.showResultSheet, let outcome = engine.selectedOutcome {
                resultSheet(outcome: outcome)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .zIndex(20)
            }
        }
    }

    // MARK: - Top Header (Exit Button on Left, Title in Center)
    private var topHeader: some View {
        HStack {
            // Exit Button (Left)
            Button(action: {
                HapticsManager.shared.selection()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(CheerUpColors.lightGrey.opacity(0.9))
                    .frame(width: 36, height: 36)
                    .background(CheerUpColors.blueGrey.opacity(0.6))
                    .clipShape(Circle())
            }

            Spacer()

            // Header Title
            Text("WHEELS")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Color.white)
                .tracking(1.5)

            Spacer()

            // Balance placeholder
            Color.clear
                .frame(width: 36, height: 36)
        }
    }

    // MARK: - Mascot Stage & Speech Bubble
    private var mascotStage: some View {
        HStack(spacing: 12) {
            // CheerUp! Mascot Cube (Mood reactive)
            CheerUpMascotView(mood: engine.mascotMood, size: 64)

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
            .frame(minHeight: 50)
            .background(
                SpeechBubbleShape()
                    .fill(CheerUpColors.lightGrey)
                    .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 3)
            )
        }
    }

    // MARK: - Spinning Wheel Stage
    private var wheelStage: some View {
        GeometryReader { geo in
            let wheelSize = min(geo.size.width - 24, geo.size.height - 24, 340)

            ZStack {
                // Outer Glow & Drop Shadow
                Circle()
                    .fill(Color.black.opacity(0.4))
                    .frame(width: wheelSize + 12, height: wheelSize + 12)
                    .blur(radius: 8)
                    .offset(y: 8)

                // 12-Segment Clean Wheel (Rotates with engine)
                WheelSegmentsView()
                    .frame(width: wheelSize, height: wheelSize)
                    .rotationEffect(.degrees(engine.rotation))

                // Center Metallic / Dark Hub (from Wheels.html)
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CheerUpColors.blueGrey, CheerUpColors.deepNavy],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: wheelSize * 0.16, height: wheelSize * 0.16)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                    )
                    .overlay(
                        // Inner Red Center Jewel Dot
                        Circle()
                            .fill(Color(hex: 0xFF2D55))
                            .frame(width: wheelSize * 0.07, height: wheelSize * 0.07)
                            .shadow(color: Color.black.opacity(0.35), radius: 2)
                    )
                    .shadow(color: Color.black.opacity(0.5), radius: 5)

                // Top Pointer Needle (Fixed at 12 o'clock with tick oscillation)
                WheelPointerNeedle()
                    .frame(width: 36, height: 42)
                    .rotationEffect(.degrees(engine.pointerDeflection), anchor: .top)
                    .offset(y: -wheelSize / 2 + 10)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, y: 2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Bottom Controls: Prominent SPIN Button matching App Aesthetic
    private var bottomControls: some View {
        VStack(spacing: 12) {
            Button(action: {
                engine.spin()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .bold))
                    Text(engine.isSpinning ? LanguageManager.shared.tr("SPINNING...", "EN COURS...") : LanguageManager.shared.tr("SPIN", "TOURNER"))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .tracking(2.0)
                }
                .foregroundStyle(CheerUpColors.deepNavy)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(CheerUpColors.lightGrey)
                .clipShape(Capsule())
                .shadow(
                    color: Color.black.opacity(0.35),
                    radius: 8,
                    x: 0,
                    y: 4
                )
            }
            .disabled(engine.isSpinning)
            .opacity(engine.isSpinning ? 0.6 : 1.0)
            .scaleEffect(engine.isSpinning ? 0.98 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: engine.isSpinning)
        }
    }

    // MARK: - Result Reveal Sheet
    private func resultSheet(outcome: WheelOutcome) -> some View {
        ZStack {
            // Dimmed Backdrop
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    engine.showResultSheet = false
                }

            VStack(spacing: 14) {
                // Big Outcome Emoji
                Text(outcome.emoji)
                    .font(.system(size: 64))
                    .padding(.vertical, 4)

                // Outcome Title
                Text(outcome.title)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundStyle(Color.white)

                // Outcome Description
                Text(outcome.text)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                // Active Challenge Countdown Timer (if present)
                if outcome.timerSeconds != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "timer")
                            .font(.system(size: 18, weight: .bold))
                        Text(engine.countdownRemaining > 0 ? "⏱ \(engine.countdownRemaining)s" : LanguageManager.shared.tr("Done! 🎉", "Fini ! 🎉"))
                            .font(.system(size: 22, weight: .black, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundStyle(CheerUpColors.lightGrey)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.2))
                    .clipShape(Capsule())
                }

                // Mini CheerUp! Mascot Reaction Badge
                CheerUpMascotView(mood: outcome.mood, size: 54)
                    .padding(.top, 4)

                // Prominent "SPIN AGAIN" Button
                Button(action: {
                    engine.spinAgain()
                }) {
                    Text(LanguageManager.shared.tr("SPIN AGAIN", "RETOURNER"))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .tracking(1.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CheerUpColors.blueGrey)
                        .clipShape(Capsule())
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                }
                .padding(.top, 8)
            }
            .padding(24)
            .frame(maxWidth: 340)
            .background(CheerUpColors.darkBlue)
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .stroke(CheerUpColors.blueGrey.opacity(0.35), lineWidth: 1.5)
            )
            .shadow(color: Color.black.opacity(0.5), radius: 24, y: 12)
        }
    }
}

// MARK: - Clean Wheel Segments View (NO EMOJIS)
struct WheelSegmentsView: View {
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let segmentAngle = (2.0 * .pi) / 12.0

            for i in 0..<12 {
                let startAngle = Angle(radians: Double(i) * segmentAngle)
                let endAngle = Angle(radians: Double(i + 1) * segmentAngle)

                // Fill clean wedge arc
                var path = Path()
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: startAngle,
                    endAngle: endAngle,
                    clockwise: false
                )
                path.closeSubpath()

                let color = WheelsData.segments[i].color
                context.fill(path, with: .color(color))

                // Clean white divider stroke between segments
                context.stroke(path, with: .color(Color.white.opacity(0.35)), lineWidth: 2)
            }

            // Outer Circular Rim
            let outerCircle = Path(ellipseIn: CGRect(origin: .zero, size: size))
            context.stroke(
                outerCircle,
                with: .color(CheerUpColors.deepNavy),
                lineWidth: 6
            )
        }
    }
}

// MARK: - Wheel Pointer Needle (Top Indicator from Wheels.html)
struct WheelPointerNeedle: View {
    var body: some View {
        ZStack {
            Path { path in
                path.move(to: CGPoint(x: 18, y: 40)) // Pointy bottom tip
                path.addLine(to: CGPoint(x: 3, y: 8))
                path.addQuadCurve(to: CGPoint(x: 33, y: 8), control: CGPoint(x: 18, y: -4))
                path.closeSubpath()
            }
            .fill(CheerUpColors.deepNavy)
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 18, y: 40))
                    path.addLine(to: CGPoint(x: 3, y: 8))
                    path.addQuadCurve(to: CGPoint(x: 33, y: 8), control: CGPoint(x: 18, y: -4))
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 2)
            )

            // Top pivot screw circle
            Circle()
                .fill(Color(hex: 0x00A896))
                .frame(width: 9, height: 9)
                .offset(y: -10)
        }
    }
}
