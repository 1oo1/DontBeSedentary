import Cocoa

final class ReminderWindowController {
    private var panels: [NSPanel] = []

    func showOnAllScreens(text: String) {
        dismissAll()

        for screen in NSScreen.screens {
            let panel = createPanel(for: screen, text: text)
            panels.append(panel)
            panel.orderFrontRegardless()
        }
    }

    func dismissAll() {
        for panel in panels {
            panel.close()
        }
        panels.removeAll()
    }

    private func createPanel(for screen: NSScreen, text: String) -> NSPanel {
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

        let contentView = ReminderView(frame: screen.frame, text: text)
        panel.contentView = contentView

        return panel
    }
}

// MARK: - ReminderView

private class ReminderView: NSVisualEffectView {
    private let gradientLayer = CAGradientLayer()
    private let label = NSTextField(labelWithString: "")
    private var breathingAnimation: CABasicAnimation?
    private let text: String

    init(frame: NSRect, text: String) {
        self.text = text
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
            label.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor, multiplier: 0.8)
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
