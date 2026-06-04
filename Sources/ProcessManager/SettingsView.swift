import ProcessManagerCore
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var monitor: ProcessMonitor

    let onBack: () -> Void
    let onSave: () -> Void

    @State private var draft = SettingsDraft()
    @State private var hasLoaded = false

    private let portFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 1
        formatter.maximum = 65_535
        return formatter
    }()

    init(onBack: @escaping () -> Void = {}, onSave: @escaping () -> Void = {}) {
        self.onBack = onBack
        self.onSave = onSave
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    generalSection
                    portsSection
                    rulesSection
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .preferredColorScheme(monitor.appearanceMode.colorScheme)
        .onAppear {
            guard !hasLoaded else {
                return
            }

            draft = SettingsDraft(config: monitor.configSnapshot)
            hasLoaded = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button {
                onBack()
            } label: {
                Label(monitor.t(.back), systemImage: "chevron.left")
            }
            .buttonStyle(SettingsHeaderButtonStyle())

            Spacer()

            Text(monitor.t(.settings))
                .font(.headline)

            Spacer()

            Button {
                monitor.applyConfig(draft.config)
                onSave()
            } label: {
                Label(monitor.t(.save), systemImage: "checkmark")
            }
            .buttonStyle(SettingsHeaderButtonStyle(prominent: true))
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.72))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var generalSection: some View {
        SettingsSection(title: monitor.t(.generalTab), systemImage: "gearshape") {
            VStack(alignment: .leading, spacing: 16) {
                Toggle(monitor.t(.enableMonitoring), isOn: $draft.monitoringEnabled)

                pickerGroup(title: monitor.t(.language)) {
                    Picker("", selection: $draft.languageMode) {
                        ForEach(LanguageMode.allCases) { mode in
                            Text(mode.localizedName(language: monitor.language))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                pickerGroup(title: monitor.t(.appearance)) {
                    Picker("", selection: $draft.appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.localizedName(language: monitor.language))
                                .tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                HStack(spacing: 10) {
                    Text(monitor.t(.scanInterval))
                        .frame(width: 82, alignment: .leading)

                    Slider(value: $draft.scanInterval, in: 2...60, step: 1)

                    Text("\(Int(draft.scanInterval))s")
                        .font(.body.monospacedDigit())
                        .frame(width: 44, alignment: .trailing)
                }

                HStack(spacing: 10) {
                    Button {
                        draft = SettingsDraft(config: AppConfig())
                    } label: {
                        Label(monitor.t(.resetDefaults), systemImage: "arrow.counterclockwise")
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Label(monitor.t(.termHint), systemImage: "info.circle")
                    Label(monitor.t(.permissionHint), systemImage: "lock")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }

    private var portsSection: some View {
        SettingsSection(title: monitor.t(.portMonitoring), systemImage: "network") {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Spacer()

                    Button {
                        draft.ports.append(PortWatch(port: suggestedPort(), label: ""))
                    } label: {
                        Label(monitor.t(.add), systemImage: "plus")
                    }
                }

                ForEach($draft.ports) { $port in
                    PortEditorRow(
                        port: $port,
                        portFormatter: portFormatter,
                        deleteHelp: monitor.t(.delete),
                        portPlaceholder: monitor.t(.portPlaceholder),
                        labelPlaceholder: monitor.t(.labelPlaceholder),
                        remove: { draft.ports.removeAll { $0.id == port.id } }
                    )
                }
            }
        }
    }

    private var rulesSection: some View {
        SettingsSection(title: monitor.t(.activeRules), systemImage: "scope") {
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Spacer()

                    Button {
                        draft.rules.append(ProcessRule(pattern: "", label: ""))
                    } label: {
                        Label(monitor.t(.add), systemImage: "plus")
                    }
                }

                ForEach($draft.rules) { $rule in
                    RuleEditorRow(
                        rule: $rule,
                        deleteHelp: monitor.t(.delete),
                        patternPlaceholder: monitor.t(.keywordRegexPlaceholder),
                        labelPlaceholder: monitor.t(.labelPlaceholder),
                        remove: { draft.rules.removeAll { $0.id == rule.id } }
                    )
                }
            }
        }
    }

    private func pickerGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.subheadline.weight(.semibold))

            content()
        }
    }

    private func suggestedPort() -> Int {
        let usedPorts = Set(draft.ports.map(\.port))

        for candidate in AppConfig.defaultPorts.map(\.port) where !usedPorts.contains(candidate) {
            return candidate
        }

        return (usedPorts.max() ?? 3000) + 1
    }
}

private struct SettingsHeaderButtonStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .foregroundStyle(prominent ? Color.white : Color.primary)
            .background {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.18, dampingFraction: 0.78), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if prominent {
            return isPressed ? Color.accentColor.opacity(0.78) : Color.accentColor
        }

        return Color(nsColor: .textBackgroundColor).opacity(isPressed ? 0.72 : 0.42)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(spacing: 7) {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 18)

                Text(title)
                    .font(.headline)

                Spacer()
            }

            content()
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.78), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        }
    }
}

private struct PortEditorRow: View {
    @Binding var port: PortWatch
    let portFormatter: NumberFormatter
    let deleteHelp: String
    let portPlaceholder: String
    let labelPlaceholder: String
    let remove: () -> Void

    var body: some View {
        HStack(spacing: 9) {
            Toggle("", isOn: $port.enabled)
                .labelsHidden()
                .frame(width: 22)

            TextField(portPlaceholder, value: $port.port, formatter: portFormatter)
                .frame(width: 76)

            TextField(labelPlaceholder, text: $port.label)
                .frame(maxWidth: .infinity)

            Button(role: .destructive, action: remove) {
                Image(systemName: "trash")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(deleteHelp)
        }
        .padding(9)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.38), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}

private struct RuleEditorRow: View {
    @Binding var rule: ProcessRule
    let deleteHelp: String
    let patternPlaceholder: String
    let labelPlaceholder: String
    let remove: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 9) {
            Toggle("", isOn: $rule.enabled)
                .labelsHidden()
                .frame(width: 22)
                .padding(.top, 2)

            VStack(spacing: 7) {
                TextField(patternPlaceholder, text: $rule.pattern)
                    .font(.system(.body, design: .monospaced))

                TextField(labelPlaceholder, text: $rule.label)
            }
            .frame(maxWidth: .infinity)

            Button(role: .destructive, action: remove) {
                Image(systemName: "trash")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .help(deleteHelp)
            .padding(.top, 1)
        }
        .padding(9)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.38), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
    }
}
