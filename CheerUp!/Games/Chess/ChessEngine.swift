import Foundation

// MARK: - Immutable Value-Type Board State & FIDE Rules Engine

struct ChessBoardState: Sendable {
    private(set) var squares: [ChessPiece?]
    private(set) var turn: PieceColor
    private(set) var castlingRights: CastlingRights
    private(set) var enPassantTarget: ChessSquare?
    private(set) var halfMoveClock: Int
    private(set) var fullMoveNumber: Int
    private(set) var capturedByLight: [PieceKind]
    private(set) var capturedByDark: [PieceKind]
    private(set) var lastMove: ChessMove?
    private(set) var status: ChessGameStatus
    private(set) var positionCounts: [String: Int]

    init() {
        self.squares = Array(repeating: nil, count: 64)
        self.turn = .light
        self.castlingRights = .all
        self.enPassantTarget = nil
        self.halfMoveClock = 0
        self.fullMoveNumber = 1
        self.capturedByLight = []
        self.capturedByDark = []
        self.lastMove = nil
        self.status = .playing
        self.positionCounts = [:]
        setupStandardBoard()
        let key = repetitionKey()
        self.positionCounts[key] = 1
        refreshStatus()
    }

    /// Initializes a board state from a standard FEN string (handy for tests & scenarios).
    init?(fen: String) {
        let parts = fen.split(separator: " ").map(String.init)
        guard parts.count >= 4 else { return nil }

        var board: [ChessPiece?] = Array(repeating: nil, count: 64)
        let ranks = parts[0].split(separator: "/")
        guard ranks.count == 8 else { return nil }

        for (fenRowIdx, rankStr) in ranks.enumerated() {
            let rank = 7 - fenRowIdx
            var file = 0
            for ch in rankStr {
                if let emptyCount = Int(String(ch)) {
                    file += emptyCount
                } else {
                    guard file < 8 else { return nil }
                    let color: PieceColor = ch.isUppercase ? .light : .dark
                    let kind: PieceKind?
                    switch ch.lowercased() {
                    case "p": kind = .pawn
                    case "n": kind = .knight
                    case "b": kind = .bishop
                    case "r": kind = .rook
                    case "q": kind = .queen
                    case "k": kind = .king
                    default:  kind = nil
                    }
                    guard let pieceKind = kind else { return nil }
                    let hasMoved = !(pieceKind == .pawn && ((color == .light && rank == 1) || (color == .dark && rank == 6)))
                    board[rank * 8 + file] = ChessPiece(kind: pieceKind, color: color, hasMoved: hasMoved)
                    file += 1
                }
            }
            guard file == 8 else { return nil }
        }

        let sideToMove: PieceColor = parts[1] == "b" ? .dark : .light
        let castleStr = parts[2]
        var rights = CastlingRights.none
        if castleStr.contains("K") { rights.whiteKingside = true }
        if castleStr.contains("Q") { rights.whiteQueenside = true }
        if castleStr.contains("k") { rights.blackKingside = true }
        if castleStr.contains("q") { rights.blackQueenside = true }

        // Synchronize unmoved flags on home-rank kings & rooks matching FEN rights
        func clearHasMovedIfAt(_ sq: ChessSquare, kind: PieceKind, color: PieceColor) {
            let idx = sq.rank * 8 + sq.file
            if var p = board[idx], p.kind == kind, p.color == color {
                p.hasMoved = false
                board[idx] = p
            }
        }
        if rights.whiteKingside || rights.whiteQueenside {
            clearHasMovedIfAt(ChessSquare(file: 4, rank: 0), kind: .king, color: .light)
        }
        if rights.whiteKingside { clearHasMovedIfAt(ChessSquare(file: 7, rank: 0), kind: .rook, color: .light) }
        if rights.whiteQueenside { clearHasMovedIfAt(ChessSquare(file: 0, rank: 0), kind: .rook, color: .light) }
        if rights.blackKingside || rights.blackQueenside {
            clearHasMovedIfAt(ChessSquare(file: 4, rank: 7), kind: .king, color: .dark)
        }
        if rights.blackKingside { clearHasMovedIfAt(ChessSquare(file: 7, rank: 7), kind: .rook, color: .dark) }
        if rights.blackQueenside { clearHasMovedIfAt(ChessSquare(file: 0, rank: 7), kind: .rook, color: .dark) }

        let epSquare: ChessSquare? = parts[3] == "-" ? nil : ChessSquare(algebraic: parts[3])
        let half = parts.count > 4 ? (Int(parts[4]) ?? 0) : 0
        let full = parts.count > 5 ? max(1, Int(parts[5]) ?? 1) : 1

        self.squares = board
        self.turn = sideToMove
        self.castlingRights = rights
        self.enPassantTarget = epSquare
        self.halfMoveClock = half
        self.fullMoveNumber = full
        self.capturedByLight = []
        self.capturedByDark = []
        self.lastMove = nil
        self.status = .playing
        self.positionCounts = [:]
        let key = repetitionKey()
        self.positionCounts[key] = 1
        refreshStatus()
    }

    private mutating func setupStandardBoard() {
        squares = Array(repeating: nil, count: 64)
        let backRank: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]

        for file in 0..<8 {
            setPiece(ChessPiece(kind: backRank[file], color: .light), at: ChessSquare(file: file, rank: 0))
            setPiece(ChessPiece(kind: .pawn, color: .light), at: ChessSquare(file: file, rank: 1))
            setPiece(ChessPiece(kind: .pawn, color: .dark), at: ChessSquare(file: file, rank: 6))
            setPiece(ChessPiece(kind: backRank[file], color: .dark), at: ChessSquare(file: file, rank: 7))
        }
    }

    // MARK: - Square Access

    func piece(at square: ChessSquare) -> ChessPiece? {
        guard square.isValid else { return nil }
        return squares[square.rank * 8 + square.file]
    }

    private mutating func setPiece(_ piece: ChessPiece?, at square: ChessSquare) {
        guard square.isValid else { return }
        squares[square.rank * 8 + square.file] = piece
    }

    func kingSquare(for color: PieceColor) -> ChessSquare? {
        for idx in 0..<64 {
            if let p = squares[idx], p.kind == .king && p.color == color {
                return ChessSquare(file: idx % 8, rank: idx / 8)
            }
        }
        return nil
    }

    // MARK: - Attack & Check Detection

    func isKingInCheck(for color: PieceColor) -> Bool {
        guard let kingSq = kingSquare(for: color) else { return false }
        return isSquareAttacked(kingSq, by: color.opponent)
    }

    func isSquareAttacked(_ square: ChessSquare, by attacker: PieceColor) -> Bool {
        // 1. Pawn attacks
        let pawnRank = square.rank + (attacker == .light ? -1 : 1)
        if (0..<8).contains(pawnRank) {
            for df in [-1, 1] {
                let pf = square.file + df
                if (0..<8).contains(pf), let p = piece(at: ChessSquare(file: pf, rank: pawnRank)),
                   p.color == attacker, p.kind == .pawn {
                    return true
                }
            }
        }

        // 2. Knight attacks
        let knightDeltas = [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)]
        for (df, dr) in knightDeltas {
            if let sq = square.offset(files: df, ranks: dr),
               let p = piece(at: sq), p.color == attacker, p.kind == .knight {
                return true
            }
        }

        // 3. King attacks
        for df in -1...1 {
            for dr in -1...1 where !(df == 0 && dr == 0) {
                if let sq = square.offset(files: df, ranks: dr),
                   let p = piece(at: sq), p.color == attacker, p.kind == .king {
                    return true
                }
            }
        }

        // 4. Orthogonal rays (Rook / Queen)
        let orthoDirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
        for (df, dr) in orthoDirs {
            var cur = square.offset(files: df, ranks: dr)
            while let sq = cur {
                if let p = piece(at: sq) {
                    if p.color == attacker && (p.kind == .rook || p.kind == .queen) {
                        return true
                    }
                    break
                }
                cur = sq.offset(files: df, ranks: dr)
            }
        }

        // 5. Diagonal rays (Bishop / Queen)
        let diagDirs = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        for (df, dr) in diagDirs {
            var cur = square.offset(files: df, ranks: dr)
            while let sq = cur {
                if let p = piece(at: sq) {
                    if p.color == attacker && (p.kind == .bishop || p.kind == .queen) {
                        return true
                    }
                    break
                }
                cur = sq.offset(files: df, ranks: dr)
            }
        }

        return false
    }

    // MARK: - Legal Move Generation

    func legalMoves(for color: PieceColor? = nil) -> [ChessMove] {
        let mover = color ?? turn
        guard !status.isTerminal else { return [] }
        var pseudo: [ChessMove] = []
        pseudo.reserveCapacity(40)

        for idx in 0..<64 {
            guard let piece = squares[idx], piece.color == mover else { continue }
            let sq = ChessSquare(file: idx % 8, rank: idx / 8)
            appendPseudoLegalMoves(from: sq, piece: piece, into: &pseudo)
        }

        return pseudo.filter { move in
            var copy = self
            copy.applyUnchecked(move)
            return !copy.isKingInCheck(for: mover)
        }
    }

    func legalMoves(from square: ChessSquare) -> [ChessMove] {
        guard !status.isTerminal,
              let piece = piece(at: square),
              piece.color == turn else {
            return []
        }
        var pseudo: [ChessMove] = []
        appendPseudoLegalMoves(from: square, piece: piece, into: &pseudo)
        return pseudo.filter { move in
            var copy = self
            copy.applyUnchecked(move)
            return !copy.isKingInCheck(for: turn)
        }
    }

    private func appendPseudoLegalMoves(from sq: ChessSquare, piece: ChessPiece, into out: inout [ChessMove]) {
        switch piece.kind {
        case .pawn:
            let dir = piece.color == .light ? 1 : -1
            let startRank = piece.color == .light ? 1 : 6
            let promoRank = piece.color == .light ? 7 : 0

            // Single push
            if let oneAhead = sq.offset(files: 0, ranks: dir), self.piece(at: oneAhead) == nil {
                if oneAhead.rank == promoRank {
                    for kind in PieceKind.promotableKinds {
                        out.append(ChessMove(
                            from: sq, to: oneAhead, movedPiece: piece,
                            capturedPiece: nil, capturedSquare: nil, promotion: kind,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                } else {
                    out.append(ChessMove(
                        from: sq, to: oneAhead, movedPiece: piece,
                        capturedPiece: nil, capturedSquare: nil, promotion: nil,
                        isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                    ))

                    // Double push from home rank
                    if sq.rank == startRank,
                       let twoAhead = sq.offset(files: 0, ranks: dir * 2),
                       self.piece(at: twoAhead) == nil {
                        out.append(ChessMove(
                            from: sq, to: twoAhead, movedPiece: piece,
                            capturedPiece: nil, capturedSquare: nil, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                }
            }

            // Diagonal captures & en passant
            for df in [-1, 1] {
                guard let targetSq = sq.offset(files: df, ranks: dir) else { continue }
                if let victim = self.piece(at: targetSq), victim.color != piece.color {
                    if targetSq.rank == promoRank {
                        for kind in PieceKind.promotableKinds {
                            out.append(ChessMove(
                                from: sq, to: targetSq, movedPiece: piece,
                                capturedPiece: victim, capturedSquare: targetSq, promotion: kind,
                                isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                            ))
                        }
                    } else {
                        out.append(ChessMove(
                            from: sq, to: targetSq, movedPiece: piece,
                            capturedPiece: victim, capturedSquare: targetSq, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                } else if let ep = enPassantTarget, ep == targetSq {
                    let capturedSq = ChessSquare(file: targetSq.file, rank: sq.rank)
                    if let epVictim = self.piece(at: capturedSq),
                       epVictim.color != piece.color,
                       epVictim.kind == .pawn {
                        out.append(ChessMove(
                            from: sq, to: targetSq, movedPiece: piece,
                            capturedPiece: epVictim, capturedSquare: capturedSq, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: true
                        ))
                    }
                }
            }

        case .knight:
            let deltas = [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)]
            for (df, dr) in deltas {
                guard let dst = sq.offset(files: df, ranks: dr) else { continue }
                if let occupant = self.piece(at: dst) {
                    if occupant.color != piece.color {
                        out.append(ChessMove(
                            from: sq, to: dst, movedPiece: piece,
                            capturedPiece: occupant, capturedSquare: dst, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                } else {
                    out.append(ChessMove(
                        from: sq, to: dst, movedPiece: piece,
                        capturedPiece: nil, capturedSquare: nil, promotion: nil,
                        isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                    ))
                }
            }

        case .bishop:
            appendSlidingMoves(from: sq, piece: piece, directions: [(1, 1), (1, -1), (-1, 1), (-1, -1)], into: &out)

        case .rook:
            appendSlidingMoves(from: sq, piece: piece, directions: [(1, 0), (-1, 0), (0, 1), (0, -1)], into: &out)

        case .queen:
            appendSlidingMoves(
                from: sq,
                piece: piece,
                directions: [(1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)],
                into: &out
            )

        case .king:
            for df in -1...1 {
                for dr in -1...1 where !(df == 0 && dr == 0) {
                    guard let dst = sq.offset(files: df, ranks: dr) else { continue }
                    if let occupant = self.piece(at: dst) {
                        if occupant.color != piece.color {
                            out.append(ChessMove(
                                from: sq, to: dst, movedPiece: piece,
                                capturedPiece: occupant, capturedSquare: dst, promotion: nil,
                                isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                            ))
                        }
                    } else {
                        out.append(ChessMove(
                            from: sq, to: dst, movedPiece: piece,
                            capturedPiece: nil, capturedSquare: nil, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                }
            }
            appendCastlingMoves(from: sq, king: piece, into: &out)
        }
    }

    private func appendSlidingMoves(
        from sq: ChessSquare,
        piece: ChessPiece,
        directions: [(Int, Int)],
        into out: inout [ChessMove]
    ) {
        for (df, dr) in directions {
            var cur = sq.offset(files: df, ranks: dr)
            while let dst = cur {
                if let occupant = self.piece(at: dst) {
                    if occupant.color != piece.color {
                        out.append(ChessMove(
                            from: sq, to: dst, movedPiece: piece,
                            capturedPiece: occupant, capturedSquare: dst, promotion: nil,
                            isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                        ))
                    }
                    break
                } else {
                    out.append(ChessMove(
                        from: sq, to: dst, movedPiece: piece,
                        capturedPiece: nil, capturedSquare: nil, promotion: nil,
                        isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: false
                    ))
                }
                cur = dst.offset(files: df, ranks: dr)
            }
        }
    }

    private func appendCastlingMoves(from sq: ChessSquare, king: ChessPiece, into out: inout [ChessMove]) {
        let homeRank = king.color == .light ? 0 : 7
        guard sq.file == 4, sq.rank == homeRank, !king.hasMoved else { return }
        let enemy = king.color.opponent
        guard !isSquareAttacked(sq, by: enemy) else { return }

        let canKingside = king.color == .light ? castlingRights.whiteKingside : castlingRights.blackKingside
        if canKingside {
            let fSq = ChessSquare(file: 5, rank: homeRank)
            let gSq = ChessSquare(file: 6, rank: homeRank)
            let rookSq = ChessSquare(file: 7, rank: homeRank)
            if self.piece(at: fSq) == nil,
               self.piece(at: gSq) == nil,
               let rook = self.piece(at: rookSq),
               rook.kind == .rook && rook.color == king.color && !rook.hasMoved,
               !isSquareAttacked(fSq, by: enemy),
               !isSquareAttacked(gSq, by: enemy) {
                out.append(ChessMove(
                    from: sq, to: gSq, movedPiece: king,
                    capturedPiece: nil, capturedSquare: nil, promotion: nil,
                    isCastlingKingside: true, isCastlingQueenside: false, isEnPassant: false
                ))
            }
        }

        let canQueenside = king.color == .light ? castlingRights.whiteQueenside : castlingRights.blackQueenside
        if canQueenside {
            let dSq = ChessSquare(file: 3, rank: homeRank)
            let cSq = ChessSquare(file: 2, rank: homeRank)
            let bSq = ChessSquare(file: 1, rank: homeRank)
            let rookSq = ChessSquare(file: 0, rank: homeRank)
            if self.piece(at: dSq) == nil,
               self.piece(at: cSq) == nil,
               self.piece(at: bSq) == nil,
               let rook = self.piece(at: rookSq),
               rook.kind == .rook && rook.color == king.color && !rook.hasMoved,
               !isSquareAttacked(dSq, by: enemy),
               !isSquareAttacked(cSq, by: enemy) {
                out.append(ChessMove(
                    from: sq, to: cSq, movedPiece: king,
                    capturedPiece: nil, capturedSquare: nil, promotion: nil,
                    isCastlingKingside: false, isCastlingQueenside: true, isEnPassant: false
                ))
            }
        }
    }

    // MARK: - Move Execution

    @discardableResult
    mutating func makeMove(_ move: ChessMove) -> Bool {
        let validMoves = legalMoves(from: move.from)
        guard let legal = validMoves.first(where: { $0 == move }) else {
            return false
        }
        applyMoveAndUpdateState(legal)
        return true
    }

    /// Fast unchecked move used during legal filtering & AI search (leaves `status` unrefreshed when searching).
    fileprivate mutating func applyUnchecked(_ move: ChessMove) {
        setPiece(nil, at: move.from)

        if move.isEnPassant, let capSq = move.capturedSquare {
            setPiece(nil, at: capSq)
        }

        var updatedPiece = move.movedPiece
        updatedPiece.hasMoved = true
        if let promo = move.promotion {
            updatedPiece.kind = promo
        }
        setPiece(updatedPiece, at: move.to)

        // Move rook cleanly when castling
        if move.isCastlingKingside {
            let rank = move.from.rank
            if var rook = piece(at: ChessSquare(file: 7, rank: rank)) {
                rook.hasMoved = true
                setPiece(nil, at: ChessSquare(file: 7, rank: rank))
                setPiece(rook, at: ChessSquare(file: 5, rank: rank))
            }
        } else if move.isCastlingQueenside {
            let rank = move.from.rank
            if var rook = piece(at: ChessSquare(file: 0, rank: rank)) {
                rook.hasMoved = true
                setPiece(nil, at: ChessSquare(file: 0, rank: rank))
                setPiece(rook, at: ChessSquare(file: 3, rank: rank))
            }
        }

        // Update castling rights on king/rook departure or corner rook capture
        revokeCastlingRights(for: move)

        // Update en passant square on 2-rank pawn push
        if move.movedPiece.kind == .pawn && abs(move.to.rank - move.from.rank) == 2 {
            let skippedRank = (move.from.rank + move.to.rank) / 2
            enPassantTarget = ChessSquare(file: move.from.file, rank: skippedRank)
        } else {
            enPassantTarget = nil
        }

        turn = turn.opponent
    }

    private mutating func applyMoveAndUpdateState(_ move: ChessMove) {
        applyUnchecked(move)

        if let cap = move.capturedPiece {
            if move.movedPiece.color == .light {
                capturedByLight.append(cap.kind)
            } else {
                capturedByDark.append(cap.kind)
            }
        }

        if move.movedPiece.kind == .pawn || move.isCapture {
            halfMoveClock = 0
        } else {
            halfMoveClock += 1
        }

        if move.movedPiece.color == .dark {
            fullMoveNumber += 1
        }

        lastMove = move
        let key = repetitionKey()
        positionCounts[key, default: 0] += 1
        refreshStatus()
    }

    private mutating func revokeCastlingRights(for move: ChessMove) {
        if move.movedPiece.kind == .king {
            if move.movedPiece.color == .light {
                castlingRights.whiteKingside = false
                castlingRights.whiteQueenside = false
            } else {
                castlingRights.blackKingside = false
                castlingRights.blackQueenside = false
            }
        }
        func checkCorner(_ sq: ChessSquare) {
            if sq == ChessSquare(file: 0, rank: 0) { castlingRights.whiteQueenside = false }
            if sq == ChessSquare(file: 7, rank: 0) { castlingRights.whiteKingside = false }
            if sq == ChessSquare(file: 0, rank: 7) { castlingRights.blackQueenside = false }
            if sq == ChessSquare(file: 7, rank: 7) { castlingRights.blackKingside = false }
        }
        checkCorner(move.from)
        checkCorner(move.to)
    }

    // MARK: - Status & Draw Conditions

    mutating func forceTimeout(winner: PieceColor) {
        status = .timeout(winner: winner)
    }

    private mutating func refreshStatus() {
        // Compute legal moves before marking terminal so `legalMoves()` executes cleanly
        status = .playing
        let nextMoves = legalMoves(for: turn)
        let inCheck = isKingInCheck(for: turn)

        if nextMoves.isEmpty {
            status = inCheck ? .checkmate(winner: turn.opponent) : .stalemate
            return
        }

        if isInsufficientMaterial() {
            status = .drawInsufficientMaterial
            return
        }

        let key = repetitionKey()
        if (positionCounts[key] ?? 0) >= 3 {
            status = .drawThreefoldRepetition
            return
        }

        if halfMoveClock >= 100 {
            status = .drawFiftyMove
            return
        }

        status = inCheck ? .check(turn) : .playing
    }

    func isInsufficientMaterial() -> Bool {
        var lightMinors: [(PieceKind, ChessSquare)] = []
        var darkMinors: [(PieceKind, ChessSquare)] = []

        for idx in 0..<64 {
            guard let piece = squares[idx] else { continue }
            switch piece.kind {
            case .pawn, .rook, .queen:
                return false
            case .king:
                continue
            case .bishop, .knight:
                let sq = ChessSquare(file: idx % 8, rank: idx / 8)
                if piece.color == .light {
                    lightMinors.append((piece.kind, sq))
                } else {
                    darkMinors.append((piece.kind, sq))
                }
            }
        }

        let totalMinors = lightMinors.count + darkMinors.count
        // K vs K, K+minor vs K
        if totalMinors <= 1 { return true }

        // K+B vs K+B on same-colored squares cannot checkmate
        if lightMinors.count == 1, darkMinors.count == 1,
           lightMinors[0].0 == .bishop, darkMinors[0].0 == .bishop {
            return lightMinors[0].1.isLightSquare == darkMinors[0].1.isLightSquare
        }

        return false
    }

    func repetitionKey() -> String {
        var out = ""
        for rank in stride(from: 7, through: 0, by: -1) {
            var empty = 0
            for file in 0..<8 {
                if let p = squares[rank * 8 + file] {
                    if empty > 0 {
                        out.append(String(empty))
                        empty = 0
                    }
                    out.append(p.fenCharacter)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { out.append(String(empty)) }
            if rank > 0 { out.append("/") }
        }
        out.append(" \(turn == .light ? "w" : "b") \(castlingRights.fenString)")

        // Only record en passant target if an enemy pawn can legally capture it
        if let ep = enPassantTarget, hasLegalEnPassantCapture(at: ep) {
            out.append(" \(ep.algebraic)")
        } else {
            out.append(" -")
        }
        return out
    }

    private func hasLegalEnPassantCapture(at ep: ChessSquare) -> Bool {
        let pawnRank = turn == .light ? ep.rank - 1 : ep.rank + 1
        guard (0..<8).contains(pawnRank) else { return false }
        for df in [-1, 1] {
            let pf = ep.file + df
            guard (0..<8).contains(pf) else { continue }
            let fromSq = ChessSquare(file: pf, rank: pawnRank)
            if let p = piece(at: fromSq), p.color == turn, p.kind == .pawn {
                let capturedSq = ChessSquare(file: ep.file, rank: pawnRank)
                let victim = piece(at: capturedSq)
                let move = ChessMove(
                    from: fromSq, to: ep, movedPiece: p,
                    capturedPiece: victim, capturedSquare: capturedSq, promotion: nil,
                    isCastlingKingside: false, isCastlingQueenside: false, isEnPassant: true
                )
                var copy = self
                copy.applyUnchecked(move)
                if !copy.isKingInCheck(for: turn) {
                    return true
                }
            }
        }
        return false
    }
}

// MARK: - Stateful Session Engine (Supports Exact Undo & Restart)

struct ChessSnapshot {
    let boardState: ChessBoardState
    let whiteTimeRemaining: TimeInterval
    let blackTimeRemaining: TimeInterval
}

@MainActor
final class ChessSessionEngine {
    private(set) var state: ChessBoardState
    private(set) var difficulty: ChessDifficulty
    private(set) var timeControl: ChessTimeControl
    private(set) var whiteTimeRemaining: TimeInterval
    private(set) var blackTimeRemaining: TimeInterval
    private(set) var moveHistory: [ChessMove] = []
    private var undoStack: [ChessSnapshot] = []

    var canUndo: Bool {
        !undoStack.isEmpty
    }

    init(difficulty: ChessDifficulty = .intermediate, timeControl: ChessTimeControl = .untimed) {
        self.difficulty = difficulty
        self.timeControl = timeControl
        let initialSecs = timeControl.initialSeconds ?? 0
        self.whiteTimeRemaining = initialSecs
        self.blackTimeRemaining = initialSecs
        self.state = ChessBoardState()
    }

    func reset(difficulty: ChessDifficulty? = nil, timeControl: ChessTimeControl? = nil) {
        if let difficulty { self.difficulty = difficulty }
        if let timeControl { self.timeControl = timeControl }
        let initialSecs = self.timeControl.initialSeconds ?? 0
        self.whiteTimeRemaining = initialSecs
        self.blackTimeRemaining = initialSecs
        self.state = ChessBoardState()
        self.moveHistory.removeAll()
        self.undoStack.removeAll()
    }

    func updateDifficulty(_ difficulty: ChessDifficulty) {
        self.difficulty = difficulty
    }

    @discardableResult
    func performMove(_ move: ChessMove) -> Bool {
        let snapshot = ChessSnapshot(
            boardState: state,
            whiteTimeRemaining: whiteTimeRemaining,
            blackTimeRemaining: blackTimeRemaining
        )
        guard state.makeMove(move) else { return false }
        undoStack.append(snapshot)
        moveHistory.append(move)
        return true
    }

    /// Undoes one single half-move (ply), restoring exact board state, clocks, and castling/EP rights.
    @discardableResult
    func undoSinglePly() -> Bool {
        guard let last = undoStack.popLast() else { return false }
        state = last.boardState
        whiteTimeRemaining = last.whiteTimeRemaining
        blackTimeRemaining = last.blackTimeRemaining
        _ = moveHistory.popLast()
        return true
    }

    /// Undoes back to the human player's (`.light`) turn so Undo never traps the user on AI's turn.
    @discardableResult
    func undoToPlayerTurn() -> Int {
        guard !undoStack.isEmpty else { return 0 }
        var pliesUndone = 0
        // If AI moved last (turn == .light now), undo AI + Player (2 plies); if Player just moved (turn == .dark), undo 1 ply.
        if undoSinglePly() {
            pliesUndone += 1
        }
        while state.turn != .light, undoSinglePly() {
            pliesUndone += 1
        }
        return pliesUndone
    }

    /// Advances active clock; returns winner color if a flag falls.
    @discardableResult
    func tickClock(elapsed: TimeInterval) -> PieceColor? {
        guard timeControl.initialSeconds != nil, !state.status.isTerminal, elapsed > 0 else {
            return nil
        }
        if state.turn == .light {
            whiteTimeRemaining = max(0, whiteTimeRemaining - elapsed)
            if whiteTimeRemaining <= 0 {
                state.forceTimeout(winner: .dark)
                return .dark
            }
        } else {
            blackTimeRemaining = max(0, blackTimeRemaining - elapsed)
            if blackTimeRemaining <= 0 {
                state.forceTimeout(winner: .light)
                return .light
            }
        }
        return nil
    }
}

// MARK: - Chess AI (Alpha-Beta Search + Piece-Square Tables + MVV-LVA Ordering)

enum ChessAI {
    private static let mateScore = 100_000

    static func bestMove(for state: ChessBoardState, difficulty: ChessDifficulty) -> ChessMove? {
        let color = state.turn
        let moves = orderedMoves(state.legalMoves(for: color))
        guard !moves.isEmpty else { return nil }
        if moves.count == 1 { return moves[0] }

        switch difficulty {
        case .beginner:
            return chooseBeginnerMove(state: state, moves: moves, for: color)
        case .intermediate:
            return searchBestMove(state: state, moves: moves, depth: 2, for: color, topPoolSize: 2, thresholdCp: 25)
        case .advanced:
            return searchBestMove(state: state, moves: moves, depth: 3, for: color, topPoolSize: 1, thresholdCp: 0)
        }
    }

    private static func chooseBeginnerMove(
        state: ChessBoardState,
        moves: [ChessMove],
        for color: PieceColor
    ) -> ChessMove? {
        // Depth-1 greedy score + forgiving noise so beginners have fun winnable games
        var scored: [(move: ChessMove, score: Int)] = moves.map { move in
            var copy = state
            copy.applyUnchecked(move)
            // Always play obvious mate-in-1 if spotted cleanly
            if copy.legalMoves(for: color.opponent).isEmpty && copy.isKingInCheck(for: color.opponent) {
                return (move, mateScore)
            }
            let base = evaluate(copy, perspective: color)
            let jitter = Int.random(in: -85...85)
            return (move, base + jitter)
        }
        scored.sort { $0.score > $1.score }
        if let mate = scored.first, mate.score >= mateScore - 100 {
            return mate.move
        }
        let poolCount = min(3, scored.count)
        return scored[Int.random(in: 0..<poolCount)].move
    }

    private static func searchBestMove(
        state: ChessBoardState,
        moves: [ChessMove],
        depth: Int,
        for color: PieceColor,
        topPoolSize: Int,
        thresholdCp: Int
    ) -> ChessMove? {
        var scored: [(move: ChessMove, score: Int)] = []
        scored.reserveCapacity(moves.count)
        var alpha = -mateScore - 500
        let beta = mateScore + 500
        var nodeBudget = depth >= 3 ? 28_000 : 8_000

        for move in moves {
            var copy = state
            copy.applyUnchecked(move)
            let val = -negamax(copy, depth: depth - 1, ply: 1, alpha: -beta, beta: -alpha, perspective: color.opponent, nodeBudget: &nodeBudget)
            scored.append((move, val))
            if val > alpha { alpha = val }
        }

        scored.sort { $0.score > $1.score }
        guard let best = scored.first else { return nil }
        if topPoolSize <= 1 || best.score >= mateScore - 1_000 {
            return best.move
        }

        let candidates = scored.prefix(topPoolSize).filter { best.score - $0.score <= thresholdCp }
        return candidates.randomElement()?.move ?? best.move
    }

    private static func negamax(
        _ state: ChessBoardState,
        depth: Int,
        ply: Int,
        alpha initialAlpha: Int,
        beta: Int,
        perspective: PieceColor,
        nodeBudget: inout Int
    ) -> Int {
        nodeBudget -= 1
        if nodeBudget <= 0 {
            return evaluate(state, perspective: perspective)
        }

        let moves = orderedMoves(state.legalMoves(for: perspective))
        if moves.isEmpty {
            if state.isKingInCheck(for: perspective) {
                return -(mateScore - ply)
            }
            return 0 // Stalemate
        }

        if state.isInsufficientMaterial() {
            return 0
        }

        if depth <= 0 {
            return quiescence(state, alpha: initialAlpha, beta: beta, perspective: perspective, qDepth: 2, nodeBudget: &nodeBudget)
        }

        var alpha = initialAlpha
        var best = -mateScore - 500

        for move in moves {
            var copy = state
            copy.applyUnchecked(move)
            let score = -negamax(copy, depth: depth - 1, ply: ply + 1, alpha: -beta, beta: -alpha, perspective: perspective.opponent, nodeBudget: &nodeBudget)
            if score > best { best = score }
            if best > alpha { alpha = best }
            if alpha >= beta { break }
        }
        return best
    }

    private static func quiescence(
        _ state: ChessBoardState,
        alpha initialAlpha: Int,
        beta: Int,
        perspective: PieceColor,
        qDepth: Int,
        nodeBudget: inout Int
    ) -> Int {
        nodeBudget -= 1
        let standPat = evaluate(state, perspective: perspective)
        if qDepth <= 0 || nodeBudget <= 0 { return standPat }
        var alpha = initialAlpha
        if standPat >= beta { return beta }
        if standPat > alpha { alpha = standPat }

        let forcing = orderedMoves(state.legalMoves(for: perspective)).filter { $0.isCapture || $0.promotion != nil }
        for move in forcing {
            var copy = state
            copy.applyUnchecked(move)
            let score = -quiescence(copy, alpha: -beta, beta: -alpha, perspective: perspective.opponent, qDepth: qDepth - 1, nodeBudget: &nodeBudget)
            if score >= beta { return beta }
            if score > alpha { alpha = score }
        }
        return alpha
    }

    private static func orderedMoves(_ moves: [ChessMove]) -> [ChessMove] {
        moves.sorted { movePriority($0) > movePriority($1) }
    }

    private static func movePriority(_ move: ChessMove) -> Int {
        var score = 0
        if let cap = move.capturedPiece {
            score += 1_000 + cap.kind.value * 100 - move.movedPiece.kind.value * 10
        }
        if let promo = move.promotion {
            score += 800 + promo.value * 80
        }
        if move.isCastling {
            score += 90
        }
        // Central file/rank nudge
        let fileDist = abs(move.to.file * 2 - 7)
        let rankDist = abs(move.to.rank * 2 - 7)
        score += 14 - (fileDist + rankDist)
        return score
    }

    // MARK: - Static Position Evaluation (Centipawns)

    private static func evaluate(_ state: ChessBoardState, perspective: PieceColor) -> Int {
        var total = 0
        var lightBishops = 0
        var darkBishops = 0

        for idx in 0..<64 {
            guard let p = state.squares[idx] else { continue }
            let file = idx % 8
            let rank = idx / 8
            let pstRank = p.color == .light ? rank : (7 - rank)
            let squareVal = pieceCentipawns(p.kind) + pstBonus(kind: p.kind, file: file, rankFromBack: pstRank)

            if p.color == .light {
                total += squareVal
                if p.kind == .bishop { lightBishops += 1 }
            } else {
                total -= squareVal
                if p.kind == .bishop { darkBishops += 1 }
            }
        }

        if lightBishops >= 2 { total += 30 }
        if darkBishops >= 2 { total -= 30 }

        return perspective == .light ? total : -total
    }

    private static func pieceCentipawns(_ kind: PieceKind) -> Int {
        switch kind {
        case .pawn:   return 100
        case .knight: return 320
        case .bishop: return 330
        case .rook:   return 500
        case .queen:  return 900
        case .king:   return 0
        }
    }

    private static func pstBonus(kind: PieceKind, file: Int, rankFromBack r: Int) -> Int {
        let row = max(0, min(7, r))
        let col = max(0, min(7, file))
        let idx = (7 - row) * 8 + col
        switch kind {
        case .pawn:   return pawnPST[idx]
        case .knight: return knightPST[idx]
        case .bishop: return bishopPST[idx]
        case .rook:   return rookPST[idx]
        case .queen:  return queenPST[idx]
        case .king:   return kingMidPST[idx]
        }
    }

    // Ranked top-to-bottom from rank 8 (row 0) down to rank 1 (row 7) from White's perspective
    private static let pawnPST: [Int] = [
         0,  0,  0,  0,  0,  0,  0,  0,
        50, 50, 50, 50, 50, 50, 50, 50,
        10, 10, 20, 30, 30, 20, 10, 10,
         5,  5, 10, 27, 27, 10,  5,  5,
         0,  0,  0, 24, 24,  0,  0,  0,
         5, -5,-10,  0,  0,-10, -5,  5,
         5, 10, 10,-22,-22, 10, 10,  5,
         0,  0,  0,  0,  0,  0,  0,  0
    ]

    private static let knightPST: [Int] = [
        -50,-40,-30,-30,-30,-30,-40,-50,
        -40,-20,  0,  0,  0,  0,-20,-40,
        -30,  0, 10, 15, 15, 10,  0,-30,
        -30,  5, 15, 20, 20, 15,  5,-30,
        -30,  0, 15, 20, 20, 15,  0,-30,
        -30,  5, 10, 15, 15, 10,  5,-30,
        -40,-20,  0,  5,  5,  0,-20,-40,
        -50,-40,-30,-30,-30,-30,-40,-50
    ]

    private static let bishopPST: [Int] = [
        -20,-10,-10,-10,-10,-10,-10,-20,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -10,  0,  5, 10, 10,  5,  0,-10,
        -10,  5,  5, 10, 10,  5,  5,-10,
        -10,  0, 10, 10, 10, 10,  0,-10,
        -10, 10, 10, 10, 10, 10, 10,-10,
        -10,  5,  0,  0,  0,  0,  5,-10,
        -20,-10,-10,-10,-10,-10,-10,-20
    ]

    private static let rookPST: [Int] = [
         0,  0,  0,  0,  0,  0,  0,  0,
         5, 10, 10, 10, 10, 10, 10,  5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
        -5,  0,  0,  0,  0,  0,  0, -5,
         0,  0,  0,  5,  5,  0,  0,  0
    ]

    private static let queenPST: [Int] = [
        -20,-10,-10, -5, -5,-10,-10,-20,
        -10,  0,  0,  0,  0,  0,  0,-10,
        -10,  0,  5,  5,  5,  5,  0,-10,
         -5,  0,  5,  5,  5,  5,  0, -5,
          0,  0,  5,  5,  5,  5,  0, -5,
        -10,  5,  5,  5,  5,  5,  0,-10,
        -10,  0,  5,  0,  0,  0,  0,-10,
        -20,-10,-10, -5, -5,-10,-10,-20
    ]

    private static let kingMidPST: [Int] = [
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -30,-40,-40,-50,-50,-40,-40,-30,
        -20,-30,-30,-40,-40,-30,-30,-20,
        -10,-20,-20,-20,-20,-20,-20,-10,
         20, 20,  0,  0,  0,  0, 20, 20,
         20, 30, 10,  0,  0, 10, 30, 20
    ]
}
