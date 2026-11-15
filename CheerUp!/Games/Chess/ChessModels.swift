import Foundation

// MARK: - Board Coordinates

/// Zero-indexed chessboard square where `file` is `0...7` (`a...h`) and `rank` is `0...7` (`1...8`).
struct ChessSquare: Hashable, Codable, Sendable, CustomStringConvertible {
    let file: Int
    let rank: Int

    var isValid: Bool {
        (0..<8).contains(file) && (0..<8).contains(rank)
    }

    /// Standard chess square coloring (`a1` is dark, `h1` is light, `a8` is light).
    var isLightSquare: Bool {
        (file + rank) % 2 == 1
    }

    var algebraic: String {
        guard isValid else { return "??" }
        let fileChar = Character(UnicodeScalar(97 + file)!)
        return "\(fileChar)\(rank + 1)"
    }

    var description: String { algebraic }

    init(file: Int, rank: Int) {
        self.file = file
        self.rank = rank
    }

    init?(algebraic: String) {
        let lower = algebraic.lowercased()
        guard lower.count == 2,
              let fScalar = lower.first?.asciiValue,
              let rScalar = lower.last?.asciiValue,
              fScalar >= 97 && fScalar <= 104,
              rScalar >= 49 && rScalar <= 56 else {
            return nil
        }
        self.file = Int(fScalar - 97)
        self.rank = Int(rScalar - 49)
    }

    func offset(files df: Int, ranks dr: Int) -> ChessSquare? {
        let sq = ChessSquare(file: file + df, rank: rank + dr)
        return sq.isValid ? sq : nil
    }
}

// MARK: - Chess Piece Instance

struct ChessPiece: Equatable, Hashable, Codable, Sendable {
    let id: UUID
    var kind: PieceKind
    let color: PieceColor
    var hasMoved: Bool

    init(id: UUID = UUID(), kind: PieceKind, color: PieceColor, hasMoved: Bool = false) {
        self.id = id
        self.kind = kind
        self.color = color
        self.hasMoved = hasMoved
    }

    var fenCharacter: Character {
        let ch = kind.fenSymbol
        return color == .light ? ch : Character(ch.lowercased())
    }
}

// MARK: - Castling Rights

struct CastlingRights: Equatable, Hashable, Codable, Sendable {
    var whiteKingside: Bool = true
    var whiteQueenside: Bool = true
    var blackKingside: Bool = true
    var blackQueenside: Bool = true

    static let all = CastlingRights()
    static let none = CastlingRights(
        whiteKingside: false,
        whiteQueenside: false,
        blackKingside: false,
        blackQueenside: false
    )

    var fenString: String {
        var out = ""
        if whiteKingside { out.append("K") }
        if whiteQueenside { out.append("Q") }
        if blackKingside { out.append("k") }
        if blackQueenside { out.append("q") }
        return out.isEmpty ? "-" : out
    }
}

// MARK: - Chess Move

struct ChessMove: Equatable, Hashable, Codable, Sendable {
    let from: ChessSquare
    let to: ChessSquare
    let movedPiece: ChessPiece
    let capturedPiece: ChessPiece?
    let capturedSquare: ChessSquare?
    let promotion: PieceKind?
    let isCastlingKingside: Bool
    let isCastlingQueenside: Bool
    let isEnPassant: Bool

    var isCastling: Bool { isCastlingKingside || isCastlingQueenside }
    var isCapture: Bool { capturedPiece != nil }

    var notation: String {
        if isCastlingKingside { return "O-O" }
        if isCastlingQueenside { return "O-O-O" }
        var text = ""
        if movedPiece.kind != .pawn {
            text.append(movedPiece.kind.fenSymbol)
        } else if isCapture {
            text.append(from.algebraic.first!)
        }
        if isCapture { text.append("x") }
        text.append(to.algebraic)
        if let promotion {
            text.append("=\(promotion.fenSymbol)")
        }
        return text
    }
}

// MARK: - Game Status

enum ChessGameStatus: Equatable, Sendable {
    case playing
    case check(PieceColor)
    case checkmate(winner: PieceColor)
    case stalemate
    case drawFiftyMove
    case drawThreefoldRepetition
    case drawInsufficientMaterial
    case timeout(winner: PieceColor)

    var isTerminal: Bool {
        switch self {
        case .playing, .check:
            return false
        case .checkmate, .stalemate, .drawFiftyMove, .drawThreefoldRepetition, .drawInsufficientMaterial, .timeout:
            return true
        }
    }

    var isDraw: Bool {
        switch self {
        case .stalemate, .drawFiftyMove, .drawThreefoldRepetition, .drawInsufficientMaterial:
            return true
        default:
            return false
        }
    }

    var winner: PieceColor? {
        switch self {
        case .checkmate(let w), .timeout(let w):
            return w
        default:
            return nil
        }
    }

    var inCheckColor: PieceColor? {
        if case .check(let color) = self { return color }
        return nil
    }
}

// MARK: - AI Difficulty & Quick Clock Modes

enum ChessDifficulty: String, CaseIterable, Identifiable, Sendable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .beginner:
            return LanguageManager.shared.tr("Beginner", "Débutant", "Principiante")
        case .intermediate:
            return LanguageManager.shared.tr("Intermediate", "Intermédiaire", "Intermedio")
        case .advanced:
            return LanguageManager.shared.tr("Advanced", "Avancé", "Avanzado")
        }
    }

    var shortLabel: String {
        switch self {
        case .beginner:
            return LanguageManager.shared.tr("EASY", "FACILE", "FÁCIL")
        case .intermediate:
            return LanguageManager.shared.tr("MED", "MOYEN", "MEDIO")
        case .advanced:
            return LanguageManager.shared.tr("HARD", "FORT", "DIFÍCIL")
        }
    }
}

enum ChessTimeControl: String, CaseIterable, Identifiable, Sendable {
    case untimed
    case threeMinutes
    case fiveMinutes

    var id: String { rawValue }

    var initialSeconds: TimeInterval? {
        switch self {
        case .untimed:      return nil
        case .threeMinutes: return 180
        case .fiveMinutes:  return 300
        }
    }

    var shortTitle: String {
        switch self {
        case .untimed:
            return LanguageManager.shared.tr("Untimed", "Libre", "Sin reloj")
        case .threeMinutes:
            return "3 Min"
        case .fiveMinutes:
            return "5 Min"
        }
    }
}

// MARK: - Pending Pawn Promotion

struct PendingPromotion: Equatable, Identifiable {
    let id = UUID()
    let from: ChessSquare
    let to: ChessSquare
    let color: PieceColor
    let options: [ChessMove]
}
