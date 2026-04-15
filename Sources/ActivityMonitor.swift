import Cocoa

final class ActivityMonitor {
    private var keyboardEventMonitor: Any?
    private var mouseEventMonitor: Any?
    private var timer: Timer?

    private var lastActivityTime: Date = Date()
    private var sessionStartTime: Date?
    private var isUserActive: Bool = false
    private var isReminderShowing: Bool = false

    var sedentaryMinutes: Int = 45
    var onShouldShowReminder: (() -> Void)?
    var onShouldDismissReminder: (() -> Void)?

    private let inactivityThresholdForDismiss: TimeInterval = 10 * 60 // 10 minutes

    func start() {
        startEventMonitors()
        startTimer()
    }

    func stop() {
        stopEventMonitors()
        timer?.invalidate()
        timer = nil
    }

    private func startEventMonitors() {
        let keyboardMask: NSEvent.EventTypeMask = [.keyDown, .keyUp, .flagsChanged]
        keyboardEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: keyboardMask) { [weak self] _ in
            self?.recordActivity()
        }

        let mouseMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown, .scrollWheel, .leftMouseDragged, .rightMouseDragged]
        mouseEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: mouseMask) { [weak self] _ in
            self?.recordActivity()
        }
    }

    private func stopEventMonitors() {
        if let monitor = keyboardEventMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardEventMonitor = nil
        }
        if let monitor = mouseEventMonitor {
            NSEvent.removeMonitor(monitor)
            mouseEventMonitor = nil
        }
    }

    private func recordActivity() {
        lastActivityTime = Date()

        if !isUserActive {
            isUserActive = true
            sessionStartTime = Date()
            Logger.shared.log("用户开始使用电脑")
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.checkStatus()
        }
    }

    private func checkStatus() {
        let now = Date()
        let timeSinceLastActivity = now.timeIntervalSince(lastActivityTime)

        // If user has been inactive for more than 2 minutes, consider them away
        if timeSinceLastActivity > 120 {
            if isUserActive {
                isUserActive = false
                sessionStartTime = nil
            }

            // If reminder is showing and user has been inactive for 10 minutes, dismiss
            if isReminderShowing && timeSinceLastActivity >= inactivityThresholdForDismiss {
                isReminderShowing = false
                onShouldDismissReminder?()
                Logger.shared.log("提醒窗口关闭（用户已离开 10 分钟）")
            }
            return
        }

        // User is active
        if !isUserActive {
            isUserActive = true
            sessionStartTime = now
            Logger.shared.log("用户开始使用电脑")
        }

        // Check if user has been active long enough to trigger reminder
        if let start = sessionStartTime, !isReminderShowing {
            let sessionDuration = now.timeIntervalSince(start)
            if sessionDuration >= Double(sedentaryMinutes) * 60 {
                isReminderShowing = true
                onShouldShowReminder?()
                Logger.shared.log("显示久坐提醒（已连续使用 \(sedentaryMinutes) 分钟）")
            }
        }
    }
}
