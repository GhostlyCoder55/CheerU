import SwiftUI

// MARK: - CheerUp! Arcade — App Entry Point

@main
struct CheerUpApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root View with Launch Screen

struct RootView: View {
    @State private var isShowingLaunchScreen = true
    @State private var appState = AppState()

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ArcadeRootView(appState: appState)
                .opacity(isShowingLaunchScreen ? 0 : 1)

            if isShowingLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isShowingLaunchScreen = false
                }
            }
        }
    }
}

// MARK: - Launch Screen

struct LaunchScreenView: View {
    @State private var scale: CGFloat = 0.85
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            Image("AppLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 140, height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                .shadow(color: Color.black.opacity(0.4), radius: 18, x: 0, y: 8)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}

// MARK: - Arcade Root View (Navigation Controller)

struct ArcadeRootView: View {
    @Bindable var appState: AppState

    private let gradients: [GameIdentifier: [Color]] = [
        .tap:      CheerUpColors.GameGradient.tap,
        .tradeOff: CheerUpColors.GameGradient.tradeOff,
        .wheels:   CheerUpColors.GameGradient.wheels,
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if appState.isPlayingGame, let game = appState.selectedGame {
                // Active Gameplay / Exhibit
                gameView(for: game)
                    .transition(.opacity)
            } else if appState.showingIntro, let game = appState.selectedGame {
                // Game / Exhibit Introduction
                GameIntroView(
                    game: game,
                    gradientColors: gradients[game] ?? [],
                    onPlay: { appState.startGame() },
                    onBack: { appState.exitToArcade() }
                )
                .transition(.opacity)
            } else {
                // Arcade home
                ArcadeHomeView(onSelectGame: { game in
                    withAnimation(CheerUpAnimation.fadeMedium) {
                        appState.selectGame(game)
                    }
                })
                .transition(.opacity)
            }
        }
        .animation(CheerUpAnimation.fadeMedium, value: appState.isPlayingGame)
        .animation(CheerUpAnimation.fadeMedium, value: appState.showingIntro)
    }

    @ViewBuilder
    private func gameView(for game: GameIdentifier) -> some View {
        switch game {
        case .tap:
            TapView(onExit: { appState.exitToArcade() })
        case .tradeOff:
            TradeOffView(onExit: { appState.exitToArcade() })
        case .wheels:
            WheelsView(onExit: { appState.exitToArcade() })
        }
    }
}
