import Cocoa

@MainActor
final class ReminderWindowController {
    private var panels: [NSPanel] = []
    private var escGlobalMonitor: Any?
    private var escLocalMonitor: Any?
    private var escPressCount: Int = 0
    private var lastEscTime: Date = .distantPast
    private var countdownTimer: Timer?
    private var remainingMinutes: Int = 0

    var onEscDismiss: (() -> Void)?

    func showOnAllScreens(text: String, dismissMinutes: Int) {
        dismissAll()

        remainingMinutes = dismissMinutes
        let countdownText = formatCountdown(remainingMinutes)

        for screen in NSScreen.screens {
            let panel = createPanel(for: screen, text: text, countdownText: countdownText)
            panels.append(panel)
            panel.orderFrontRegardless()
        }

        startEscMonitor()
        startCountdownTimer()
    }

    func dismissAll() {
        stopEscMonitor()
        countdownTimer?.invalidate()
        countdownTimer = nil
        for panel in panels {
            panel.close()
        }
        panels.removeAll()
    }

    private func startEscMonitor() {
        stopEscMonitor()
        escPressCount = 0

        let handleEsc: (NSEvent) -> Void = { [weak self] event in
            guard let self = self, event.keyCode == 53 else { return } // 53 = Esc
            MainActor.assumeIsolated {
                let now = Date()
                if now.timeIntervalSince(self.lastEscTime) > 2.0 {
                    self.escPressCount = 0
                }
                self.lastEscTime = now
                self.escPressCount += 1
                if self.escPressCount >= 5 {
                    self.dismissAll()
                    self.onEscDismiss?()
                }
            }
        }

        escGlobalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown, handler: handleEsc)
        escLocalMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleEsc(event)
            return event
        }
    }

    private func stopEscMonitor() {
        if let monitor = escGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            escGlobalMonitor = nil
        }
        if let monitor = escLocalMonitor {
            NSEvent.removeMonitor(monitor)
            escLocalMonitor = nil
        }
    }

    private func formatCountdown(_ minutes: Int) -> String {
        "剩余 \(minutes) 分钟（5次Esc强制退出）"
    }

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateCountdown()
            }
        }
    }

    private func updateCountdown() {
        remainingMinutes = max(0, remainingMinutes - 1)
        let text = formatCountdown(remainingMinutes)
        for panel in panels {
            (panel.contentView as? ReminderView)?.updateCountdown(text)
        }
    }

    private func createPanel(for screen: NSScreen, text: String, countdownText: String) -> NSPanel {
        let panel = NSPanel(
            contentRect: screen.frame,
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.setFrame(screen.frame, display: true)

        let contentView = ReminderView(frame: screen.frame, text: text, countdownText: countdownText)
        panel.contentView = contentView

        return panel
    }
}

// MARK: - ReminderView

private class ReminderView: NSVisualEffectView {
    private let gradientLayer = CAGradientLayer()
    private let label = NSTextField(labelWithString: "")
    private let countdownLabel = NSTextField(labelWithString: "")
    private var breathingAnimation: CABasicAnimation?
    private let text: String
    private let countdownText: String

    init(frame: NSRect, text: String, countdownText: String) {
        self.text = text
        self.countdownText = countdownText
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateCountdown(_ text: String) {
        countdownLabel.stringValue = text
    }

    private func setup() {
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true

        setupGradient()
        setupLabel()
        startAnimations()
    }

    private func setupGradient() {
        guard let layer = self.layer else { return }

        // #407245 color
        let green = NSColor(red: 0x40/255.0, green: 0x72/255.0, blue: 0x45/255.0, alpha: 1.0)

        gradientLayer.type = .radial
        gradientLayer.colors = [
            NSColor.clear.cgColor,
            green.withAlphaComponent(0.5).cgColor,
            green.withAlphaComponent(0.85).cgColor
        ]
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 1.0)
        gradientLayer.frame = bounds

        layer.addSublayer(gradientLayer)
    }

    private func setupLabel() {
        // Countdown label
        countdownLabel.stringValue = countdownText
        countdownLabel.font = NSFont(name: "PingFang SC Regular", size: 18) ?? NSFont.systemFont(ofSize: 18)
        countdownLabel.textColor = NSColor.white.withAlphaComponent(0.8)
        countdownLabel.alignment = .center
        countdownLabel.isBezeled = false
        countdownLabel.isEditable = false
        countdownLabel.drawsBackground = false
        countdownLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countdownLabel)

        // Reminder label
        label.stringValue = text
        label.font = NSFont(name: "PingFang SC Medium", size: 28) ?? NSFont.systemFont(ofSize: 28, weight: .medium)
        label.textColor = .white
        label.alignment = .center
        label.isBezeled = false
        label.isEditable = false
        label.drawsBackground = false
        label.translatesAutoresizingMaskIntoConstraints = false

        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8),

            countdownLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            countdownLabel.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -16),
            countdownLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8)
        ])
    }

    private func startAnimations() {
        // Breathing animation on gradient opacity
        let breathe = CABasicAnimation(keyPath: "opacity")
        breathe.fromValue = 0.6
        breathe.toValue = 1.0
        breathe.duration = 2.5
        breathe.autoreverses = true
        breathe.repeatCount = .infinity
        breathe.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        gradientLayer.add(breathe, forKey: "breathing")

        // Label width smooth transition animation
        startLabelAnimation()
    }

    private func startLabelAnimation() {
        let scaleAnim = CABasicAnimation(keyPath: "transform.scale.x")
        scaleAnim.fromValue = 0.95
        scaleAnim.toValue = 1.05
        scaleAnim.duration = 3.0
        scaleAnim.autoreverses = true
        scaleAnim.repeatCount = .infinity
        scaleAnim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        label.layer?.add(scaleAnim, forKey: "labelScale")
    }

    override func layout() {
        super.layout()
        gradientLayer.frame = bounds
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Ensure label layer exists for animation
        label.wantsLayer = true
        startLabelAnimation()
    }
}
