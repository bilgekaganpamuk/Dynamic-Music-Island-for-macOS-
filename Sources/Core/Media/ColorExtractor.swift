import Foundation
import AppKit
import SwiftUI
import CoreImage

/// High-performance color extractor that generates vibrant accent and secondary ambient colors from album artwork.
public final class ColorExtractor: Sendable {
    public static let shared = ColorExtractor()

    public init() {}

    /// Extracts dominant accent color and secondary background glow color from an NSImage.
    public func extractColors(from image: NSImage?) -> (accent: Color, secondary: Color) {
        guard let image = image,
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return (Color.accentColor, Color.purple.opacity(0.4))
        }

        let width = bitmap.pixelsWide
        let height = bitmap.pixelsHigh
        guard width > 0 && height > 0 else {
            return (Color.accentColor, Color.purple.opacity(0.4))
        }

        // Sample 16 points across the image to calculate dominant RGB
        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var sampleCount: CGFloat = 0

        let stepX = max(1, width / 4)
        let stepY = max(1, height / 4)

        for x in stride(from: 0, to: width, by: stepX) {
            for y in stride(from: 0, to: height, by: stepY) {
                if let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) {
                    // Ignore near-black or near-white background pixels to find vibrant content
                    let brightness = (color.redComponent + color.greenComponent + color.blueComponent) / 3.0
                    if brightness > 0.15 && brightness < 0.85 {
                        totalR += color.redComponent
                        totalG += color.greenComponent
                        totalB += color.blueComponent
                        sampleCount += 1
                    }
                }
            }
        }

        if sampleCount > 0 {
            let avgR = Double(totalR / sampleCount)
            let avgG = Double(totalG / sampleCount)
            let avgB = Double(totalB / sampleCount)

            let accent = Color(red: avgR, green: avgG, blue: avgB)
            let secondary = Color(
                red: min(1.0, avgR * 1.2),
                green: min(1.0, avgG * 0.8),
                blue: min(1.0, avgB * 1.3)
            ).opacity(0.6)

            return (accent, secondary)
        }

        return (Color.accentColor, Color.purple.opacity(0.4))
    }
}
