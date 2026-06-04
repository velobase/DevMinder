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
    private let mainWindowBehavior: NSWindow.CollectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
    private let popoverWindowBehavior: NSWindow.CollectionBehavior = [.canJoinAllSpaces, .transient, .fullScreenAuxiliary]

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        AppActions.showSettings = { [weak self] in
            self?.navigation.showSettings()
        }

        applyAppearance()
        setupStatusItem()
        bindMonitor()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showStatusPopover()
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

        button.image = MenuBarIcon.make(state: menuBarIconState)
        button.image?.accessibilityDescription = monitor.statusTitle
        button.imagePosition = menuBarTitle.isEmpty ? .imageOnly : .imageLeading
        button.title = menuBarTitle
    }

    private var menuBarIconState: MenuBarIcon.State {
        if !monitor.monitoringEnabled {
            return .paused
        }

        return monitor.activeCount > 0 ? .active : .idle
    }

    private var menuBarTitle: String {
        guard monitor.monitoringEnabled else {
            return ""
        }

        guard monitor.activeCount > 0 else {
            return ""
        }

        return " \(monitor.activeCount)"
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
            showStatusPopover()
        }
    }

    private func showStatusPopover() {
        guard
            let button = statusItem?.button,
            let popover
        else {
            return
        }

        if !popover.isShown {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }

        if let window = popover.contentViewController?.view.window {
            window.collectionBehavior = popoverWindowBehavior
            window.makeKey()
        }
    }

    private func showMainWindow() {
        if let mainWindow {
            mainWindow.collectionBehavior = mainWindowBehavior
            if mainWindow.isMiniaturized {
                mainWindow.deminiaturize(nil)
            }
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
        window.collectionBehavior = mainWindowBehavior
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
