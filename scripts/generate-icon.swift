import AppKit
import Foundation

let root = CommandLine.arguments.dropFirst().first.map(URL.init(fileURLWithPath:)) ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let resources = root.appendingPathComponent("Resources", isDirectory: true)
let iconset = resources.appendingPathComponent("ProcessManager.iconset", isDirectory: true)

try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

struct IconSize {
    let filename: String
    let pixels: Int
}

let sizes = [
    IconSize(filename: "icon_16x16.png", pixels: 16),
    IconSize(filename: "icon_16x16@2x.png", pixels: 32),
    IconSize(filename: "icon_32x32.png", pixels: 32),
    IconSize(filename: "icon_32x32@2x.png", pixels: 64),
    IconSize(filename: "icon_128x128.png", pixels: 128),
    IconSize(filename: "icon_128x128@2x.png", pixels: 256),
    IconSize(filename: "icon_256x256.png", pixels: 256),
    IconSize(filename: "icon_256x256@2x.png", pixels: 512),
    IconSize(filename: "icon_512x512.png", pixels: 512),
    IconSize(filename: "icon_512x512@2x.png", pixels: 1024)
]

func drawIcon(pixels: Int) -> NSImage {
    let size = NSSize(width: pixels, height: pixels)
    let image = NSImage(size: size)

    image.lockFocus()
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    let scale = CGFloat(pixels)
    let bounds = CGRect(origin: .zero, size: CGSize(width: scale, height: scale))
    context.clear(bounds)

    let inset = scale * 0.08
    let baseRect = bounds.insetBy(dx: inset, dy: inset)
    let radius = scale * 0.22
    let basePath = CGPath(roundedRect: baseRect, cornerWidth: radius, cornerHeight: radius, transform: nil)

    context.saveGState()
    context.setShadow(offset: CGSize(width: 0, height: -scale * 0.025), blur: scale * 0.055, color: NSColor.black.withAlphaComponent(0.28).cgColor)
    context.addPath(basePath)
    context.setFillColor(NSColor(red: 0.07, green: 0.10, blue: 0.14, alpha: 1).cgColor)
    context.fillPath()
    context.restoreGState()

    context.saveGState()
    context.addPath(basePath)
    context.clip()

    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: [
            NSColor(red: 0.10, green: 0.17, blue: 0.24, alpha: 1).cgColor,
            NSColor(red: 0.04, green: 0.06, blue: 0.09, alpha: 1).cgColor
        ] as CFArray,
        locations: [0, 1]
    )
    context.drawLinearGradient(
        gradient!,
        start: CGPoint(x: baseRect.minX, y: baseRect.maxY),
        end: CGPoint(x: baseRect.maxX, y: baseRect.minY),
        options: []
    )

    context.setStrokeColor(NSColor.white.withAlphaComponent(0.12).cgColor)
    context.setLineWidth(max(1, scale * 0.012))
    context.addPath(basePath)
    context.strokePath()

    let ringRect = CGRect(x: scale * 0.25, y: scale * 0.25, width: scale * 0.50, height: scale * 0.50)
    context.setLineWidth(scale * 0.055)
    context.setLineCap(.round)
    context.setStrokeColor(NSColor(red: 0.20, green: 0.85, blue: 0.58, alpha: 1).cgColor)
    context.addArc(
        center: CGPoint(x: ringRect.midX, y: ringRect.midY),
        radius: ringRect.width * 0.5,
        startAngle: CGFloat.pi * 0.08,
        endAngle: CGFloat.pi * 1.52,
        clockwise: false
    )
    context.strokePath()

    context.setStrokeColor(NSColor(red: 1.00, green: 0.62, blue: 0.23, alpha: 1).cgColor)
    context.addArc(
        center: CGPoint(x: ringRect.midX, y: ringRect.midY),
        radius: ringRect.width * 0.5,
        startAngle: CGFloat.pi * 1.62,
        endAngle: CGFloat.pi * 1.96,
        clockwise: false
    )
    context.strokePath()

    let nodes = [
        CGPoint(x: scale * 0.33, y: scale * 0.58),
        CGPoint(x: scale * 0.50, y: scale * 0.69),
        CGPoint(x: scale * 0.67, y: scale * 0.46)
    ]

    context.setStrokeColor(NSColor.white.withAlphaComponent(0.70).cgColor)
    context.setLineWidth(scale * 0.026)
    context.move(to: nodes[0])
    context.addLine(to: nodes[1])
    context.addLine(to: nodes[2])
    context.strokePath()

    for (index, node) in nodes.enumerated() {
        let nodeRadius = scale * (index == 1 ? 0.052 : 0.046)
        let nodeRect = CGRect(
            x: node.x - nodeRadius,
            y: node.y - nodeRadius,
            width: nodeRadius * 2,
            height: nodeRadius * 2
        )
        context.setFillColor((index == 2 ? NSColor(red: 1.00, green: 0.62, blue: 0.23, alpha: 1) : NSColor(red: 0.20, green: 0.85, blue: 0.58, alpha: 1)).cgColor)
        context.fillEllipse(in: nodeRect)
        context.setStrokeColor(NSColor.white.withAlphaComponent(0.86).cgColor)
        context.setLineWidth(max(1, scale * 0.012))
        context.strokeEllipse(in: nodeRect)
    }

    let portSlot = CGRect(x: scale * 0.31, y: scale * 0.27, width: scale * 0.38, height: scale * 0.10)
    let slotPath = CGPath(roundedRect: portSlot, cornerWidth: scale * 0.045, cornerHeight: scale * 0.045, transform: nil)
    context.setFillColor(NSColor.black.withAlphaComponent(0.28).cgColor)
    context.addPath(slotPath)
    context.fillPath()

    context.setFillColor(NSColor.white.withAlphaComponent(0.82).cgColor)
    for index in 0..<3 {
        let dotSize = scale * 0.026
        let dotX = portSlot.minX + scale * 0.085 + CGFloat(index) * scale * 0.105
        let dotRect = CGRect(x: dotX, y: portSlot.midY - dotSize / 2, width: dotSize, height: dotSize)
        context.fillEllipse(in: dotRect)
    }

    context.restoreGState()
    image.unlockFocus()

    return image
}

for size in sizes {
    let image = drawIcon(pixels: size.pixels)

    guard
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else {
        fatalError("Could not render \(size.filename)")
    }

    try png.write(to: iconset.appendingPathComponent(size.filename))
}

print(iconset.path)
