import AppKit

enum MenuBarIcon {
    enum State {
        case idle
        case active
        case paused
    }

    static func make(state: State) -> NSImage {
        if state == .paused {
            return makePausedIcon()
        }

        return makeActivityIcon(active: state == .active)
    }

    private static func makeActivityIcon(active: Bool) -> NSImage {
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

    private static func makePausedIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        let color = NSColor.secondaryLabelColor

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(origin: .zero, size: size))

        let circle = CGRect(x: 3, y: 3, width: 12, height: 12)
        context.setFillColor(color.withAlphaComponent(0.16).cgColor)
        context.fillEllipse(in: circle)
        context.setStrokeColor(color.withAlphaComponent(0.78).cgColor)
        context.setLineWidth(1.45)
        context.strokeEllipse(in: circle)

        let barWidth: CGFloat = 1.8
        let barHeight: CGFloat = 6.6
        let barY = (size.height - barHeight) / 2
        let leftBar = CGRect(x: 7.0, y: barY, width: barWidth, height: barHeight)
        let rightBar = CGRect(x: 10.0, y: barY, width: barWidth, height: barHeight)

        context.setFillColor(color.withAlphaComponent(0.92).cgColor)
        context.fill(leftBar)
        context.fill(rightBar)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
