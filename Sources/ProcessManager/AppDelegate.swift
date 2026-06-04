import AppKit
import Combine
import ProcessManagerCore
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let monitor = ProcessMonitor()
    private let navigation = AppNavigation()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var cancellables: Set<AnyCancellable> = []
    private let fullSize = NSSize(width: 540, height: 680)

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        AppActions.showSettings = { [weak self] in
            self?.navigation.showSettings()
        }

        applyAppearance()
        setupStatusItem()
        bindMonitor()
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.target = self
        item.button?.action = #selector(togglePopover(_:))
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        statusItem = item
        updateStatusItem()

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = fullSize
        popover.contentViewController = NSHostingController(
            rootView: MenuView()
                .environmentObject(monitor)
                .environmentObject(navigation)
        )
        self.popover = popover
    }

    private func bindMonitor() {
        monitor.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateStatusItem()
                }
            }
            .store(in: &cancellables)

        monitor.$appearanceMode
            .sink { [weak self] _ in
                self?.applyAppearance()
            }
            .store(in: &cancellables)

        monitor.$languageMode
            .sink { [weak self] _ in
                self?.updateLocalizedChrome()
            }
            .store(in: &cancellables)

        navigation.$screen
            .sink { [weak self] screen in
                self?.resizeChrome(for: screen)
            }
            .store(in: &cancellables)
    }

    private func updateStatusItem() {
        guard let button = statusItem?.button else {
            return
        }

        button.image = MenuBarIcon.make(active: monitor.activeCount > 0)
        button.image?.accessibilityDescription = monitor.statusTitle
        button.imagePosition = .imageLeading
        button.title = " \(monitor.statusTitle)"
    }

    private func updateLocalizedChrome() {
        mainWindow?.title = monitor.t(.appName)
        updateStatusItem()
    }

    private func applyAppearance() {
        let appearance = monitor.appearanceMode.nsAppearanceName.flatMap(NSAppearance.init(named:))
        NSApp.appearance = appearance
        mainWindow?.appearance = appearance
        popover?.contentViewController?.view.appearance = appearance
    }

    private func resizeChrome(for screen: AppScreen) {
        popover?.contentSize = fullSize

        guard let mainWindow else {
            return
        }

        mainWindow.contentMinSize = NSSize(width: 520, height: 560)
        mainWindow.setContentSize(fullSize)
    }

    @objc
    private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else {
            return
        }

        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    private func showMainWindow() {
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: fullSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = monitor.t(.appName)
        window.contentMinSize = NSSize(width: 520, height: 560)
        window.contentViewController = NSHostingController(
            rootView: MenuView()
                .environmentObject(monitor)
                .environmentObject(navigation)
        )
        window.delegate = self
        window.isReleasedWhenClosed = false
        window.center()

        mainWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}
