import Foundation
import ProcessManagerCore
import SwiftUI

@MainActor
final class ProcessMonitor: ObservableObject {
    @Published var ports: [PortWatch] {
        didSet { saveConfig() }
    }

    @Published var rules: [ProcessRule] {
        didSet { saveConfig() }
    }

    @Published var scanInterval: TimeInterval {
        didSet {
            saveConfig()
            startTimer()
        }
    }

    @Published var monitoringEnabled: Bool {
        didSet {
            saveConfig()
            if monitoringEnabled {
                scanNow()
                startTimer()
            } else {
                setStatus(.sleeping)
            }
        }
    }

    @Published var languageMode: LanguageMode {
        didSet {
            saveConfig()
            refreshStatusMessage()
        }
    }

    @Published var appearanceMode: AppearanceMode {
        didSet { saveConfig() }
    }

    @Published private(set) var portProcesses: [PortProcess] = []
    @Published private(set) var ruleMatches: [RuleProcessMatch] = []
    @Published private(set) var lastScanDate: Date?
    @Published private(set) var statusMessage = ""
    @Published private(set) var isScanning = false
    @Published var errorMessage: String?

    private let scanner = ProcessScanner()
    private var timer: Timer?
    private var scanTask: Task<Void, Never>?
    private var statusKind: MonitorStatus = .ready
    private let configKey = "process-manager.config.v1"

    init() {
        let config = Self.loadConfig(key: configKey)
        self.ports = config.ports
        self.rules = config.rules
        self.scanInterval = config.scanInterval
        self.monitoringEnabled = config.monitoringEnabled
        self.languageMode = config.languageMode
        self.appearanceMode = config.appearanceMode
        self.statusMessage = ""
        refreshStatusMessage()

        startTimer()

        if monitoringEnabled {
            scanNow()
        }
    }

    var activeCount: Int {
        let portTargets = portProcesses.map { $0.terminationTarget.id }
        let ruleTargets = ruleMatches.map { "pid-\($0.process.pid)" }
        return Set(portTargets + ruleTargets).count
    }

    var statusSymbol: String {
        if !monitoringEnabled { return "moon.zzz.fill" }
        if activeCount > 0 { return "exclamationmark.circle.fill" }
        return "checkmark.circle.fill"
    }

    var statusTitle: String {
        if !monitoringEnabled { return t(.monitoringPaused) }
        if activeCount > 0 { return L10n.processCount(activeCount, language: language) }
        return t(.idle)
    }

    var language: AppLanguage {
        L10n.language(for: languageMode)
    }

    func t(_ key: L10nKey) -> String {
        L10n.text(key, language: language)
    }

    var configSnapshot: AppConfig {
        AppConfig(
            ports: ports,
            rules: rules,
            scanInterval: scanInterval,
            monitoringEnabled: monitoringEnabled,
            languageMode: languageMode,
            appearanceMode: appearanceMode
        )
    }

    func applyConfig(_ config: AppConfig) {
        ports = config.ports
        rules = config.rules
        scanInterval = Self.normalizedScanInterval(config.scanInterval)
        monitoringEnabled = config.monitoringEnabled
        languageMode = config.languageMode
        appearanceMode = config.appearanceMode

        if monitoringEnabled {
            scanNow()
        }
    }

    func scanNow() {
        guard monitoringEnabled else {
            setStatus(.sleeping)
            return
        }

        guard !isScanning else {
            return
        }

        isScanning = true
        setStatus(.scanning)

        let scanner = scanner
        let ports = ports
        let rules = rules

        scanTask?.cancel()
        scanTask = Task.detached(priority: .utility) {
            let portProcesses = scanner.scanPorts(ports)
            let ruleMatches = scanner.scanRules(rules)

            await MainActor.run {
                guard !Task.isCancelled else {
                    return
                }

                self.portProcesses = portProcesses
                self.ruleMatches = ruleMatches
                self.lastScanDate = Date()
                self.errorMessage = nil
                self.isScanning = false
                self.setStatus(self.activeCount > 0 ? .found(self.activeCount) : .noneFound)
            }
        }
    }

    func toggleMonitoring() {
        monitoringEnabled.toggle()
    }

    func terminate(pid: Int, force: Bool = false) {
        terminate(.process(pid: pid), force: force)
    }

    func terminate(_ target: ProcessTerminationTarget, force: Bool = false) {
        let scanner = scanner

        Task {
            do {
                try await Task.detached(priority: .utility) {
                    try scanner.terminate(target, force: force)
                }.value

                errorMessage = nil
                setStatus(.terminated(target: target.displayLabel, force: force))
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                    self?.scanNow()
                }
            } catch {
                let message = L10n.terminateFailed(
                    target: target.displayLabel,
                    error: error.localizedDescription,
                    language: language
                )
                errorMessage = message
                setStatus(.terminateFailed(target: target.displayLabel, error: error.localizedDescription))
            }
        }
    }

    func addPort() {
        ports.append(PortWatch(port: suggestedPort(), label: ""))
    }

    func removePort(id: PortWatch.ID) {
        ports.removeAll { $0.id == id }
        scanNow()
    }

    func addRule() {
        rules.append(ProcessRule(pattern: "", label: ""))
    }

    func removeRule(id: ProcessRule.ID) {
        rules.removeAll { $0.id == id }
        scanNow()
    }

    func resetDefaults() {
        ports = AppConfig.defaultPorts
        rules = AppConfig.defaultRules
        scanInterval = AppConfig.defaultScanInterval
        monitoringEnabled = true
        languageMode = .system
        appearanceMode = .system
        scanNow()
    }

    func processes(for port: Int) -> [PortProcess] {
        portProcesses.filter { $0.port == port }
    }

    private func startTimer() {
        timer?.invalidate()

        guard monitoringEnabled else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: scanInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.scanNow()
            }
        }
    }

    private func saveConfig() {
        let config = AppConfig(
            ports: ports,
            rules: rules,
            scanInterval: scanInterval,
            monitoringEnabled: monitoringEnabled,
            languageMode: languageMode,
            appearanceMode: appearanceMode
        )

        guard let data = try? JSONEncoder().encode(config) else {
            return
        }

        UserDefaults.standard.set(data, forKey: configKey)
    }

    private func suggestedPort() -> Int {
        let usedPorts = Set(ports.map(\.port))

        for candidate in AppConfig.defaultPorts.map(\.port) {
            if !usedPorts.contains(candidate) {
                return candidate
            }
        }

        return (usedPorts.max() ?? 3000) + 1
    }

    private static func loadConfig(key: String) -> AppConfig {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let config = try? JSONDecoder().decode(AppConfig.self, from: data)
        else {
            return AppConfig()
        }

        return AppConfig(
            ports: config.ports,
            rules: config.rules,
            scanInterval: normalizedScanInterval(config.scanInterval),
            monitoringEnabled: config.monitoringEnabled,
            languageMode: config.languageMode,
            appearanceMode: config.appearanceMode
        )
    }

    private static func normalizedScanInterval(_ interval: TimeInterval) -> TimeInterval {
        max(2, min(interval, 60))
    }

    private func refreshStatusMessage() {
        statusMessage = localizedStatus(statusKind)
    }

    private func setStatus(_ status: MonitorStatus) {
        statusKind = status
        statusMessage = localizedStatus(status)
    }

    private func localizedStatus(_ status: MonitorStatus) -> String {
        switch status {
        case .ready:
            return t(.ready)
        case .sleeping:
            return t(.monitoringPaused)
        case .scanning:
            return t(.scanning)
        case .found(let count):
            return L10n.foundProcessCount(count, language: language)
        case .noneFound:
            return t(.noTargetProcesses)
        case .terminated(let target, let force):
            return L10n.terminated(target: target, force: force, language: language)
        case .terminateFailed(let target, let error):
            return L10n.terminateFailed(target: target, error: error, language: language)
        }
    }
}

private enum MonitorStatus {
    case ready
    case sleeping
    case scanning
    case found(Int)
    case noneFound
    case terminated(target: String, force: Bool)
    case terminateFailed(target: String, error: String)
}
