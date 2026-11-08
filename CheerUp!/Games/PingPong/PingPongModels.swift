import SwiftUI
import GameKit

// MARK: - Ping Pong Models & Types
// Modular data structures for CheerUp! Arcade – Ping Pong.

enum PingPongMode: String, CaseIterable, Identifiable {
    case endless = "endless"
    case classic = "classic"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .endless:
            return LanguageManager.shared.tr("ENDLESS CHALLENGE", "DÉFI SANS FIN", "RETO SIN FIN")
        case .classic:
            return LanguageManager.shared.tr("CLASSIC ARCADE", "ARCADE CLASSIQUE", "CLÁSICO ARCADE")
        }
    }

    var shortTitle: String {
        switch self {
        case .endless:
            return LanguageManager.shared.tr("Endless", "Sans Fin", "Sin Fin")
        case .classic:
            return LanguageManager.shared.tr("Classic (First to 7)", "Classique (7 pts)", "Clásico (a 7 pts)")
        }
    }

    var targetScore: Int {
        switch self {
        case .endless: return 999999
        case .classic: return 7
        }
    }
}

enum PingPongPowerUpType: String, CaseIterable, Identifiable {
    case giantPaddle = "giantPaddle"
    case speedBoost  = "speedBoost"
    case slowMotion  = "slowMotion"
    case stickyPaddle = "stickyPaddle"
    case doublePoints = "doublePoints"
    case shield       = "shield"
    case chaosBall    = "chaosBall"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .giantPaddle:
            return LanguageManager.shared.tr("GIANT PADDLE", "RAQUETTE GÉANTE", "PALA GIGANTE")
        case .speedBoost:
            return LanguageManager.shared.tr("SPEED BOOST", "TURBO VITESSE", "TURBO VELOCIDAD")
        case .slowMotion:
            return LanguageManager.shared.tr("SLOW MOTION", "RALENTI", "CÁMARA LENTA")
        case .stickyPaddle:
            return LanguageManager.shared.tr("STICKY PADDLE", "RAQUETTE AIMANT", "PALA IMÁN")
        case .doublePoints:
            return LanguageManager.shared.tr("2X POINTS", "POINTS DOUBLÉS", "PUNTOS DOBLES")
        case .shield:
            return LanguageManager.shared.tr("SHIELD", "BOUCLIER", "ESCUDO")
        case .chaosBall:
            return LanguageManager.shared.tr("CHAOS BALL", "BALLE CHAOS", "BOLA CAOS")
        }
    }

    var shortBadge: String {
        switch self {
        case .giantPaddle:  return "WIDE"
        case .speedBoost:   return "FAST"
        case .slowMotion:   return "SLOW"
        case .stickyPaddle: return "STICKY"
        case .doublePoints: return "2X PTS"
        case .shield:       return "SHIELD"
        case .chaosBall:    return "CHAOS"
        }
    }

    var duration: Double {
        switch self {
        case .giantPaddle:  return 8.5
        case .speedBoost:   return 6.5
        case .slowMotion:   return 6.0
        case .stickyPaddle: return 8.0
        case .doublePoints: return 10.0
        case .shield:       return 14.0
        case .chaosBall:    return 7.0
        }
    }

    var color: Color {
        switch self {
        case .giantPaddle:  return Color(hex: 0x2EDB8A) // Emerald Green
        case .speedBoost:   return Color(hex: 0xFF4B5C) // Crimson Red
        case .slowMotion:   return Color(hex: 0x3D7BFF) // Electric Blue
        case .stickyPaddle: return Color(hex: 0xFFC83D) // Amber Gold
        case .doublePoints: return Color(hex: 0xFF7AB6) // Neon Pink
        case .shield:       return Color(hex: 0x00D2FF) // Cyan Shield
        case .chaosBall:    return Color(hex: 0xA855F7) // Chaos Purple
        }
    }

    var uiColorHex: UInt {
        switch self {
        case .giantPaddle:  return 0x2EDB8A
        case .speedBoost:   return 0xFF4B5C
        case .slowMotion:   return 0x3D7BFF
        case .stickyPaddle: return 0xFFC83D
        case .doublePoints: return 0xFF7AB6
        case .shield:       return 0x00D2FF
        case .chaosBall:    return 0xA855F7
        }
    }

    /// Disruptive physics power-ups that should not stack conflictingly
    var isPhysicsDisruptive: Bool {
        switch self {
        case .speedBoost, .slowMotion, .chaosBall:
            return true
        default:
            return false
        }
    }
}

struct SpawnedPowerUp: Identifiable, Equatable {
    let id: UUID = UUID()
    let type: PingPongPowerUpType
    var position: CGPoint // In normalized court coordinates (360 x 620)
    let radius: CGFloat = 19.0
    var lifetime: Double = 8.0
    var age: Double = 0.0
}

struct ActivePowerUpState: Identifiable, Equatable {
    var id: String { type.rawValue }
    let type: PingPongPowerUpType
    var remaining: Double
    let totalDuration: Double

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return max(0, min(1, remaining / totalDuration))
    }
}

enum PingPongDifficultyTier: Int, CaseIterable {
    case rookie = 1
    case warmingUp = 2
    case gettingHot = 3
    case blazing = 4
    case chaosMaster = 5
    case unstoppable = 6

    var title: String {
        switch self {
        case .rookie:
            return LanguageManager.shared.tr("ROOKIE", "DÉBUTANT", "NOVATO")
        case .warmingUp:
            return LanguageManager.shared.tr("WARMING UP", "ÉCHAUFFEMENT", "CALENTANDO")
        case .gettingHot:
            return LanguageManager.shared.tr("GETTING HOT", "ÇA CHAUFFE", "EN RACHA")
        case .blazing:
            return LanguageManager.shared.tr("BLAZING", "EXPLOSIF", "ARDIENTE")
        case .chaosMaster:
            return LanguageManager.shared.tr("CHAOS MASTER", "MAÎTRE DU CHAOS", "MAESTRO DEL CAOS")
        case .unstoppable:
            return LanguageManager.shared.tr("UNSTOPPABLE", "INARRÊTABLE", "IMPARABLE")
        }
    }

    static func forScore(_ score: Int, rallyCount: Int) -> PingPongDifficultyTier {
        let metric = score + (rallyCount / 4)
        switch metric {
        case 0..<5:   return .rookie
        case 5..<12:  return .warmingUp
        case 12..<22: return .gettingHot
        case 22..<35: return .blazing
        case 35..<50: return .chaosMaster
        default:      return .unstoppable
        }
    }
}

enum PingPongEvent: Equatable {
    case paddleHit(isPlayer: Bool, position: CGPoint, speed: CGFloat, isSmash: Bool)
    case wallBounce(position: CGPoint)
    case shieldSaved(position: CGPoint)
    case powerUpSpawned(SpawnedPowerUp)
    case powerUpCollected(PingPongPowerUpType, position: CGPoint)
    case playerScored(pointsAdded: Int, newScore: Int, position: CGPoint)
    case cpuScored(newCpuScore: Int, position: CGPoint)
    case callout(text: String, colorHex: UInt)
    case stickyCaught(position: CGPoint)
    case stickyLaunched(position: CGPoint)
    case difficultyIncreased(PingPongDifficultyTier)
    case gameOver(finalScore: Int, playerWon: Bool, isNewBest: Bool)
}

// MARK: - Game Center Leaderboard Integration

final class PingPongGameCenterManager {
    static let shared = PingPongGameCenterManager()
    static let endlessLeaderboardID = "com.gc.CheerUp.pingpong.endless"

    private init() {}

    /// Submit Endless Challenge high score to Game Center if authenticated.
    /// Safe no-op if the player isn't signed into Game Center.
    func submitEndlessScore(_ score: Int) {
        GameCenterManager.shared.submitScore(score, for: .pingPong)
    }
}
