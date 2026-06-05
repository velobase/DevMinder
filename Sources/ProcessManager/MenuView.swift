import AppKit
import ProcessManagerCore
import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var monitor: ProcessMonitor
    @EnvironmentObject private var navigation: AppNavigation
    @State private var showsIdlePorts = false

    private var enabledPorts: [PortWatch] {
        monitor.ports.filter(\.enabled)
    }

    private var activePortRows: [PortRowData] {
        enabledPorts.compactMap { port in
            let processes = monitor.processes(for: port.port)
            guard !processes.isEmpty else {
                return nil
            }

            return PortRowData(port: port, processes: processes)
        }
    }

    private var idlePorts: [PortWatch] {
        enabledPorts.filter { monitor.processes(for: $0.port).isEmpty }
    }

    private var enabledRules: [ProcessRule] {
        monitor.rules.filter { $0.enabled && !$0.pattern.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ZStack {
            switch navigation.screen {
            case .dashboard:
                dashboard
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .settings:
                SettingsView(
                    onBack: { navigation.showDashboard() },
                    onSave: { navigation.showDashboard() }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(AppPalette.windowBackground)
        .frame(minWidth: 520, idealWidth: 540, maxWidth: .infinity, minHeight: 560, idealHeight: 680, maxHeight: .infinity)
        .preferredColorScheme(monitor.appearanceMode.colorScheme)
        .animation(.spring(response: 0.30, dampingFraction: 0.90), value: navigation.screen)
    }

    private var dashboard: some View {
        VStack(alignment: .leading, spacing: 0) {
            statusHeader

            if let errorMessage = monitor.errorMessage {
                ErrorBanner(message: errorMessage)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    SectionHeader(
                        title: monitor.t(.portMonitoring),
                        systemImage: "network",
                        count: enabledPorts.count
                    )

                    portList

                    SectionHeader(
                        title: monitor.t(.activeRecognition),
                        systemImage: "scope",
                        count: monitor.ruleMatches.count
                    )
                    .padding(.top, 2)

                    ruleList
                }
                .padding(16)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: monitor.activeCount)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: monitor.isScanning)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: monitor.portProcesses)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: monitor.ruleMatches)
        .animation(.spring(response: 0.28, dampingFraction: 0.88), value: showsIdlePorts)
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                StatusMark(
                    symbol: monitor.statusSymbol,
                    color: statusColor
                )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(monitor.t(.appName))
                            .font(.title3.weight(.semibold))
                            .lineLimit(1)

                        StatusPill(text: monitor.statusTitle, color: statusColor)
                    }

                    HStack(spacing: 7) {
                        Text(monitor.statusMessage)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if let lastScanDate = monitor.lastScanDate {
                            Text("·")
                            Text(lastScanDate, style: .time)
                                .monospacedDigit()
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 10)

                headerActions
            }

            HStack(spacing: 8) {
                MetricChip(value: "\(monitor.activeCount)", label: monitor.t(.processesTab), color: statusColor)
                MetricChip(value: "\(enabledPorts.count)", label: monitor.t(.portsTab), color: .blue)
                MetricChip(value: "\(enabledRules.count)", label: monitor.t(.activeRecognition), color: .purple)
            }
        }
        .padding(16)
        .background {
            Rectangle()
                .fill(AppPalette.headerBackground)
        }
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var headerActions: some View {
        HStack(spacing: 6) {
            Button {
                monitor.scanNow()
            } label: {
                ScanningGlyph(active: monitor.isScanning)
            }
            .buttonStyle(ToolbarIconButtonStyle(tint: AppPalette.idleColor))
            .disabled(!monitor.monitoringEnabled || monitor.isScanning)
            .help(monitor.t(.scan))

            Button {
                monitor.toggleMonitoring()
            } label: {
                Image(systemName: monitor.monitoringEnabled ? "pause.fill" : "play.fill")
            }
            .buttonStyle(ToolbarIconButtonStyle(tint: AppPalette.idleColor))
            .help(monitor.monitoringEnabled ? monitor.t(.pauseMonitoring) : monitor.t(.resumeMonitoring))

            Button {
                AppActions.showSettings()
            } label: {
                Image(systemName: "slider.horizontal.3")
            }
            .buttonStyle(ToolbarIconButtonStyle(tint: .secondary))
            .help(monitor.t(.settings))

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(ToolbarIconButtonStyle(tint: .red))
            .help(monitor.t(.quit))
        }
    }

    @ViewBuilder
    private var portList: some View {
        if enabledPorts.isEmpty {
            EmptyState(text: monitor.t(.noEnabledPorts), systemImage: "network.slash")
                .transition(.opacity)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(activePortRows) { row in
                    PortStatusRow(port: row.port, processes: row.processes)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                if !idlePorts.isEmpty {
                    IdlePortsDisclosure(ports: idlePorts, isExpanded: $showsIdlePorts)
                        .transition(.opacity)
                }
            }
        }
    }

    @ViewBuilder
    private var ruleList: some View {
        if !monitor.monitoringEnabled {
            EmptyState(text: monitor.t(.monitoringPaused), systemImage: "pause.circle")
                .transition(.opacity)
        } else if monitor.ruleMatches.isEmpty {
            EmptyState(text: monitor.t(.noRuleMatches), systemImage: "checkmark.circle")
                .transition(.opacity)
        } else {
            LazyVStack(spacing: 8) {
                ForEach(monitor.ruleMatches) { match in
                    RuleMatchRow(match: match)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
        }
    }

    private var statusColor: Color {
        if monitor.activeCount > 0 { return AppPalette.runningColor }
        return AppPalette.idleColor
    }
}

private struct PortRowData: Identifiable {
    let port: PortWatch
    let processes: [PortProcess]

    var id: PortWatch.ID { port.id }
}

private enum AppPalette {
    static let windowBackground = Color(nsColor: .windowBackgroundColor)
    static let headerBackground = Color(nsColor: .controlBackgroundColor).opacity(0.72)
    static let rowBackground = Color(nsColor: .controlBackgroundColor).opacity(0.82)
    static let rowBorder = Color.primary.opacity(0.08)
    static let insetBackground = Color(nsColor: .textBackgroundColor).opacity(0.42)
    static let idleColor = Color(nsColor: .secondaryLabelColor)
    static let runningColor = Color.orange
}

private struct IdlePortsDisclosure: View {
    @EnvironmentObject private var monitor: ProcessMonitor
    let ports: [PortWatch]
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 8) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 10) {
                    StatusDot(color: AppPalette.idleColor)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(monitor.t(.idlePorts))
                            .font(.subheadline.weight(.semibold))

                        Text(isExpanded ? monitor.t(.collapseIdlePorts) : monitor.t(.expandIdlePorts))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(ports.count)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppPalette.insetBackground, in: Capsule())

                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(11)
                .contentShape(Rectangle())
                .background(AppPalette.rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(AppPalette.rowBorder, lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .help(isExpanded ? monitor.t(.collapseIdlePorts) : monitor.t(.expandIdlePorts))

            if isExpanded {
                LazyVStack(spacing: 8) {
                    ForEach(ports) { port in
                        PortStatusRow(port: port, processes: [])
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

private struct StatusMark: View {
    let symbol: String
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.16))
                .frame(width: 44, height: 44)

            Image(systemName: symbol)
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 52, height: 52)
    }
}

private struct StatusPill: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.caption.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12), in: Capsule())
        .foregroundStyle(color)
    }
}

private struct MetricChip: View {
    let value: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 20)

            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(AppPalette.insetBackground, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(color.opacity(0.14), lineWidth: 1)
        }
    }
}

private struct ScanningGlyph: View {
    let active: Bool

    @ViewBuilder
    var body: some View {
        if active {
            TimelineView(.animation) { timeline in
                let rotation = timeline.date.timeIntervalSinceReferenceDate * 220

                Image(systemName: "arrow.triangle.2.circlepath")
                    .rotationEffect(.degrees(rotation))
                    .animation(nil, value: rotation)
            }
            .frame(width: 16, height: 16)
        } else {
            Image(systemName: "arrow.triangle.2.circlepath")
                .frame(width: 16, height: 16)
        }
    }
}

private struct ToolbarIconButtonStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: 31, height: 31)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(configuration.isPressed ? tint.opacity(0.18) : AppPalette.insetBackground)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.28 : 0.12), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 18)

            Text(title)
                .font(.subheadline.weight(.semibold))

            Text("\(count)")
                .font(.caption2.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppPalette.insetBackground, in: Capsule())

            Spacer()
        }
    }
}

private struct PortStatusRow: View {
    @EnvironmentObject private var monitor: ProcessMonitor
    let port: PortWatch
    let processes: [PortProcess]

    private var rowColor: Color {
        processes.isEmpty ? AppPalette.idleColor : AppPalette.runningColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 10) {
                StatusDot(color: rowColor)

                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text(verbatim: port.displayName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(verbatim: ":\(port.port)")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .fixedSize()
                }

                Spacer()

                if processes.isEmpty {
                    Text(monitor.t(.idle))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppPalette.insetBackground, in: Capsule())
                        .transition(.opacity)
                }
            }

            if !processes.isEmpty {
                VStack(spacing: 7) {
                    ForEach(processes) { process in
                        ProcessRow(
                            title: process.name,
                            subtitle: process.commandLine,
                            trailing: process.displayTarget,
                            systemImage: process.isDockerContainer
                                ? "shippingbox.fill"
                                : (process.isProtectedSystemProcess ? "gearshape.2.fill" : "terminal"),
                            canTerminate: process.canTerminate,
                            actionMode: monitor.terminationButtonMode(for: process.terminationTarget),
                            terminateLabel: process.isDockerContainer ? monitor.t(.stopContainer) : monitor.t(.sendTerm),
                            forceTerminateLabel: process.isDockerContainer ? monitor.t(.killContainer) : monitor.t(.forceKill),
                            disabledHelp: process.isProtectedSystemProcess ? monitor.t(.systemProcessProtected) : monitor.t(.dockerProxyProtected),
                            terminate: { monitor.terminate(process.terminationTarget) },
                            forceTerminate: { monitor.terminate(process.terminationTarget, force: true) }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .padding(11)
        .background(AppPalette.rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.rowBorder, lineWidth: 1)
        }
    }
}

private struct StatusDot: View {
    let color: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)
        }
        .frame(width: 22, height: 22)
    }
}

private struct RuleMatchRow: View {
    @EnvironmentObject private var monitor: ProcessMonitor
    let match: RuleProcessMatch

    private var target: ProcessTerminationTarget {
        .process(pid: match.process.pid)
    }

    var body: some View {
        ProcessRow(
            title: match.process.displayName,
            subtitle: match.process.commandLine,
            trailing: match.rules.joined(separator: ", "),
            systemImage: "terminal",
            canTerminate: true,
            actionMode: monitor.terminationButtonMode(for: target),
            terminateLabel: monitor.t(.sendTerm),
            forceTerminateLabel: monitor.t(.forceKill),
            disabledHelp: monitor.t(.dockerProxyProtected),
            terminate: { monitor.terminate(target) },
            forceTerminate: { monitor.terminate(target, force: true) }
        )
        .padding(11)
        .background(AppPalette.rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.rowBorder, lineWidth: 1)
        }
    }
}

private struct ProcessRow: View {
    @EnvironmentObject private var monitor: ProcessMonitor
    let title: String
    let subtitle: String
    let trailing: String
    let systemImage: String
    let canTerminate: Bool
    let actionMode: ProcessTerminationButtonMode
    let terminateLabel: String
    let forceTerminateLabel: String
    let disabledHelp: String
    let terminate: () -> Void
    let forceTerminate: () -> Void

    private var buttonIcon: String {
        switch actionMode {
        case .graceful:
            "xmark.circle.fill"
        case .waiting:
            "hourglass.circle.fill"
        case .force:
            "exclamationmark.octagon.fill"
        }
    }

    private var buttonHelp: String {
        guard canTerminate else {
            return disabledHelp
        }

        switch actionMode {
        case .graceful:
            return terminateLabel
        case .waiting:
            return monitor.t(.waitingForExit)
        case .force:
            return forceTerminateLabel
        }
    }

    private var buttonColor: Color {
        switch actionMode {
        case .graceful, .force:
            return .red
        case .waiting:
            return .secondary
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(AppPalette.insetBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Text(trailing)
                            .font(.caption2.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        Spacer(minLength: 28)
                    }

                    Text(subtitle.isEmpty ? title : subtitle)
                        .font(.caption2.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                        .padding(.trailing, 28)
                }
            }

            Button(action: actionMode == .force ? forceTerminate : terminate) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(buttonColor)
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(!canTerminate || actionMode == .waiting)
            .opacity((canTerminate && actionMode != .waiting) ? 1 : 0.42)
            .help(buttonHelp)
        }
    }
}

private struct ErrorBanner: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.red)
            .lineLimit(2)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.red.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct EmptyState: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 24)
                .background(AppPalette.insetBackground, in: RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(11)
        .background(AppPalette.rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppPalette.rowBorder, lineWidth: 1)
        }
    }
}
