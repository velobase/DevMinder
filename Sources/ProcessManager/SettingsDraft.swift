import Foundation
import ProcessManagerCore

struct SettingsDraft: Equatable {
    var ports: [PortWatch]
    var rules: [ProcessRule]
    var scanInterval: TimeInterval
    var monitoringEnabled: Bool
    var languageMode: LanguageMode
    var appearanceMode: AppearanceMode

    init(config: AppConfig = AppConfig()) {
        self.ports = config.ports
        self.rules = config.rules
        self.scanInterval = config.scanInterval
        self.monitoringEnabled = config.monitoringEnabled
        self.languageMode = config.languageMode
        self.appearanceMode = config.appearanceMode
    }

    var config: AppConfig {
        AppConfig(
            ports: ports,
            rules: rules,
            scanInterval: scanInterval,
            monitoringEnabled: monitoringEnabled,
            languageMode: languageMode,
            appearanceMode: appearanceMode
        )
    }
}
