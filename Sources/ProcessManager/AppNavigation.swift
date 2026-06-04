import Foundation

@MainActor
final class AppNavigation: ObservableObject {
    @Published var screen: AppScreen = .dashboard

    func showDashboard() {
        screen = .dashboard
    }

    func showSettings() {
        screen = .settings
    }
}

enum AppScreen: Equatable {
    case dashboard
    case settings
}
