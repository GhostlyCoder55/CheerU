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
        // Unified Game Center submission across all games
        GameCenterManager.shared.submitScore(score, for: game)
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
    case pingPong = "pingPong"
    case gravity = "gravity"
    case rush = "rush"
    case wheels = "wheels"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap:      return "TAP"
        case .pingPong: return "PING PONG"
        case .gravity:  return "GRAVITY"
        case .rush:     return "RUSH"
        case .wheels:   return "WHEELS"
        }
    }

    var subtitle: String {
        switch self {
        case .tap:
            return LanguageManager.shared.tr("Reflex • Fast Taps", "Réflexes • Vitesse", "Reflejos • Velocidad")
        case .pingPong:
            return LanguageManager.shared.tr("Arcade • Chaos Rallies", "Arcade • Échanges Chaos", "Arcade • Rallies Caos")
        case .gravity:
            return LanguageManager.shared.tr("Serpent • Shifting World", "Serpent • Monde Mouvant", "Serpiente • Mundo Cambiante")
        case .rush:
            return LanguageManager.shared.tr("Starship • Meteor Dodge", "Vaisseau • Météores", "Nave • Esquiva Meteoros")
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
        case .pingPong:
            return LanguageManager.shared.tr(
                "Fast paced pixel table tennis with wild power ups and endless rallies.",
                "Ping pong pixel ultra rapide avec bonus fous et échanges sans fin.",
                "Ping pong píxel rápido con potenciadores locos y rallies sin fin."
            )
        case .gravity:
            return LanguageManager.shared.tr(
                "Guide an enchanted pixel serpent across a torus world where crossing edges shifts gravity.",
                "Guidez un serpent pixel dans un monde torique où franchir les bords change la gravité.",
                "Guía a una serpiente píxel en un mundo toroidal donde cruzar bordes cambia la gravedad."
            )
        case .rush:
            return LanguageManager.shared.tr(
                "Pilot a tiny pixel starship through endless meteors. Survive longer to score higher!",
                "Pilotez un mini vaisseau pixel à travers les météores. Survivez plus longtemps pour marquer plus !",
                "Pilota una pequeña nave píxel entre meteoros. ¡Sobrevive más tiempo para sumar puntos!"
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
        case .pingPong:
            return "figure.table.tennis"
        case .gravity:
            return "sparkles"
        case .rush:
            return "airplane"
        case .wheels:
            return "slider.horizontal.3"
        }
    }

    var isGame: Bool {
        switch self {
        case .tap, .pingPong, .gravity, .rush: return true
        case .wheels: return false
        }
    }
}
