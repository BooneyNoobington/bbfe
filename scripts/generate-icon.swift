// Rebuild with: swift -module-cache-path /tmp/bbfe-icon-cache scripts/generate-icon.swift
// Run from the repository root. No third-party assets or libraries are required.
import AppKit
import Foundation

let output = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("Apple/BBFE/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func render(size: Int, mac: Bool) throws {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                                  bitsPerSample: 8, samplesPerPixel: mac ? 4 : 3, hasAlpha: mac,
                                  isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let scale = CGFloat(size) / 1024
    let transform = NSAffineTransform()
    transform.scale(by: scale)
    transform.concat()
    let inset: CGFloat = mac ? 64 : 0
    let rect = NSRect(x: inset, y: inset, width: 1024 - 2 * inset, height: 1024 - 2 * inset)
    let background = NSBezierPath(roundedRect: rect, xRadius: mac ? 196 : 0, yRadius: mac ? 196 : 0)
    NSColor(srgbRed: 0.071, green: 0.118, blue: 0.176, alpha: 1).setFill()
    background.fill()
    // Coordinates become a lower-case b: a nod to the original cipher table.
    let points: [(Int, Int)] = [(0, 3), (0, 2), (0, 1), (0, 0), (1, 2), (2, 2), (2, 1), (2, 0), (1, 0)]
    for (column, row) in points {
        let point = NSRect(x: 270 + CGFloat(column) * 158, y: 240 + CGFloat(row) * 146, width: 112, height: 112)
        let shape = NSBezierPath(roundedRect: point, xRadius: 27, yRadius: 27)
        if column == 0 && row == 3 {
            NSColor(srgbRed: 0.933, green: 0.463, blue: 0.278, alpha: 1).setFill()
        } else {
            NSColor(srgbRed: 0.930, green: 0.922, blue: 0.882, alpha: 1).setFill()
        }
        shape.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    let name = mac ? "mac-\(size).png" : "ios-1024.png"
    try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent(name))
}

try render(size: 1024, mac: false)
var images: [[String: Any]] = [["filename": "ios-1024.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"]]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let pixels = size * scale
        try render(size: pixels, mac: true)
        images.append(["filename": "mac-\(pixels).png", "idiom": "mac", "scale": "\(scale)x", "size": "\(size)x\(size)"])
    }
}
let manifest: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: manifest, options: [.prettyPrinted, .sortedKeys])
    .write(to: output.appendingPathComponent("Contents.json"))
print("Generated BBFE app icons.")
