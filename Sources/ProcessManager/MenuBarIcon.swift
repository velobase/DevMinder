import AppKit

enum MenuBarIcon {
    static func make(active: Bool) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        let color = active ? NSColor.systemOrange : NSColor.secondaryLabelColor

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(origin: .zero, size: size))

        let rect = CGRect(x: 3, y: 3, width: 12, height: 12)

        context.setStrokeColor(color.withAlphaComponent(active ? 0.95 : 0.78).cgColor)
        context.setLineWidth(1.8)
        context.setLineCap(.round)
        context.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: 5.2,
            startAngle: CGFloat.pi * 0.12,
            endAngle: CGFloat.pi * 1.68,
            clockwise: false
        )
        context.strokePath()

        let nodes = [
            CGPoint(x: 5.6, y: 9.9),
            CGPoint(x: 9.2, y: 11.4),
            CGPoint(x: 12.6, y: 7.4)
        ]

        context.setStrokeColor(NSColor.labelColor.withAlphaComponent(active ? 0.62 : 0.36).cgColor)
        context.setLineWidth(1.15)
        context.move(to: nodes[0])
        context.addLine(to: nodes[1])
        context.addLine(to: nodes[2])
        context.strokePath()

        for (index, point) in nodes.enumerated() {
            let nodeColor = active && index == 2 ? NSColor.systemOrange : color
            let radius: CGFloat = index == 1 ? 1.9 : 1.65
            let dot = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)

            context.setFillColor(nodeColor.cgColor)
            context.fillEllipse(in: dot)
            context.setStrokeColor(NSColor.windowBackgroundColor.withAlphaComponent(0.85).cgColor)
            context.setLineWidth(0.65)
            context.strokeEllipse(in: dot)
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
