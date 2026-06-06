import AppKit

enum MenuBarIcon {
    enum State {
        case idle
        case active
        case paused
    }

    static func make(state: State) -> NSImage {
        switch state {
        case .idle:
            return makeActivityIcon(color: .white)
        case .active:
            return makeActivityIcon(color: .systemOrange)
        case .paused:
            return makePauseIcon(color: .secondaryLabelColor)
        }
    }

    private static func makeActivityIcon(color: NSColor) -> NSImage {
        let size = NSSize(width: 23, height: 23)
        let image = NSImage(size: size)

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(origin: .zero, size: size))

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(2.2)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.addArc(
            center: CGPoint(x: 11.5, y: 11.5),
            radius: 6.75,
            startAngle: CGFloat.pi * 0.12,
            endAngle: CGFloat.pi * 1.68,
            clockwise: false
        )
        context.strokePath()

        let nodes = [
            CGPoint(x: 7.05, y: 12.45),
            CGPoint(x: 11.75, y: 14.35),
            CGPoint(x: 16.10, y: 9.40)
        ]

        context.setLineWidth(1.48)
        context.move(to: nodes[0])
        context.addLine(to: nodes[1])
        context.addLine(to: nodes[2])
        context.strokePath()

        for (index, point) in nodes.enumerated() {
            let radius: CGFloat = index == 1 ? 2.35 : 2.1
            let dot = CGRect(
                x: point.x - radius,
                y: point.y - radius,
                width: radius * 2,
                height: radius * 2
            )

            context.setFillColor(color.cgColor)
            context.fillEllipse(in: dot)
        }

        image.unlockFocus()
        image.isTemplate = false
        return image
    }

    private static func makePauseIcon(color: NSColor) -> NSImage {
        let size = NSSize(width: 23, height: 23)
        let image = NSImage(size: size)

        image.lockFocus()
        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.clear(CGRect(origin: .zero, size: size))

        let barWidth: CGFloat = 2.8
        let barHeight: CGFloat = 12.2
        let barY = (size.height - barHeight) / 2
        let leftBar = CGRect(x: 7.6, y: barY, width: barWidth, height: barHeight)
        let rightBar = CGRect(x: 12.4, y: barY, width: barWidth, height: barHeight)

        context.setFillColor(color.cgColor)
        context.fill(leftBar)
        context.fill(rightBar)

        image.unlockFocus()
        image.isTemplate = false
        return image
    }
}
