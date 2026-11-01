import Foundation

// MARK: - Score Persistence
// Uses UserDefaults for simplicity — stores high scores for mini-games.

final class ScoreManager {
    static let shared = ScoreManager()

    private let defaults = UserDefaults.standard
    private let prefix = "cheerup.highscore."

    private init() {}

    func highScore(for game: GameIdentifier) -> Int {
        defaults.integer(forKey: prefix + game.rawValue)
    }

    func updateHighScore(for game: GameIdentifier, score: Int) {
        let current = highScore(for: game)
        if score > current {
            defaults.set(score, forKey: prefix + game.rawValue)
        }
    }

    func allHighScores() -> [GameIdentifier: Int] {
        var scores: [GameIdentifier: Int] = [:]
        for game in GameIdentifier.allCases {
            scores[game] = highScore(for: game)
        }
        return scores
    }
}

// MARK: - Game Identifier

enum GameIdentifier: String, CaseIterable, Identifiable {
    case tap = "tap"
    case tradeOff = "tradeOff"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap:      return "TAP"
        case .tradeOff: return "THE TRADE OFF"
        }
    }

    var subtitle: String {
        switch self {
        case .tap:      return "Reflex • Pixel Pop"
        case .tradeOff: return "Visualizer • Interactive Constraint"
        }
    }

    var shortDescription: String {
        switch self {
        case .tap:
            return "Tap the target color tile to trigger a pixel explosion before time runs out."
        case .tradeOff:
            return "Fast, Good, Cheap: Pick two. An interactive constraint demonstrating that one value must always be sacrificed."
        }
    }

    var symbol: String {
        switch self {
        case .tap:      return "hand.tap.fill"
        case .tradeOff: return "slider.horizontal.3"
        }
    }

    var isGame: Bool {
        switch self {
        case .tap: return true
        case .tradeOff: return false
        }
    }
}
