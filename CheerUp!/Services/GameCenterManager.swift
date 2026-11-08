import GameKit
import SwiftUI

// MARK: - Game Center Manager
// Unified leaderboard authentication and score submission for all CheerUp! arcade games.

final class GameCenterManager {
    static let shared = GameCenterManager()

    private(set) var isAuthenticated: Bool = false

    private init() {}

    // MARK: - Leaderboard Identifiers
    func leaderboardID(for game: GameIdentifier) -> String? {
        switch game {
        case .tap:      return "com.gc.CheerUp.tap.endless"
        case .pingPong: return "com.gc.CheerUp.pingpong.endless"
        case .gravity:  return "com.gc.CheerUp.gravity.endless"
        case .rush:     return "com.gc.CheerUp.rush.endless"
        case .wheels:   return nil
        }
    }

    // MARK: - Player Authentication
    func authenticateLocalPlayer() {
        let player = GKLocalPlayer.local
        player.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if player.isAuthenticated {
                    self?.isAuthenticated = true
                } else {
                    self?.isAuthenticated = false
                }

                if let vc = viewController {
                    Self.topViewController()?.present(vc, animated: true)
                }
            }
        }
    }

    // MARK: - Unified Score Submission
    func submitScore(_ score: Int, for game: GameIdentifier) {
        guard score > 0, let id = leaderboardID(for: game) else { return }
        let player = GKLocalPlayer.local
        guard player.isAuthenticated else { return }

        DispatchQueue.global(qos: .utility).async {
            GKLeaderboard.submitScore(score, context: 0, player: player, leaderboardIDs: [id]) { _ in }
        }
    }

    private static func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return nil
        }
        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
