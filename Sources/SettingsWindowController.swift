import Cocoa

struct SettingsData {
    var sedentaryMinutes: Int
    var dismissMinutes: Int
    var sessionEndMinutes: Int
    var reminderText: String
}

@MainActor
final class SettingsWindowController: NSWindowController, NSTextFieldDelegate {
    private var sedentaryField: NSTextField!
    private var dismissField: NSTextField!
    private var sessionEndField: NSTextField!
    private var textField: NSTextField!
    private var saveButton: NSButton!
    private var initialSedentary: String = ""
    private var initialDismiss: String = ""
    private var initialSessionEnd: String = ""
    private var initialText: String = ""
    var onSettingsChanged: ((SettingsData) -> Void)?

    convenience init(currentMinutes: Int, dismissMinutes: Int, sessionEndMinutes: Int, reminderText: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 420, height: 340),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)
        setupUI(currentMinutes: currentMinutes, dismissMinutes: dismissMinutes, sessionEndMinutes: sessionEndMinutes, reminderText: reminderText)
    }

    private func setupUI(currentMinutes: Int, dismissMinutes: Int, sessionEndMinutes: Int, reminderText: String) {
        guard let contentView = window?.contentView else { return }

        let numFormatter = NumberFormatter()
        numFormatter.allowsFloats = false
        numFormatter.minimum = 1
        numFormatter.maximum = 999

        // Sedentary time
        let sedentaryLabel = NSTextField(labelWithString: "久坐提醒时间（分钟）：")
        sedentaryLabel.font = NSFont.systemFont(ofSize: 14)
        sedentaryLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sedentaryLabel)

        sedentaryField = NSTextField()
        sedentaryField.stringValue = "\(currentMinutes)"
        sedentaryField.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        sedentaryField.alignment = .center
        sedentaryField.translatesAutoresizingMaskIntoConstraints = false
        sedentaryField.formatter = numFormatter
        contentView.addSubview(sedentaryField)

        // Dismiss time
        let dismissLabel = NSTextField(labelWithString: "提醒窗口显示时间（分钟）：")
        dismissLabel.font = NSFont.systemFont(ofSize: 14)
        dismissLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(dismissLabel)

        dismissField = NSTextField()
        dismissField.stringValue = "\(dismissMinutes)"
        dismissField.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        dismissField.alignment = .center
        dismissField.translatesAutoresizingMaskIntoConstraints = false
        dismissField.formatter = numFormatter
        contentView.addSubview(dismissField)

        // Session-end inactivity
        let sessionEndLabel = NSTextField(labelWithString: "离开判定时间（分钟）：")
        sessionEndLabel.font = NSFont.systemFont(ofSize: 14)
        sessionEndLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sessionEndLabel)

        sessionEndField = NSTextField()
        sessionEndField.stringValue = "\(sessionEndMinutes)"
        sessionEndField.font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .regular)
        sessionEndField.alignment = .center
        sessionEndField.translatesAutoresizingMaskIntoConstraints = false
        sessionEndField.formatter = numFormatter
        contentView.addSubview(sessionEndField)

        // Reminder text
        let textLabel = NSTextField(labelWithString: "提醒文本（可用 {{sedentaryMinutes}}）：")
        textLabel.font = NSFont.systemFont(ofSize: 14)
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textLabel)

        textField = NSTextField()
        textField.stringValue = reminderText
        textField.font = NSFont.systemFont(ofSize: 14)
        textField.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textField)

        // Save button
        saveButton = NSButton(title: "Save", target: self, action: #selector(saveClicked))
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r"
        saveButton.isEnabled = false
        contentView.addSubview(saveButton)

        // Store initial values for change tracking
        initialSedentary = "\(currentMinutes)"
        initialDismiss = "\(dismissMinutes)"
        initialSessionEnd = "\(sessionEndMinutes)"
        initialText = reminderText

        // Set delegates for change detection
        sedentaryField.delegate = self
        dismissField.delegate = self
        sessionEndField.delegate = self
        textField.delegate = self

        NSLayoutConstraint.activate([
            sedentaryLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sedentaryLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 25),

            sedentaryField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sedentaryField.topAnchor.constraint(equalTo: sedentaryLabel.bottomAnchor, constant: 6),
            sedentaryField.widthAnchor.constraint(equalToConstant: 80),

            dismissLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dismissLabel.topAnchor.constraint(equalTo: sedentaryField.bottomAnchor, constant: 16),

            dismissField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            dismissField.topAnchor.constraint(equalTo: dismissLabel.bottomAnchor, constant: 6),
            dismissField.widthAnchor.constraint(equalToConstant: 80),

            sessionEndLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sessionEndLabel.topAnchor.constraint(equalTo: dismissField.bottomAnchor, constant: 16),

            sessionEndField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            sessionEndField.topAnchor.constraint(equalTo: sessionEndLabel.bottomAnchor, constant: 6),
            sessionEndField.widthAnchor.constraint(equalToConstant: 80),

            textLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textLabel.topAnchor.constraint(equalTo: sessionEndField.bottomAnchor, constant: 16),

            textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            textField.topAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 6),

            saveButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            saveButton.topAnchor.constraint(equalTo: textField.bottomAnchor, constant: 20)
        ])
    }

    func controlTextDidChange(_ obj: Notification) {
        let changed = sedentaryField.stringValue != initialSedentary ||
                      dismissField.stringValue != initialDismiss ||
                      sessionEndField.stringValue != initialSessionEnd ||
                      textField.stringValue != initialText
        saveButton.isEnabled = changed
    }

    @objc private func saveClicked() {
        let sedentary = sedentaryField.integerValue
        let dismiss = dismissField.integerValue
        let sessionEnd = sessionEndField.integerValue
        let text = textField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        guard sedentary > 0, dismiss > 0, sessionEnd > 0, !text.isEmpty else { return }

        let settings = SettingsData(
            sedentaryMinutes: sedentary,
            dismissMinutes: dismiss,
            sessionEndMinutes: sessionEnd,
            reminderText: text
        )
        onSettingsChanged?(settings)
        Logger.shared.log("用户修改设置：久坐提醒 \(sedentary) 分钟，提醒显示 \(dismiss) 分钟，离开判定 \(sessionEnd) 分钟，文本「\(text)」")
        window?.close()
    }
}
