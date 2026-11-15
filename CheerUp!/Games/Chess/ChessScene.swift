import SpriteKit
import UIKit

@MainActor
protocol ChessSceneDelegate: AnyObject {
    func chessSceneDidTapSquare(_ square: ChessSquare)
    func chessSceneDidDragPiece(from: ChessSquare, to: ChessSquare) -> Bool
}

/// Pure 2D flat pixel-art SpriteKit chessboard scene integrating `PieceAnimator`,
/// `PixelFX`, `ScreenShake`, and `CapturedTray` in a brown-and-cream wooden frame.
/// Supports both Tap-to-Move and fluid Touch-and-Drag piece movement.
final class ChessScene: SKScene {
    weak var gameDelegate: ChessSceneDelegate?

    // Fixed virtual portrait dimensions maximizing board footprint on portrait iPhone screens
    static let sceneWidth: CGFloat = 384
    static let sceneHeight: CGFloat = 452
    private let tileSize: CGFloat = 44
    private let pixelUnit: CGFloat = 2
    private let leftRailWidth: CGFloat = 18
    private let bottomRailHeight: CGFloat = 18
    private let outerTrimWidth: CGFloat = 8

    private var boardOrigin: CGPoint = .zero
    private let worldNode = SKNode()
    private var animator: PieceAnimator!

    // Board highlight layers
    private var tileNodes: [SKSpriteNode] = []
    private var lastMoveNodes: [SKSpriteNode] = []
    private var legalMarkerNodes: [SKSpriteNode] = []
    private var legalDestinationSquares: Set<ChessSquare> = []
    private var checkHighlightNode: SKSpriteNode?
    private var dragHoverNode: SKSpriteNode?

    // Piece & captured tray tracking
    private var pieceNodes: [UUID: AnimatedPiece] = [:]
    private var pieceSquareMap: [UUID: ChessSquare] = [:]
    private var lightCapturedTray: CapturedTray!
    private var darkCapturedTray: CapturedTray!
    private var topAdvantageLabel: SKLabelNode?
    private var bottomAdvantageLabel: SKLabelNode?

    // Touch / Drag state
    private var touchStartSquare: ChessSquare?
    private var touchStartPoint: CGPoint = .zero
    private var draggedPieceID: UUID?
    private var isDraggingPiece = false

    private var didBuildScene = false
    private(set) var isAnimatingMove = false
    var playerColor: PieceColor = .light {
        didSet {
            guard oldValue != playerColor, didBuildScene else { return }
            didBuildScene = false
            ensureBuilt()
        }
    }
    private var isBoardFlipped: Bool { playerColor == .dark }
    var isGamePaused: Bool = false {
        didSet {
            worldNode.isPaused = isGamePaused
        }
    }
    private var animationGeneration = 0

    override init(size: CGSize = CGSize(width: ChessScene.sceneWidth, height: ChessScene.sceneHeight)) {
        super.init(size: size)
        self.scaleMode = .aspectFit
        self.backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        if !didBuildScene {
            buildScene()
            didBuildScene = true
        }
    }

    // MARK: - Scene Construction

    private func ensureBuilt() {
        guard !didBuildScene else { return }
        buildScene()
        didBuildScene = true
    }

    private func buildScene() {
        worldNode.removeAllChildren()
        removeAllChildren()
        addChild(worldNode)

        let boardGridSize = tileSize * 8 // 320
        let totalFrameWidth = leftRailWidth + boardGridSize + outerTrimWidth // 354
        let totalFrameHeight = bottomRailHeight + boardGridSize + outerTrimWidth // 354

        let frameLeft = (size.width - totalFrameWidth) * 0.5
        let frameBottom = (size.height - totalFrameHeight) * 0.5
        boardOrigin = CGPoint(x: frameLeft + leftRailWidth, y: frameBottom + bottomRailHeight)

        let boardRect = CGRect(
            x: boardOrigin.x,
            y: boardOrigin.y,
            width: boardGridSize,
            height: boardGridSize
        )

        // Animator setup
        animator = PieceAnimator(world: worldNode, tileSize: tileSize, pixelUnit: pixelUnit)
        animator.selectionFrameTexture = ChessSpriteAssets.selectionFrameTexture
        animator.boardFrame = boardRect
        animator.squareCenterOffset = CGPoint(x: 0, y: tileSize * 0.5 - 1)

        buildWoodFrame(
            frameRect: CGRect(x: frameLeft, y: frameBottom, width: totalFrameWidth, height: totalFrameHeight),
            boardRect: boardRect
        )
        buildGridTiles()
        buildCapturedTrays(frameLeft: frameLeft, frameBottom: frameBottom, frameWidth: totalFrameWidth, frameHeight: totalFrameHeight)
    }

    private func buildWoodFrame(frameRect: CGRect, boardRect: CGRect) {
        // Drop shadow plate
        let shadow = SKShapeNode(rect: frameRect.offsetBy(dx: 0, dy: -5), cornerRadius: 6)
        shadow.fillColor = UIColor.black.withAlphaComponent(0.42)
        shadow.strokeColor = .clear
        shadow.zPosition = 0
        worldNode.addChild(shadow)

        // Outer walnut wood frame
        let outerFrame = SKShapeNode(rect: frameRect, cornerRadius: 5)
        outerFrame.fillColor = PixelPalette.woodFrame
        outerFrame.strokeColor = PixelPalette.outline
        outerFrame.lineWidth = pixelUnit
        outerFrame.zPosition = 1
        worldNode.addChild(outerFrame)

        // Subtle inner wood bevel rim
        let bevelRect = frameRect.insetBy(dx: pixelUnit * 2, dy: pixelUnit * 2)
        let bevel = SKShapeNode(rect: bevelRect, cornerRadius: 3)
        bevel.fillColor = .clear
        bevel.strokeColor = PixelPalette.woodBevel
        bevel.lineWidth = pixelUnit
        bevel.zPosition = 2
        worldNode.addChild(bevel)

        // Thin cream hairline tightly framing the 8x8 tiles (matching reference)
        let hairline = SKShapeNode(rect: boardRect.insetBy(dx: -pixelUnit * 0.5, dy: -pixelUnit * 0.5))
        hairline.fillColor = .clear
        hairline.strokeColor = PixelPalette.creamLight
        hairline.lineWidth = pixelUnit
        hairline.zPosition = 4
        worldNode.addChild(hairline)

        // File labels a-h (or h-a when playing Brown) on bottom wood rail
        let baseFiles = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let files = isBoardFlipped ? Array(baseFiles.reversed()) : baseFiles
        for (idx, letter) in files.enumerated() {
            let label = SKLabelNode(text: letter)
            label.fontName = "Menlo-Bold"
            label.fontSize = 11
            label.fontColor = PixelPalette.creamLight
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(
                x: boardRect.minX + (CGFloat(idx) + 0.5) * tileSize,
                y: frameRect.minY + bottomRailHeight * 0.5
            )
            label.zPosition = 5
            worldNode.addChild(label)
        }

        // Rank labels 1-8 (or 8-1 when playing Brown) on left wood rail
        for visualRank in 0..<8 {
            let logicalRank = isBoardFlipped ? (7 - visualRank) : visualRank
            let label = SKLabelNode(text: "\(logicalRank + 1)")
            label.fontName = "Menlo-Bold"
            label.fontSize = 11
            label.fontColor = PixelPalette.creamLight
            label.horizontalAlignmentMode = .center
            label.verticalAlignmentMode = .center
            label.position = CGPoint(
                x: frameRect.minX + leftRailWidth * 0.5,
                y: boardRect.minY + (CGFloat(visualRank) + 0.5) * tileSize
            )
            label.zPosition = 5
            worldNode.addChild(label)
        }
    }

    private func buildGridTiles() {
        tileNodes.removeAll()
        for rank in 0..<8 {
            for file in 0..<8 {
                let sq = ChessSquare(file: file, rank: rank)
                let tile = SKSpriteNode(
                    color: sq.isLightSquare ? PixelPalette.boardLight : PixelPalette.boardDark,
                    size: CGSize(width: tileSize, height: tileSize)
                )
                tile.position = squareCenter(for: sq)
                tile.zPosition = 3
                worldNode.addChild(tile)
                tileNodes.append(tile)
            }
        }
    }

    private func buildCapturedTrays(frameLeft: CGFloat, frameBottom: CGFloat, frameWidth: CGFloat, frameHeight: CGFloat) {
        let iconSize = CGSize(width: 17, height: 28)
        let provider: (PieceKind, PieceColor) -> SKTexture? = { kind, color in
            ChessSpriteAssets.miniTrayTexture(kind: kind, color: color)
        }

        let trayBarHeight: CGFloat = 28
        let topY = frameBottom + frameHeight + 19
        let bottomY = frameBottom - 19

        // Subtle recessed tray strips above & below board
        for yPos in [topY, bottomY] {
            let barRect = CGRect(x: frameLeft, y: yPos - trayBarHeight * 0.5, width: frameWidth, height: trayBarHeight)
            let bar = SKShapeNode(rect: barRect, cornerRadius: 6)
            bar.fillColor = UIColor(red: 0.07, green: 0.13, blue: 0.18, alpha: 0.72)
            bar.strokeColor = PixelPalette.woodBevel.withAlphaComponent(0.55)
            bar.lineWidth = 1
            bar.zPosition = 18
            worldNode.addChild(bar)
        }

        let lightTrayY = isBoardFlipped ? bottomY : topY
        let darkTrayY = isBoardFlipped ? topY : bottomY

        // Cream pieces lost by Cream side
        lightCapturedTray = CapturedTray(
            capturedColor: .light,
            iconSize: iconSize,
            overlap: 0.65,
            pixelUnit: pixelUnit,
            iconProvider: provider
        )
        lightCapturedTray.position = CGPoint(x: frameLeft + 16, y: lightTrayY - 2)
        lightCapturedTray.zPosition = 20
        worldNode.addChild(lightCapturedTray)

        let topAdv = SKLabelNode(text: "")
        topAdv.fontName = "Menlo-Bold"
        topAdv.fontSize = 12
        topAdv.fontColor = PixelPalette.creamLight
        topAdv.horizontalAlignmentMode = .right
        topAdv.verticalAlignmentMode = .center
        topAdv.position = CGPoint(x: frameLeft + frameWidth - 10, y: topY)
        topAdv.zPosition = 20
        worldNode.addChild(topAdv)
        topAdvantageLabel = topAdv

        // Brown pieces lost by Brown side
        darkCapturedTray = CapturedTray(
            capturedColor: .dark,
            iconSize: iconSize,
            overlap: 0.65,
            pixelUnit: pixelUnit,
            iconProvider: provider
        )
        darkCapturedTray.position = CGPoint(x: frameLeft + 16, y: darkTrayY - 2)
        darkCapturedTray.zPosition = 20
        worldNode.addChild(darkCapturedTray)

        let bottomAdv = SKLabelNode(text: "")
        bottomAdv.fontName = "Menlo-Bold"
        bottomAdv.fontSize = 12
        bottomAdv.fontColor = PixelPalette.goldBright
        bottomAdv.horizontalAlignmentMode = .right
        bottomAdv.verticalAlignmentMode = .center
        bottomAdv.position = CGPoint(x: frameLeft + frameWidth - 10, y: bottomY)
        bottomAdv.zPosition = 20
        worldNode.addChild(bottomAdv)
        bottomAdvantageLabel = bottomAdv
    }

    // MARK: - Board Synchronization

    func syncBoardImmediately(from state: ChessBoardState) {
        ensureBuilt()
        animationGeneration += 1
        isAnimatingMove = false
        cancelActiveDrag(snapBack: false)
        animator.reset()

        clearLegalMoveMarkers()
        clearLastMoveHighlights()
        clearCheckHighlight()

        for (_, animated) in pieceNodes {
            animated.node.removeAllActions()
            animated.node.removeFromParent()
        }
        pieceNodes.removeAll()
        pieceSquareMap.removeAll()

        for idx in 0..<64 {
            guard let piece = state.squares[idx] else { continue }
            let sq = ChessSquare(file: idx % 8, rank: idx / 8)
            spawnPieceNode(piece, at: sq)
        }

        lightCapturedTray.restore(state.capturedByDark)
        darkCapturedTray.restore(state.capturedByLight)
        updateAdvantageLabels()

        if let last = state.lastMove {
            showLastMoveHighlights(from: last.from, to: last.to)
        }
        if let checkedColor = state.status.inCheckColor, let kSq = state.kingSquare(for: checkedColor) {
            showCheckHighlight(at: kSq)
        }
    }

    private func spawnPieceNode(_ piece: ChessPiece, at square: ChessSquare) {
        let tex = ChessSpriteAssets.pieceTexture(kind: piece.kind, color: piece.color)
        // Exact 68:112 aspect ratio (30 x 49) preserving natural height hierarchy & straight alignment
        let node = SKSpriteNode(texture: tex, size: CGSize(width: 30, height: 49))
        node.anchorPoint = CGPoint(x: 0.5, y: 0)
        node.position = pieceBottomCenter(for: square)
        node.zPosition = 12 + CGFloat(7 - visualRank(for: square)) * 0.1
        worldNode.addChild(node)

        let animated = AnimatedPiece(node: node, kind: piece.kind, color: piece.color)
        pieceNodes[piece.id] = animated
        pieceSquareMap[piece.id] = square
    }

    // MARK: - Selection, Illegal Nudge & Legal Move Highlights

    func showSelection(pieceID: UUID?, legalMoves: [ChessMove]) {
        ensureBuilt()
        clearLegalMoveMarkers()

        if let pieceID, let animated = pieceNodes[pieceID] {
            animator.select(animated)
        } else {
            animator.deselect()
        }

        for move in legalMoves {
            legalDestinationSquares.insert(move.to)
            let isCap = move.isCapture
            let tex = isCap ? ChessSpriteAssets.captureTargetTexture : ChessSpriteAssets.legalDotTexture
            let markerSize = isCap ? CGSize(width: tileSize, height: tileSize) : CGSize(width: 16, height: 16)
            let marker = SKSpriteNode(texture: tex, size: markerSize)
            marker.position = squareCenter(for: move.to)
            marker.zPosition = isCap ? 15 : 9
            marker.alpha = isCap ? 0.92 : 0.85
            worldNode.addChild(marker)
            legalMarkerNodes.append(marker)
        }
    }

    /// Subtle horizontal wiggle when a player taps a piece that has 0 legal moves (e.g., pinned or in check).
    func nudgeBlockedPiece(pieceID: UUID, kingSquare: ChessSquare?) {
        ensureBuilt()
        if let anim = pieceNodes[pieceID] {
            let n = anim.node
            let baseX = n.position.x
            n.removeAction(forKey: "nudge")
            n.run(.sequence([
                .moveTo(x: baseX - 3, duration: 0.04),
                .moveTo(x: baseX + 3, duration: 0.05),
                .moveTo(x: baseX - 2, duration: 0.04),
                .moveTo(x: baseX, duration: 0.04)
            ]), withKey: "nudge")
        }
        if let kingSquare {
            PixelFX.ring(
                at: squareCenter(for: kingSquare),
                tileSize: tileSize,
                color: PixelPalette.checkRed,
                pixelUnit: pixelUnit,
                in: worldNode
            )
        }
        Haptics.notification(.warning)
    }

    func clearSelectionAndMarkers() {
        ensureBuilt()
        animator.deselect()
        clearLegalMoveMarkers()
    }

    private func clearLegalMoveMarkers() {
        for m in legalMarkerNodes { m.removeFromParent() }
        legalMarkerNodes.removeAll()
        legalDestinationSquares.removeAll()
    }

    private func showLastMoveHighlights(from: ChessSquare, to: ChessSquare) {
        clearLastMoveHighlights()
        for sq in [from, to] {
            let tint = SKSpriteNode(color: PixelPalette.moveAmber, size: CGSize(width: tileSize, height: tileSize))
            tint.alpha = sq.isLightSquare ? 0.42 : 0.34
            tint.position = squareCenter(for: sq)
            tint.zPosition = 6
            worldNode.addChild(tint)
            lastMoveNodes.append(tint)
        }
    }

    private func clearLastMoveHighlights() {
        for n in lastMoveNodes { n.removeFromParent() }
        lastMoveNodes.removeAll()
    }

    private func showCheckHighlight(at square: ChessSquare) {
        clearCheckHighlight()
        let node = SKSpriteNode(
            texture: ChessSpriteAssets.checkFrameTexture,
            size: CGSize(width: tileSize, height: tileSize)
        )
        node.position = squareCenter(for: square)
        node.zPosition = 8
        worldNode.addChild(node)
        node.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.45, duration: 0.45),
            .fadeAlpha(to: 1.0, duration: 0.45)
        ])), withKey: "pulse")
        checkHighlightNode = node
    }

    private func clearCheckHighlight() {
        checkHighlightNode?.removeAllActions()
        checkHighlightNode?.removeFromParent()
        checkHighlightNode = nil
    }

    // MARK: - Move Execution & Signature Animations

    func animateMove(_ move: ChessMove, resultingState: ChessBoardState, completion: @escaping () -> Void) {
        ensureBuilt()
        let currentGen = animationGeneration
        isAnimatingMove = true
        cancelActiveDrag(snapBack: false)
        clearLegalMoveMarkers()
        clearCheckHighlight()
        showLastMoveHighlights(from: move.from, to: move.to)

        guard let attacker = pieceNodes[move.movedPiece.id] else {
            syncBoardImmediately(from: resultingState)
            completion()
            return
        }

        let destPos = pieceBottomCenter(for: move.to)
        pieceSquareMap[move.movedPiece.id] = move.to

        let trays: [CapturedTray] = [lightCapturedTray, darkCapturedTray]

        let afterPrimaryMotion: () -> Void = { [weak self] in
            guard let self, self.animationGeneration == currentGen else { return }

            if let promoKind = move.promotion {
                let promoTex = ChessSpriteAssets.pieceTexture(kind: promoKind, color: attacker.color)
                let promotedAnimated = AnimatedPiece(node: attacker.node, kind: promoKind, color: attacker.color)
                self.pieceNodes[move.movedPiece.id] = promotedAnimated
                self.animator.promote(promotedAnimated, toTexture: promoTex) { [weak self] in
                    self?.handlePostMoveStatus(move: move, state: resultingState, generation: currentGen, completion: completion)
                }
            } else {
                self.handlePostMoveStatus(move: move, state: resultingState, generation: currentGen, completion: completion)
            }
        }

        // Castling special coordinated King + Rook animation
        if move.isCastlingKingside || move.isCastlingQueenside {
            let rookFromFile = move.isCastlingKingside ? 7 : 0
            let rookToFile = move.isCastlingKingside ? 5 : 3
            let rookDestSq = ChessSquare(file: rookToFile, rank: move.from.rank)
            if let rookEntry = pieceNodes.first(where: { pieceSquareMap[$0.key] == ChessSquare(file: rookFromFile, rank: move.from.rank) }) {
                pieceSquareMap[rookEntry.key] = rookDestSq
                AudioManager.shared.play(.pop)
                animator.castle(
                    king: attacker,
                    kingDest: destPos,
                    rook: rookEntry.value,
                    rookDest: pieceBottomCenter(for: rookDestSq),
                    completion: afterPrimaryMotion
                )
                return
            }
        }

        // Capture animation (including En Passant)
        if let cap = move.capturedPiece, let victim = pieceNodes[cap.id] {
            pieceNodes.removeValue(forKey: cap.id)
            pieceSquareMap.removeValue(forKey: cap.id)

            if move.isEnPassant {
                AudioManager.shared.play(.bounce)
                animator.capture(attacker: attacker, victim: victim, trays: trays) { [weak self] in
                    guard let self, self.animationGeneration == currentGen else { return }
                    self.updateAdvantageLabels()
                    attacker.node.run(.move(to: destPos, duration: 0.08)) {
                        afterPrimaryMotion()
                    }
                }
            } else {
                AudioManager.shared.play(.bounce)
                animator.capture(attacker: attacker, victim: victim, trays: trays) { [weak self] in
                    guard let self, self.animationGeneration == currentGen else { return }
                    self.updateAdvantageLabels()
                    afterPrimaryMotion()
                }
            }
            return
        }

        // Standard movement animation per piece kind
        AudioManager.shared.play(.pop)
        animator.move(attacker, to: destPos, completion: afterPrimaryMotion)
    }

    private func handlePostMoveStatus(
        move: ChessMove,
        state: ChessBoardState,
        generation: Int,
        completion: @escaping () -> Void
    ) {
        guard animationGeneration == generation else { return }

        for (id, anim) in pieceNodes {
            if let sq = pieceSquareMap[id] {
                anim.node.zPosition = 12 + CGFloat(7 - visualRank(for: sq)) * 0.1
            }
        }

        switch state.status {
        case .check(let checkedColor):
            if let kingSq = state.kingSquare(for: checkedColor),
               let kingID = state.piece(at: kingSq)?.id,
               let kingAnim = pieceNodes[kingID] {
                showCheckHighlight(at: kingSq)
                AudioManager.shared.play(.switchOff)
                animator.check(king: kingAnim) { [weak self] in
                    guard let self, self.animationGeneration == generation else { return }
                    self.isAnimatingMove = false
                    completion()
                }
                return
            }

        case .checkmate(let winner):
            let loser = winner.opponent
            if let kingSq = state.kingSquare(for: loser),
               let kingID = state.piece(at: kingSq)?.id,
               let kingAnim = pieceNodes[kingID] {
                showCheckHighlight(at: kingSq)
                let attackerAnim = pieceNodes[move.movedPiece.id]
                AudioManager.shared.play(winner == playerColor ? .win : .error)
                animator.checkmate(king: kingAnim, attacker: attackerAnim) { [weak self] in
                    guard let self, self.animationGeneration == generation else { return }
                    self.isAnimatingMove = false
                    completion()
                }
                return
            }

        case .stalemate, .drawFiftyMove, .drawThreefoldRepetition, .drawInsufficientMaterial:
            let kings = [PieceColor.light, .dark].compactMap { color -> AnimatedPiece? in
                guard let sq = state.kingSquare(for: color),
                      let id = state.piece(at: sq)?.id else { return nil }
                return pieceNodes[id]
            }
            AudioManager.shared.play(.ding)
            animator.drawEffect(kings: kings) { [weak self] in
                guard let self, self.animationGeneration == generation else { return }
                self.isAnimatingMove = false
                completion()
            }
            return

        default:
            break
        }

        isAnimatingMove = false
        completion()
    }

    private func updateAdvantageLabels() {
        let playerCapturedMat = playerColor == .light ? darkCapturedTray.materialValue : lightCapturedTray.materialValue
        let aiCapturedMat = playerColor == .light ? lightCapturedTray.materialValue : darkCapturedTray.materialValue
        let diff = playerCapturedMat - aiCapturedMat
        bottomAdvantageLabel?.text = diff > 0 ? "+\(diff)" : ""
        topAdvantageLabel?.text = diff < 0 ? "+\(-diff)" : ""
    }

    // MARK: - Fluid Tap & Drag Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAnimatingMove, !isGamePaused, let touch = touches.first else { return }
        let pt = touch.location(in: worldNode)
        guard let sq = square(at: pt) else { return }

        touchStartSquare = sq
        touchStartPoint = pt
        isDraggingPiece = false

        // If user touches a friendly piece belonging to playerColor, select it immediately for snappy response
        if let entry = pieceNodes.first(where: { pieceSquareMap[$0.key] == sq && $0.value.color == playerColor }) {
            draggedPieceID = entry.key
            gameDelegate?.chessSceneDidTapSquare(sq)
        } else {
            draggedPieceID = nil
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAnimatingMove, !isGamePaused,
              let touch = touches.first,
              let draggedID = draggedPieceID,
              let anim = pieceNodes[draggedID] else { return }

        let pt = touch.location(in: worldNode)
        let dist = hypot(pt.x - touchStartPoint.x, pt.y - touchStartPoint.y)

        if !isDraggingPiece && dist > 6 {
            isDraggingPiece = true
            anim.node.removeAction(forKey: "select")
            anim.node.zPosition = 65
            anim.node.setScale(1.12)
        }

        if isDraggingPiece {
            anim.node.position = CGPoint(x: pt.x, y: pt.y - tileSize * 0.35)
            if let hoveredSq = square(at: pt), legalDestinationSquares.contains(hoveredSq) {
                showDragHover(at: hoveredSq)
            } else {
                clearDragHover()
            }
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isAnimatingMove, !isGamePaused, let touch = touches.first else {
            cancelActiveDrag(snapBack: true)
            return
        }
        let pt = touch.location(in: worldNode)
        let endSquare = square(at: pt)

        if isDraggingPiece, let startSq = touchStartSquare, let draggedID = draggedPieceID {
            clearDragHover()
            isDraggingPiece = false
            touchStartSquare = nil
            draggedPieceID = nil

            if let targetSq = endSquare, targetSq != startSq, legalDestinationSquares.contains(targetSq) {
                if let anim = pieceNodes[draggedID] {
                    anim.node.setScale(1.0)
                }
                let moved = gameDelegate?.chessSceneDidDragPiece(from: startSq, to: targetSq) ?? false
                if !moved {
                    snapPieceBack(id: draggedID, to: startSq)
                }
                return
            } else {
                snapPieceBack(id: draggedID, to: startSq)
                return
            }
        }

        // Standard tap handling when user didn't drag
        let wasFriendlyTouchStart = (draggedPieceID != nil)
        touchStartSquare = nil
        draggedPieceID = nil
        isDraggingPiece = false

        guard let tappedSq = endSquare else { return }
        // Friendly piece was already selected on `touchesBegan`; only forward `touchesEnded` for destination / empty / enemy squares
        if !wasFriendlyTouchStart {
            gameDelegate?.chessSceneDidTapSquare(tappedSq)
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cancelActiveDrag(snapBack: true)
    }

    private func snapPieceBack(id: UUID, to square: ChessSquare) {
        guard let anim = pieceNodes[id] else { return }
        let dest = pieceBottomCenter(for: square)
        let move = SKAction.move(to: dest, duration: 0.12)
        move.timingMode = .easeOut
        anim.node.run(.group([move, .scale(to: 1.0, duration: 0.12)])) { [weak self] in
            guard let self else { return }
            anim.node.zPosition = 12 + CGFloat(7 - self.visualRank(for: square)) * 0.1
            self.animator.select(anim)
        }
    }

    private func cancelActiveDrag(snapBack: Bool) {
        clearDragHover()
        if snapBack, isDraggingPiece, let id = draggedPieceID, let sq = touchStartSquare {
            snapPieceBack(id: id, to: sq)
        }
        touchStartSquare = nil
        draggedPieceID = nil
        isDraggingPiece = false
    }

    private func showDragHover(at square: ChessSquare) {
        if dragHoverNode == nil {
            let node = SKSpriteNode(
                texture: ChessSpriteAssets.selectionFrameTexture,
                size: CGSize(width: tileSize, height: tileSize)
            )
            node.zPosition = 16
            node.alpha = 0.85
            worldNode.addChild(node)
            dragHoverNode = node
        }
        dragHoverNode?.position = squareCenter(for: square)
    }

    private func clearDragHover() {
        dragHoverNode?.removeFromParent()
        dragHoverNode = nil
    }

    // MARK: - Geometry Helpers

    private func visualFile(for square: ChessSquare) -> Int {
        isBoardFlipped ? (7 - square.file) : square.file
    }

    private func visualRank(for square: ChessSquare) -> Int {
        isBoardFlipped ? (7 - square.rank) : square.rank
    }

    private func square(at pointInWorld: CGPoint) -> ChessSquare? {
        let localX = pointInWorld.x - boardOrigin.x
        let localY = pointInWorld.y - boardOrigin.y
        guard localX >= 0, localY >= 0 else { return nil }
        let dispFile = Int(floor(localX / tileSize))
        let dispRank = Int(floor(localY / tileSize))
        guard (0..<8).contains(dispFile), (0..<8).contains(dispRank) else { return nil }
        let file = isBoardFlipped ? (7 - dispFile) : dispFile
        let rank = isBoardFlipped ? (7 - dispRank) : dispRank
        let sq = ChessSquare(file: file, rank: rank)
        return sq.isValid ? sq : nil
    }

    private func squareCenter(for square: ChessSquare) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + (CGFloat(visualFile(for: square)) + 0.5) * tileSize,
            y: boardOrigin.y + (CGFloat(visualRank(for: square)) + 0.5) * tileSize
        )
    }

    private func pieceBottomCenter(for square: ChessSquare) -> CGPoint {
        CGPoint(
            x: boardOrigin.x + (CGFloat(visualFile(for: square)) + 0.5) * tileSize,
            y: boardOrigin.y + CGFloat(visualRank(for: square)) * tileSize + 1
        )
    }
}
