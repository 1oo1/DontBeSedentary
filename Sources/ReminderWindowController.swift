import Cocoa

@MainActor
final class ReminderWindowController {
    private var panels: [NSPanel] = []
    private var countdownTimer: Timer?
    private var remainingMinutes: Int = 0

    var onCloseButtonDismiss: (() -> Void)?

    func showOnAllScreens(text: String, dismissMinutes: Int) {
        dismissAll()

        remainingMinutes = dismissMinutes
        let countdownText = formatCountdown(remainingMinutes)

        for screen in NSScreen.screens {
            let panel = createPanel(for: screen, text: text, countdownText: countdownText)
            panels.append(panel)
            panel.orderFrontRegardless()
        }

        startCountdownTimer()
    }

    func dismissAll() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        for panel in panels {
            panel.close()
        }
        panels.removeAll()
    }

    private func handleCloseButton() {
        dismissAll()
        onCloseButtonDismiss?()
    }

    private func formatCountdown(_ minutes: Int) -> String {
        "剩余 \(minutes) 分钟"
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
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.setFrame(screen.frame, display: true)

        let contentView = ReminderView(frame: screen.frame, text: text, countdownText: countdownText)
        contentView.onClose = { [weak self] in
            self?.handleCloseButton()
        }
        panel.contentView = contentView

        return panel
    }
}

// MARK: - CloseButton

private class CloseButton: NSView {
    var onTap: (() -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = bounds.width / 2
        layer?.masksToBounds = true

        let blurView = NSVisualEffectView(frame: bounds)
        blurView.material = .hudWindow
        blurView.blendingMode = .withinWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = bounds.width / 2
        blurView.layer?.masksToBounds = true
        blurView.autoresizingMask = [.width, .height]
        addSubview(blurView)

        let symbol = NSTextField(labelWithString: "✕")
        symbol.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        symbol.textColor = NSColor.white.withAlphaComponent(0.9)
        symbol.alignment = .center
        symbol.translatesAutoresizingMaskIntoConstraints = false
        addSubview(symbol)

        NSLayoutConstraint.activate([
            symbol.centerXAnchor.constraint(equalTo: centerXAnchor),
            symbol.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        alphaValue = 0.8
    }

    override func mouseDown(with event: NSEvent) {
        alphaValue = 0.5
    }

    override func mouseUp(with event: NSEvent) {
        alphaValue = 0.8
        let location = convert(event.locationInWindow, from: nil)
        if bounds.contains(location) {
            onTap?()
        }
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

// MARK: - ReminderView

private class ReminderView: NSVisualEffectView {
    private let gradientLayer = CAGradientLayer()
    private let label = NSTextField(labelWithString: "")
    private let countdownLabel = NSTextField(labelWithString: "")
    private let closeButton = CloseButton(frame: NSRect(x: 0, y: 0, width: 36, height: 36))
    private var breathingAnimation: CABasicAnimation?
    private let text: String
    private let countdownText: String

    var onClose: (() -> Void)? {
        didSet { closeButton.onTap = onClose }
    }

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

    override func hitTest(_ point: NSPoint) -> NSView? {
        let buttonPoint = closeButton.convert(point, from: self)
        if closeButton.bounds.contains(buttonPoint) {
            return closeButton
        }
        return nil
    }

    private func setup() {
        material = .hudWindow
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true

        setupGradient()
        setupLabel()
        setupCloseButton()
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

    private func setupCloseButton() {
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(closeButton)
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: topAnchor, constant: 40),
            closeButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
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
