import Cocoa

final class SettingsWindowController: NSWindowController {
    private var timeField: NSTextField!
    var onTimeChanged: ((Int) -> Void)?

    convenience init(currentMinutes: Int) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 150),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupUI(currentMinutes: currentMinutes)
    }

    private func setupUI(currentMinutes: Int) {
        guard let contentView = window?.contentView else { return }

        let promptLabel = NSTextField(labelWithString: "久坐提醒时间（分钟）：")
        promptLabel.font = NSFont.systemFont(ofSize: 14)
        promptLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(promptLabel)

        timeField = NSTextField()
        timeField.stringValue = "\(currentMinutes)"
        timeField.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        timeField.alignment = .center
        timeField.translatesAutoresizingMaskIntoConstraints = false
        // Use NumberFormatter to only allow digits
        let formatter = NumberFormatter()
        formatter.allowsFloats = false
        formatter.minimum = 1
        formatter.maximum = 999
        timeField.formatter = formatter
        contentView.addSubview(timeField)

        let saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        contentView.addSubview(saveButton)

        NSLayoutConstraint.activate([
            promptLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            promptLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25),

            timeField.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timeField.topAnchor.constraint(equalTo: promptLabel.bottomAnchor, constant: 12),
            timeField.widthAnchor.constraint(equalToConstant: 80),

            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.topAnchor.constraint(equalTo: timeField.bottomAnchor, constant: 16)
        ])
    }

    @objc private func saveClicked() {
        let value = timeField.integerValue
        if value > 0 {
            onTimeChanged?(value)
            Logger.shared.log("用户修改久坐提醒时间为 \(value) 分钟")
            window?.close()
        }
    }
}
