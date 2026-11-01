import SwiftUI

// MARK: - Pixel Heart View
// Retro 8-bit / 16-bit arcade pixel heart with full and empty states.
// Matches the CheerUp! arcade design and pixel health reference.

struct PixelHeartView: View {
    let isFilled: Bool
    var size: CGFloat = 24

    // 13 columns x 11 rows:
    // . = transparent
    // B = dark outer border (#240711)
    // R = vibrant arcade crimson (#FF2E55)
    // S = deep red inner shadow (#96102A)
    // W = white highlight shine (#FFFFFF)
    private static let grid: [String] = [
        "..BBB...BBB..",
        ".BSRRB.BRRRB.",
        "BSWWRRBRRRRRB",
        "BSWWRRRRRRRRB",
        "BSRRRRRRRRRSB",
        ".BSRRRRRRRSB.",
        "..BSRRRRRSB..",
        "...BSRRRSB...",
        "....BSRSB....",
        ".....BSB.....",
        "......B......"
    ]

    var body: some View {
        Canvas { context, canvasSize in
            let cols = 13
            let rows = 11
            let pixelWidth = canvasSize.width / CGFloat(cols)
            let pixelHeight = canvasSize.height / CGFloat(rows)
            let pixelSize = min(pixelWidth, pixelHeight)

            let offsetX = (canvasSize.width - CGFloat(cols) * pixelSize) / 2
            let offsetY = (canvasSize.height - CGFloat(rows) * pixelSize) / 2

            let borderColor = isFilled ? Color(hex: 0x240711) : Color(hex: 0x340E1B)
            let shadowColor = isFilled ? Color(hex: 0x99122C) : Color(hex: 0x240913).opacity(0.4)
            let fillColor = isFilled ? Color(hex: 0xFF2E55) : Color(hex: 0x1A060E).opacity(0.35)
            let shineColor = isFilled ? Color.white : Color.white.opacity(0.6)

            for (rIndex, row) in Self.grid.enumerated() {
                for (cIndex, char) in row.enumerated() {
                    guard char != "." else { continue }

                    let rect = CGRect(
                        x: offsetX + CGFloat(cIndex) * pixelSize,
                        y: offsetY + CGFloat(rIndex) * pixelSize,
                        width: pixelSize + 0.2, // slight overlap eliminates seam gap artifacts
                        height: pixelSize + 0.2
                    )

                    let color: Color
                    switch char {
                    case "B":
                        color = borderColor
                    case "W":
                        color = shineColor
                    case "S":
                        color = shadowColor
                    case "R":
                        color = fillColor
                    default:
                        continue
                    }

                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: size, height: size * (11.0 / 13.0))
        .shadow(color: isFilled ? Color(hex: 0xFF2E55).opacity(0.5) : .clear, radius: 4, x: 0, y: 1)
        .scaleEffect(isFilled ? 1.0 : 0.92)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isFilled)
        .accessibilityLabel(isFilled ? "Full heart" : "Empty heart")
    }
}

#Preview {
    HStack(spacing: 12) {
        PixelHeartView(isFilled: true, size: 36)
        PixelHeartView(isFilled: true, size: 36)
        PixelHeartView(isFilled: false, size: 36)
    }
    .padding()
    .background(Color(hex: 0x1A1B2F))
}
