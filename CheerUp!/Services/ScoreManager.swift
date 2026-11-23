import Foundation

// MARK: - Score Persistence
// Uses UserDefaults for simplicity — stores high scores for mini-games.

final class ScoreManager {
    static let shared = ScoreManager()

    private let defaults = UserDefaults.standard
    private let prefix = "cheerup.highscore."
    private var cachedScores: [GameIdentifier: Int] = [:]
    private var recordedChessMatchIDs = Set<UUID>()

    private init() {
        reloadCache()
        NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: defaults,
            queue: nil
        ) { [weak self] _ in
            self?.reloadCache()
        }
    }

    private func reloadCache() {
        for game in GameIdentifier.allCases {
            cachedScores[game] = defaults.integer(forKey: prefix + game.rawValue)
        }
    }

    func highScore(for game: GameIdentifier) -> Int {
        if let cached = cachedScores[game] {
            return cached
        }
        let stored = defaults.integer(forKey: prefix + game.rawValue)
        cachedScores[game] = stored
        return stored
    }

    func updateHighScore(for game: GameIdentifier, score: Int) {
        let current = highScore(for: game)
        if score > current {
            cachedScores[game] = score
            defaults.set(score, forKey: prefix + game.rawValue)
        }
    }

    @discardableResult
    func recordChessOutcome(
        winner: PieceColor?,
        humanColor: PieceColor = .light,
        matchID: UUID? = nil
    ) -> Int {
        let currentWins = highScore(for: .chess)
        if let matchID {
            guard !recordedChessMatchIDs.contains(matchID) else { return currentWins }
            recordedChessMatchIDs.insert(matchID)
        }
        if winner == humanColor {
            let updatedWins = currentWins + 1
            updateHighScore(for: .chess, score: updatedWins)
            GameCenterManager.shared.submitScore(updatedWins, for: .chess)
            return updatedWins
        }
        return currentWins
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
    case chess = "chess"
    case wheels = "wheels"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tap:      return "TAP"
        case .pingPong: return "PING PONG"
        case .gravity:  return "GRAVITY"
        case .rush:     return "RUSH"
        case .chess:    return "CHESS"
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
        case .chess:
            return LanguageManager.shared.tr("Classic • Pixel Strategy", "Classique • Stratégie Pixel", "Clásico • Estrategia Píxel")
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
        case .chess:
            return LanguageManager.shared.tr(
                "Play traditional pixel-art chess against three AI levels or race the 3 and 5 minute clocks.",
                "Jouez aux échecs pixel traditionnels contre trois niveaux d'IA ou défiez les horloges de 3 et 5 min.",
                "Juega ajedrez píxel tradicional contra tres niveles de IA o reta los relojes de 3 y 5 minutos."
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
        case .chess:
            return "crown.fill"
        case .wheels:
            return "slider.horizontal.3"
        }
    }

    var isGame: Bool {
        switch self {
        case .tap, .pingPong, .gravity, .rush, .chess: return true
        case .wheels: return false
        }
    }
}
