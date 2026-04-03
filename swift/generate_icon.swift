#!/usr/bin/env swift

import Cocoa

func generateIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let s = CGFloat(size)

    // Rounded rectangle background with gradient
    let cornerRadius = s * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient: warm coral to deep rose
    let gradient = NSGradient(colors: [
        NSColor(red: 0.98, green: 0.45, blue: 0.35, alpha: 1.0),  // coral
        NSColor(red: 0.85, green: 0.22, blue: 0.40, alpha: 1.0),  // deep rose
    ])!
    gradient.draw(in: path, angle: -45)

    // Draw a stylized "A" letter with a currency accent
    let letterFont = NSFont.systemFont(ofSize: s * 0.55, weight: .bold)
    let letterAttrs: [NSAttributedString.Key: Any] = [
        .font: letterFont,
        .foregroundColor: NSColor.white,
    ]
    let letterStr = NSAttributedString(string: "A", attributes: letterAttrs)
    let letterSize = letterStr.size()
    let letterX = (s - letterSize.width) / 2.0 - s * 0.02
    let letterY = (s - letterSize.height) / 2.0 - s * 0.05
    letterStr.draw(at: NSPoint(x: letterX, y: letterY))

    // Small currency symbols scattered
    let smallFont = NSFont.systemFont(ofSize: s * 0.12, weight: .medium)
    let smallAttrs: [NSAttributedString.Key: Any] = [
        .font: smallFont,
        .foregroundColor: NSColor(white: 1.0, alpha: 0.5),
    ]

    // Ruble sign top-right area
    let ruble = NSAttributedString(string: "\u{20BD}", attributes: smallAttrs)
    ruble.draw(at: NSPoint(x: s * 0.72, y: s * 0.72))

    // Dirham (AED) - use "د" bottom-left
    let dirham = NSAttributedString(string: "د", attributes: smallAttrs)
    dirham.draw(at: NSPoint(x: s * 0.15, y: s * 0.15))

    // Dollar sign top-left
    let dollar = NSAttributedString(string: "$", attributes: smallAttrs)
    dollar.draw(at: NSPoint(x: s * 0.18, y: s * 0.68))

    image.unlockFocus()
    return image
}

func savePNG(_ image: NSImage, to path: String, size: Int) {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
    NSGraphicsContext.restoreGraphicsState()

    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: path))
}

// Generate all required sizes for macOS app icon
let sizes: [(points: Int, scale: Int)] = [
    (16, 1), (16, 2),
    (32, 1), (32, 2),
    (128, 1), (128, 2),
    (256, 1), (256, 2),
    (512, 1), (512, 2),
]

let outputDir = "AnnaExpenses/Assets.xcassets/AppIcon.appiconset"

for entry in sizes {
    let pixels = entry.points * entry.scale
    let image = generateIcon(size: pixels)
    let suffix = entry.scale > 1 ? "@\(entry.scale)x" : ""
    let filename = "icon_\(entry.points)x\(entry.points)\(suffix).png"
    let path = "\(outputDir)/\(filename)"
    savePNG(image, to: path, size: pixels)
    print("Generated \(filename) (\(pixels)x\(pixels))")
}

print("Done! Icon assets generated.")
