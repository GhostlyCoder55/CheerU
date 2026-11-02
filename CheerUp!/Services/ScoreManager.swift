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
    case wheels = "wheels"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap:      return "TAP"
        case .tradeOff: return "TRADE OFF"
        case .wheels:   return "WHEELS"
        }
    }

    var subtitle: String {
        let isFr = LanguageManager.shared.isFrench
        switch self {
        case .tap:      return isFr ? "Réflexes • Vitesse" : "Reflex • Fast Taps"
        case .tradeOff: return isFr ? "Rapide, Bon, Pas cher" : "Fast, Good, Cheap"
        case .wheels:   return isFr ? "Roue Surprise" : "Surprise Wheel"
        }
    }

    var shortDescription: String {
        let isFr = LanguageManager.shared.isFrench
        switch self {
        case .tap:
            return isFr ? "Touchez la bonne couleur à temps." : "Tap the right color before time runs out."
        case .tradeOff:
            return isFr ? "Choisissez deux : Rapide, Bon, Pas cher. Un est sacrifié." : "Pick two: Fast, Good, Cheap. One value is always sacrificed."
        case .wheels:
            return isFr ? "Tournez la roue pour des surprises et défis." : "Spin the wheel for fun surprises and quick challenges."
        }
    }

    var symbol: String {
        switch self {
        case .tap:
            return "hand.tap.fill"
        case .tradeOff, .wheels:
            return "slider.horizontal.3"
        }
    }

    var isGame: Bool {
        switch self {
        case .tap: return true
        case .tradeOff, .wheels: return false
        }
    }
}
