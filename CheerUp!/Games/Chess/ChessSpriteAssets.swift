import SpriteKit
import UIKit

/// Loads and caches the individual, reusable brown-and-cream pixel-art piece sprites
/// from `Assets.xcassets` (`chess_<kind>_<color>`) with `.nearest` filtering so every
/// piece silhouette is crisp, straight, and bottom-baseline aligned.
@MainActor
enum ChessSpriteAssets {
    private static var pieceTextureCache: [String: SKTexture] = [:]
    private static var pieceImageCache: [String: UIImage] = [:]
    private static var miniTextureCache: [String: SKTexture] = [:]
    private static var cachedSelectionFrame: SKTexture?
    private static var cachedCheckFrame: SKTexture?
    private static var cachedLegalDot: SKTexture?
    private static var cachedCaptureFrame: SKTexture?

    // MARK: - Public Accessors

    static func pieceTexture(kind: PieceKind, color: PieceColor) -> SKTexture {
        let key = "chess_\(kind.rawValue)_\(color.rawValue)"
        if let tex = pieceTextureCache[key] { return tex }
        let img = pieceImage(kind: kind, color: color)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        pieceTextureCache[key] = tex
        return tex
    }

    static func pieceImage(kind: PieceKind, color: PieceColor) -> UIImage {
        let key = "chess_\(kind.rawValue)_\(color.rawValue)"
        if let cached = pieceImageCache[key] { return cached }
        if let assetImage = UIImage(named: key) {
            pieceImageCache[key] = assetImage
            return assetImage
        }
        // Fallback symmetrical pixel grid for unit test environments without asset catalog bundle
        let fallback = renderPixelGrid(symmetricGrid(for: kind), palette: palette(for: color), scale: 4)
        pieceImageCache[key] = fallback
        return fallback
    }

    static func miniTrayTexture(kind: PieceKind, color: PieceColor) -> SKTexture {
        let key = "mini_\(kind.rawValue)_\(color.rawValue)"
        if let tex = miniTextureCache[key] { return tex }
        let img = pieceImage(kind: kind, color: color)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        miniTextureCache[key] = tex
        return tex
    }

    /// Gold 4-corner pixel selection frame matching the reference chessboard highlight.
    static var selectionFrameTexture: SKTexture {
        if let cachedSelectionFrame { return cachedSelectionFrame }
        let grid: [String] = [
            "YYYYYY....YYYYYY",
            "YGGGGY....YGGGGY",
            "YG..G......G..GY",
            "YG............GY",
            "Y..............Y",
            "Y..............Y",
            "................",
            "................",
            "................",
            "................",
            "D..............D",
            "D..............D",
            "DG............GD",
            "DG..G......G..GD",
            "DGGGGD....DGGGGD",
            "DDDDDD....DDDDDD"
        ]
        let pal: [Character: UIColor] = [
            "Y": PixelPalette.goldBright,
            "G": PixelPalette.gold,
            "D": UIColor(red: 0.72, green: 0.48, blue: 0.12, alpha: 1)
        ]
        let img = renderPixelGrid(grid, palette: pal, scale: 4)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        cachedSelectionFrame = tex
        return tex
    }

    /// Crisp red alert corner frame for a checked king square.
    static var checkFrameTexture: SKTexture {
        if let cachedCheckFrame { return cachedCheckFrame }
        let grid: [String] = [
            "RRRRRRRRRRRRRRRR",
            "RLLLLLLLLLLLLLLR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RL............LR",
            "RLLLLLLLLLLLLLLR",
            "RRRRRRRRRRRRRRRR"
        ]
        let pal: [Character: UIColor] = [
            "R": PixelPalette.checkRed,
            "L": UIColor(red: 1.0, green: 0.48, blue: 0.40, alpha: 0.85)
        ]
        let img = renderPixelGrid(grid, palette: pal, scale: 4)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        cachedCheckFrame = tex
        return tex
    }

    /// Pixel-square legal destination marker.
    static var legalDotTexture: SKTexture {
        if let cachedLegalDot { return cachedLegalDot }
        let grid: [String] = [
            "..OOOO..",
            ".OHBBHO.",
            "OHBBBBBO",
            "OBBBBBSO",
            "OBBBBBSO",
            "OBBBBBSO",
            ".OBBSSO.",
            "..OOOO.."
        ]
        let pal: [Character: UIColor] = [
            "O": UIColor(red: 0.14, green: 0.07, blue: 0.04, alpha: 0.45),
            "H": UIColor(red: 1.00, green: 0.94, blue: 0.61, alpha: 0.92),
            "B": UIColor(red: 0.97, green: 0.77, blue: 0.28, alpha: 0.88),
            "S": UIColor(red: 0.76, green: 0.54, blue: 0.16, alpha: 0.88)
        ]
        let img = renderPixelGrid(grid, palette: pal, scale: 3)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        cachedLegalDot = tex
        return tex
    }

    /// Pixel capture-target corner brackets shown on squares occupied by a capturable enemy piece.
    static var captureTargetTexture: SKTexture {
        if let cachedCaptureFrame { return cachedCaptureFrame }
        let grid: [String] = [
            "RRRRR......RRRRR",
            "RGGGR......RGGGR",
            "RG..R......R..GR",
            "RG............GR",
            "R..............R",
            "................",
            "................",
            "................",
            "................",
            "................",
            "................",
            "R..............R",
            "RG............GR",
            "RG..R......R..GR",
            "RGGGR......RGGGR",
            "RRRRR......RRRRR"
        ]
        let pal: [Character: UIColor] = [
            "R": PixelPalette.checkRed,
            "G": PixelPalette.goldBright
        ]
        let img = renderPixelGrid(grid, palette: pal, scale: 4)
        let tex = SKTexture(image: img)
        tex.filteringMode = .nearest
        cachedCaptureFrame = tex
        return tex
    }

    // MARK: - Fallback Palettes & Symmetrical Grids

    private static func palette(for color: PieceColor) -> [Character: UIColor] {
        switch color {
        case .light:
            return [
                "O": PixelPalette.outline,
                "H": PixelPalette.creamLight,
                "B": PixelPalette.creamMid,
                "S": PixelPalette.creamDark
            ]
        case .dark:
            return [
                "O": PixelPalette.outline,
                "H": PixelPalette.brownLight,
                "B": PixelPalette.brownMid,
                "S": PixelPalette.brownDark
            ]
        }
    }

    private static func symmetricGrid(for kind: PieceKind) -> [String] {
        switch kind {
        case .king:
            return [
                "......OOOO......",
                "....OOOHBOOO....",
                "....OHBBBBBO....",
                "......OSSO......",
                "...OOOHBBOOOO...",
                "..OHHBBBBBBBBO..",
                "..OHBBBBBBBBBO..",
                "...OOBBBBBBSSO..",
                "....OOHBBBBSO...",
                "....OOBBBBBSO...",
                "....OOHBBBBSO...",
                "...OOHBBBBBBSO..",
                "..OOHBBBBBBBSSO.",
                "..OOSSSSSSSSSSO.",
                ".OOHBBBBBBBBBBBO",
                ".OSSSSSSSSSSSSSO"
            ]
        case .queen:
            return [
                "..OO..OOOO..OO..",
                ".OHBO.OHHO.OBHO.",
                "..OOBOOBBOOBOO..",
                "..OHBBBBBBBBHO..",
                "...OOBBBBBBSO...",
                "....OOHBBBBSO...",
                "....OOBBBBBSO...",
                "....OOHBBBBSO...",
                "...OOHBBBBBBSO..",
                "..OOHBBBBBBBSSO.",
                "..OOSSSSSSSSSSO.",
                ".OOHBBBBBBBBBBBO",
                ".OSSSSSSSSSSSSSO"
            ]
        case .rook:
            return [
                "..OOO.OOOO.OOO..",
                "..OHBOOBBOOBSO..",
                "..OHBBBBBBBBBO..",
                "...OOSSSSSSOO...",
                "...OHBBBBBBBO...",
                "...OOBBBBBBSO...",
                "...OHBBBBBBBO...",
                "...OOBBBBBBSO...",
                "..OOSSSSSSSSSO..",
                ".OOHBBBBBBBBBBO.",
                ".OSSSSSSSSSSSSO."
            ]
        case .bishop:
            return [
                "......OOOO......",
                ".....OHBBBO.....",
                "....OHBBBBBO....",
                "...OHBBBBOBSO...",
                "...OHBBBOBBSO...",
                "....OOSSSSOO....",
                "....OHBBBBBO....",
                "...OOHBBBBBBO...",
                "..OOSSSSSSSSSO..",
                ".OOHBBBBBBBBBBO.",
                ".OSSSSSSSSSSSSO."
            ]
        case .knight:
            return [
                ".....OOOOOO.....",
                "....OHBBBBBO....",
                "...OHBBBBBBBO...",
                "..OHBBBBBBBBBO..",
                "..OOSSO.OHBBBSO.",
                "......OOHBBBBSO.",
                "....OOHBBBBBBBO.",
                "..OOSSSSSSSSSO..",
                ".OOHBBBBBBBBBBO.",
                ".OSSSSSSSSSSSSO."
            ]
        case .pawn:
            return [
                ".....OOOOOO.....",
                "....OHBBBBBO....",
                "....OBBBBBBO....",
                ".....OOSSOO.....",
                "....OOHBBBSO....",
                "....OHBBBBBO....",
                "...OOHBBBBBBO...",
                "..OOSSSSSSSSSO..",
                "..OHBBBBBBBBBO..",
                "..OSSSSSSSSSSO.."
            ]
        }
    }

    private static func renderPixelGrid(
        _ rows: [String],
        palette: [Character: UIColor],
        scale: Int
    ) -> UIImage {
        let height = rows.count
        let width = rows.first?.count ?? 1
        let size = CGSize(width: width * scale, height: height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            let cg = ctx.cgContext
            cg.setShouldAntialias(false)
            cg.interpolationQuality = .none

            for (r, row) in rows.enumerated() {
                for (c, ch) in row.enumerated() {
                    guard let fill = palette[ch] else { continue }
                    fill.setFill()
                    cg.fill(CGRect(x: c * scale, y: r * scale, width: scale, height: scale))
                }
            }
        }
    }
}
