import SwiftUI

// MARK: - Arcade Home View
// Pure vertical presentation of the arcade mini games and visualizer experiences.

struct ArcadeHomeView: View {
    let onSelectGame: (GameIdentifier) -> Void

    @State private var highScores: [GameIdentifier: Int] = [:]
    @State private var showSettings = false
    @State private var appeared = false

    private let games: [(game: GameIdentifier, gradient: [Color])] = [
        (.tap,      CheerUpColors.GameGradient.tap),
        (.pingPong, CheerUpColors.GameGradient.pingPong),
        (.gravity,  CheerUpColors.GameGradient.gravity),
        (.rush,     CheerUpColors.GameGradient.rush),
        (.wheels,   CheerUpColors.GameGradient.wheels),
        (.chess,    CheerUpColors.GameGradient.chess),
    ]

    var body: some View {
        ZStack {
            // Background: Dark Slate Gradient Palette (#253745 -> #11212D -> #06141B)
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                let totalHeight = geometry.size.height
                // Adaptive spacing & card height so all cards and header fit on a single static screen without scrolling
                let cardSpacing: CGFloat = totalHeight < 700 ? 7 : (totalHeight < 800 ? 8 : 10)
                let headerBottomSpacing: CGFloat = totalHeight < 700 ? 6 : (totalHeight < 800 ? 10 : 12)
                let cardCount = CGFloat(games.count)
                let reserved: CGFloat = 54 + headerBottomSpacing + (cardSpacing * max(0, cardCount - 1)) + 12
                let computedCardHeight: CGFloat = max(68, min(112, (totalHeight - reserved) / max(1, cardCount)))

                VStack(spacing: 0) {
                    header
                        .padding(.bottom, headerBottomSpacing)

                    // Vertical Presentation of Mini Games & Visualizer (100% Static - No scrolling)
                    VStack(spacing: cardSpacing) {
                        ForEach(Array(games.enumerated()), id: \.element.game.id) { index, item in
                            GameCardView(
                                game: item.game,
                                highScore: highScores[item.game] ?? 0,
                                gradientColors: item.gradient,
                                cardHeight: computedCardHeight,
                                onSelect: { onSelectGame(item.game) }
                            )
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 25)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.8)
                                    .delay(Double(index) * 0.08),
                                value: appeared
                            )
                        }
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, Spacing.screenPadding)
                .padding(.top, Spacing.xs)
                .padding(.bottom, Spacing.xs)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(28)
                .presentationBackground {
                    LinearGradient(
                        colors: [CheerUpColors.darkBlue, CheerUpColors.deepNavy],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        }
        .onAppear {
            loadScores()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                appeared = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
            loadScores()
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("CheerUp!")
                    .font(CheerUpFont.largeTitle)
                    .foregroundStyle(CheerUpColors.lightGrey)

                Text(LanguageManager.shared.tr("Your little arcade corner.", "Votre coin d’arcade.", "Tu rincón arcade."))
                    .font(CheerUpFont.body)
                    .foregroundStyle(CheerUpColors.mutedSilver)
            }

            Spacer()

            // Settings button
            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(CheerUpColors.mutedSilver)
                    .frame(width: 40, height: 40)
                    .background(CheerUpColors.blueGrey.opacity(0.4))
                    .clipShape(Circle())
            }
            .accessibilityLabel(LanguageManager.shared.tr("Settings", "Réglages", "Ajustes"))
        }
    }

    private func loadScores() {
        highScores = ScoreManager.shared.allHighScores()
    }
}
