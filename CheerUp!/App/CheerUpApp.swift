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
    @Environment(\.scenePhase) private var scenePhase
    @State private var isShowingLaunchScreen = true
    @State private var appState = AppState()
    @State private var languageManager = LanguageManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if !languageManager.hasCompletedLanguageOnboarding {
                LanguageOnboardingView { chosenLanguage in
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        languageManager.selectInitialLanguage(chosenLanguage)
                    }
                }
                .opacity(isShowingLaunchScreen ? 0 : 1)
                .transition(.opacity)
            } else {
                ArcadeRootView(appState: appState)
                    .opacity(isShowingLaunchScreen ? 0 : 1)
                    .transition(.opacity)
            }

            if isShowingLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            GameCenterManager.shared.authenticateLocalPlayer()
            RewardedAdManager.shared.startSDKIfNeeded()
            RewardedAdManager.shared.preloadAllIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isShowingLaunchScreen = false
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard languageManager.hasCompletedLanguageOnboarding else { return }
            if newPhase == .active || newPhase == .background {
                Task {
                    await NotificationManager.shared.refreshScheduleIfNeeded()
                }
            }
        }
    }
}

// MARK: - First-Launch MiniCheerUp! Language Welcome View

struct LanguageOnboardingView: View {
    let onSelectLanguage: (AppLanguage) -> Void

    @State private var mascotMood: MascotMood = .happy
    @State private var appeared = false

    private let options: [(lang: AppLanguage, title: String)] = [
        (.english, "English"),
        (.french,  "Français"),
        (.spanish, "Español")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: CheerUpColors.backgroundGradient,
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: Spacing.xxl) {
                Spacer()

                // MiniCheerUp! Mascot & Speech Bubble
                VStack(spacing: 16) {
                    CheerUpMascotView(mood: mascotMood, size: 96)
                        .scaleEffect(appeared ? 1.0 : 0.6)
                        .opacity(appeared ? 1 : 0)

                    Text("Hi! I'm MiniCheerUp!")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(CheerUpColors.deepNavy)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(CheerUpColors.lightGrey)
                                .shadow(color: Color.black.opacity(0.35), radius: 10, x: 0, y: 5)
                        )
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 15)
                }

                // Language Selection Buttons (English, Français, Español)
                VStack(spacing: 14) {
                    ForEach(options, id: \.lang.id) { item in
                        Button(action: {
                            HapticsManager.shared.selection()
                            AudioManager.shared.play(.pop)
                            mascotMood = .party
                            onSelectLanguage(item.lang)
                        }) {
                            HStack {
                                Text(item.title)
                                    .font(CheerUpFont.title3)
                                    .foregroundStyle(CheerUpColors.lightGrey)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(CheerUpColors.mutedSilver)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .fill(CheerUpColors.darkBlue.opacity(0.9))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                                            .stroke(CheerUpColors.blueGrey.opacity(0.6), lineWidth: 1.5)
                                    )
                            )
                        }
                        .buttonStyle(PressableButtonStyle())
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 25)

                Spacer()
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
                appeared = true
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
        .pingPong: CheerUpColors.GameGradient.pingPong,
        .gravity:  CheerUpColors.GameGradient.gravity,
        .rush:     CheerUpColors.GameGradient.rush,
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
        .task {
            await NotificationManager.shared.requestAuthorizationIfNeeded()
        }
    }

    @ViewBuilder
    private func gameView(for game: GameIdentifier) -> some View {
        switch game {
        case .tap:
            TapView(onExit: { appState.exitToArcade() })
        case .pingPong:
            PingPongView(onExit: { appState.exitToArcade() })
        case .gravity:
            GravityView(onExit: { appState.exitToArcade() })
        case .rush:
            RushView(onExit: { appState.exitToArcade() })
        case .wheels:
            WheelsView(onExit: { appState.exitToArcade() })
        }
    }
}
