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
        switch self {
        case .tap:
            return LanguageManager.shared.tr("Reflex • Fast Taps", "Réflexes • Vitesse", "Reflejos • Velocidad")
        case .tradeOff:
            return LanguageManager.shared.tr("Fast, Good, Cheap", "Rapide, Bon, Pas cher", "Rápido, Bueno, Barato")
        case .wheels:
            return LanguageManager.shared.tr("Surprise Wheel", "Roue Surprise", "Rueda Sorpresa")
        }
    }

    var shortDescription: String {
        switch self {
        case .tap:
            return LanguageManager.shared.tr(
                "Tap the right color before time runs out.",
                "Touchez la bonne couleur à temps.",
                "Toca el color correcto a tiempo."
            )
        case .tradeOff:
            return LanguageManager.shared.tr(
                "Pick two: Fast, Good, Cheap. One value is always sacrificed.",
                "Choisissez deux : Rapide, Bon, Pas cher. Un est sacrifié.",
                "Elige dos: Rápido, Bueno, Barato. Uno se sacrifica siempre."
            )
        case .wheels:
            return LanguageManager.shared.tr(
                "Spin the wheel for fun surprises and quick challenges.",
                "Tournez la roue pour des surprises et défis.",
                "Gira la rueda para sorpresas y retos."
            )
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
