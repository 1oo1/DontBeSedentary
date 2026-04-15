import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let activityMonitor = ActivityMonitor()
    private let reminderController = ReminderWindowController()
    private var settingsWindowController: SettingsWindowController?
    private var isEnabled = true
    private var enableMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupActivityMonitor()
        activityMonitor.start()
        Logger.shared.log("应用启动")
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "figure.stand", accessibilityDescription: "DontBeSedentary")
        }

        let menu = NSMenu()

        // Log submenu
        let logItem = NSMenuItem(title: "Log", action: nil, keyEquivalent: "")
        let logSubmenu = NSMenu()
        logSubmenu.addItem(NSMenuItem(title: "Open Log File", action: #selector(openLog), keyEquivalent: "l"))
        logItem.submenu = logSubmenu
        menu.addItem(logItem)

        // Time Setting submenu
        let timeSettingItem = NSMenuItem(title: "Time Setting", action: nil, keyEquivalent: "")
        let timeSubmenu = NSMenu()

        enableMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "e")
        enableMenuItem.state = .on
        timeSubmenu.addItem(enableMenuItem)

        timeSubmenu.addItem(NSMenuItem.separator())
        timeSubmenu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        timeSettingItem.submenu = timeSubmenu
        menu.addItem(timeSettingItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Activity Monitor

    private func setupActivityMonitor() {
        activityMonitor.onShouldShowReminder = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isEnabled else { return }
                self.reminderController.showOnAllScreens(minutes: self.activityMonitor.sedentaryMinutes)
            }
        }

        activityMonitor.onShouldDismissReminder = { [weak self] in
            DispatchQueue.main.async {
                self?.reminderController.dismissAll()
            }
        }
    }

    // MARK: - Actions

    @objc private func openLog() {
        Logger.shared.openLogFile()
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        enableMenuItem.state = isEnabled ? .on : .off

        if isEnabled {
            activityMonitor.start()
            Logger.shared.log("监测已启用")
        } else {
            activityMonitor.stop()
            reminderController.dismissAll()
            Logger.shared.log("监测已禁用")
        }
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(currentMinutes: activityMonitor.sedentaryMinutes)
            settingsWindowController?.onTimeChanged = { [weak self] minutes in
                self?.activityMonitor.sedentaryMinutes = minutes
            }
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        Logger.shared.log("应用退出")
        activityMonitor.stop()
        NSApp.terminate(nil)
    }
}
