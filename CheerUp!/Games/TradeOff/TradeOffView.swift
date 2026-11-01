import SwiftUI

// MARK: - THE TRADE OFF View
// An Interactive Constraint Visualizer based directly on theTradeOff.html
// Demonstrates the timeless project triangle: Fast, Good, Cheap — pick two.

struct TradeOffView: View {
    let onExit: () -> Void
    @State private var engine = TradeOffEngine()

    var body: some View {
        ZStack {
            // Background
            CheerUpColors.TradeOff.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Navigation Bar
                topBar
                    .padding(.horizontal, Spacing.screenPadding)
                    .padding(.top, Spacing.sm)

                Spacer()

                // Exhibit Header
                VStack(spacing: 8) {
                    Text("THE TRADE OFF")
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.white)
                        .tracking(3)

                    Text("AN INTERACTIVE CONSTRAINT")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .tracking(2)
                }
                .padding(.bottom, 48)

                // The 3 Tactile Switches: FAST, GOOD, CHEAP
                VStack(spacing: 32) {
                    switchRow(value: .fast, isOn: engine.isFast)
                    switchRow(value: .good, isOn: engine.isGood)
                    switchRow(value: .cheap, isOn: engine.isCheap)
                }
                .padding(.horizontal, 36)

                Spacer()

                // Lesson & Philosophical Statement
                VStack(spacing: 12) {
                    Text(engine.statement)
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(Color.white)
                        .tracking(1)

                    Text(engine.lessonDetail)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .frame(minHeight: 44)

                    Divider()
                        .background(Color.white.opacity(0.12))
                        .padding(.horizontal, 48)
                        .padding(.vertical, 4)

                    Text("Choose carefully. One value must always be sacrificed.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundStyle(Color.white.opacity(0.45))
                        .italic()
                }
                .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                HapticsManager.shared.selection()
                onExit()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }

            Spacer()

            Text("VISUALIZER")
                .font(.system(size: 11, weight: .black, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.4))
                .tracking(2)

            Spacer()

            Button(action: {
                HapticsManager.shared.selection()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    engine.reset()
                }
            }) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.white.opacity(0.75))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Switch Row
    private func switchRow(value: TradeOffValue, isOn: Bool) -> some View {
        HStack(spacing: 24) {
            // Label
            Text(value.label)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(isOn ? value.activeColor : Color.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)
                .tracking(1.5)
                .animation(.easeInOut(duration: 0.2), value: isOn)

            Spacer()

            // Mechanical Toggle Switch
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.7)) {
                    engine.toggle(value)
                }
            }) {
                ZStack(alignment: isOn ? .trailing : .leading) {
                    // Track
                    Capsule()
                        .fill(isOn ? value.activeColor.opacity(0.25) : Color(hex: 0x2A3038))
                        .frame(width: 84, height: 44)
                        .overlay(
                            Capsule()
                                .stroke(isOn ? value.activeColor.opacity(0.4) : Color.white.opacity(0.1), lineWidth: 1.5)
                        )

                    // Knob
                    Circle()
                        .fill(isOn ? value.activeColor : Color(hex: 0x8B95A2))
                        .frame(width: 38, height: 38)
                        .padding(3)
                        .shadow(color: isOn ? value.activeColor.opacity(0.6) : Color.black.opacity(0.35), radius: isOn ? 10 : 3, x: 0, y: 2)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(isOn ? 0.6 : 0.2), lineWidth: 1)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(value.label) switch, currently \(isOn ? "on" : "off")")
        }
    }
}
