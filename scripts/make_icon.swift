import Cocoa

let outDir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

func render(_ px: Int) -> Data? {
    guard let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                     bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                     colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    let r = NSRect(x: 0, y: 0, width: s, height: s).insetBy(dx: s * 0.06, dy: s * 0.06)
    let path = NSBezierPath(roundedRect: r, xRadius: s * 0.22, yRadius: s * 0.22)
    NSGradient(colors: [NSColor(red: 0.20, green: 0.45, blue: 0.98, alpha: 1),
                        NSColor(red: 0.40, green: 0.25, blue: 0.90, alpha: 1)])?.draw(in: path, angle: -90)
    let cfg = NSImage.SymbolConfiguration(pointSize: s * 0.5, weight: .regular)
        .applying(NSImage.SymbolConfiguration(paletteColors: [.white]))
    if let sym = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let sz = sym.size
        sym.draw(in: NSRect(x: (s - sz.width) / 2, y: (s - sz.height) / 2, width: sz.width, height: sz.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

let sizes: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32), ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256), ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in sizes {
    if let d = render(px) { try? d.write(to: URL(fileURLWithPath: "\(outDir)/\(name).png")) }
}
