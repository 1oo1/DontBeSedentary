import Cocoa
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private let activityMonitor = ActivityMonitor()
    private let reminderController = ReminderWindowController()
    private var settingsWindowController: SettingsWindowController?
    private var isEnabled = true
    private var enableMenuItem: NSMenuItem!
    private var launchAtLoginMenuItem: NSMenuItem!

    private var reminderText: String = "久坐 {{sedentaryMinutes}} 分钟了，休息一下吧！"

    // MARK: - UserDefaults Keys
    private enum DefaultsKey {
        static let sedentaryMinutes = "sedentaryMinutes"
        static let reminderDismissMinutes = "reminderDismissMinutes"
        static let reminderText = "reminderText"
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadSettings()
        setupStatusItem()
        setupActivityMonitor()
        activityMonitor.start()
        Logger.shared.log("应用启动")
    }

    // MARK: - Settings Persistence

    private func loadSettings() {
        let defaults = UserDefaults.standard
        if let mins = defaults.object(forKey: DefaultsKey.sedentaryMinutes) as? Int {
            activityMonitor.sedentaryMinutes = mins
        }
        if let dismiss = defaults.object(forKey: DefaultsKey.reminderDismissMinutes) as? Int {
            activityMonitor.reminderDismissMinutes = dismiss
        }
        if let text = defaults.string(forKey: DefaultsKey.reminderText) {
            reminderText = text
        }
    }

    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(activityMonitor.sedentaryMinutes, forKey: DefaultsKey.sedentaryMinutes)
        defaults.set(activityMonitor.reminderDismissMinutes, forKey: DefaultsKey.reminderDismissMinutes)
        defaults.set(reminderText, forKey: DefaultsKey.reminderText)
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

        // Enabled toggle (top-level)
        enableMenuItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "e")
        enableMenuItem.state = .on
        menu.addItem(enableMenuItem)

        // Settings (top-level)
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))

        // Launch at Login (top-level)
        launchAtLoginMenuItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginMenuItem.state = SMAppService.mainApp.status == .enabled ? .on : .off
        menu.addItem(launchAtLoginMenuItem)

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    // MARK: - Activity Monitor

    private func setupActivityMonitor() {
        activityMonitor.onShouldShowReminder = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self, self.isEnabled else { return }
                let text = self.reminderText.replacingOccurrences(
                    of: "{{sedentaryMinutes}}",
                    with: "\(self.activityMonitor.sedentaryMinutes)"
                )
                self.reminderController.showOnAllScreens(text: text)
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

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
                launchAtLoginMenuItem.state = .off
                Logger.shared.log("已关闭开机启动")
            } else {
                try SMAppService.mainApp.register()
                launchAtLoginMenuItem.state = .on
                Logger.shared.log("已开启开机启动")
            }
        } catch {
            Logger.shared.log("切换开机启动失败: \(error.localizedDescription)")
        }
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController(
                currentMinutes: activityMonitor.sedentaryMinutes,
                dismissMinutes: activityMonitor.reminderDismissMinutes,
                reminderText: reminderText
            )
            settingsWindowController?.onSettingsChanged = { [weak self] settings in
                guard let self = self else { return }
                self.activityMonitor.sedentaryMinutes = settings.sedentaryMinutes
                self.activityMonitor.reminderDismissMinutes = settings.dismissMinutes
                self.reminderText = settings.reminderText
                self.saveSettings()
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
