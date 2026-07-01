//
//  XTTComponents.swift
//  xiaokala — X Drive Log
//
//  Reusable dark-automotive UI building blocks.
//

import UIKit

// MARK: - Navigation controller

/// Navigation controller with the app's dark styling baked in.
final class XTTNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func applyStyle() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = XTTTheme.background
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .foregroundColor: XTTTheme.textPrimary,
            .font: XTTTheme.fontHeadline()
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: XTTTheme.textPrimary,
            .font: XTTTheme.fontHero()
        ]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = XTTTheme.accent
        navigationBar.prefersLargeTitles = true
    }
}

// MARK: - Card

/// Rounded card container with subtle border and shadow.
final class XTTCardView: UIView {

    init(fill: UIColor = XTTTheme.card) {
        super.init(frame: .zero)
        backgroundColor = fill
        layer.cornerRadius = XTTTheme.cardCornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor
        xtt_applyCardShadow()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Gradient view

/// A view whose layer is a `CAGradientLayer`, useful for hero panels.
final class XTTGradientView: UIView {

    override class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    init(colors: [CGColor],
         start: CGPoint = CGPoint(x: 0, y: 0),
         end: CGPoint = CGPoint(x: 1, y: 1)) {
        super.init(frame: .zero)
        gradientLayer.colors = colors
        gradientLayer.startPoint = start
        gradientLayer.endPoint = end
        layer.cornerRadius = XTTTheme.cardCornerRadius
        layer.cornerCurve = .continuous
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Primary button

/// Filled pill button with press animation.
final class XTTPrimaryButton: UIButton {

    private var fillColor: UIColor = XTTTheme.accent

    init(title: String, fill: UIColor = XTTTheme.accent) {
        super.init(frame: .zero)
        fillColor = fill
        setTitle(title, for: .normal)
        setTitleColor(.white, for: .normal)
        titleLabel?.font = XTTTheme.fontHeadline()
        backgroundColor = fill
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        heightAnchor.constraint(equalToConstant: 54).isActive = true
        addTarget(self, action: #selector(pressDown), for: [.touchDown, .touchDragEnter])
        addTarget(self, action: #selector(pressUp), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var isEnabled: Bool {
        didSet { alpha = isEnabled ? 1.0 : 0.45 }
    }

    @objc private func pressDown() {
        UIView.animate(withDuration: 0.12) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
            self.backgroundColor = self.fillColor.xtt_darkened(by: 0.12)
        }
    }

    @objc private func pressUp() {
        UIView.animate(withDuration: 0.18) {
            self.transform = .identity
            self.backgroundColor = self.fillColor
        }
    }
}

// MARK: - Secondary (ghost) button

final class XTTGhostButton: UIButton {

    init(title: String) {
        super.init(frame: .zero)
        setTitle(title, for: .normal)
        setTitleColor(XTTTheme.textSecondary, for: .normal)
        titleLabel?.font = XTTTheme.fontHeadline()
        backgroundColor = .clear
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor
        heightAnchor.constraint(equalToConstant: 54).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Text field

/// Padded, dark-styled text field with a leading SF Symbol.
final class XTTTextField: UITextField {

    private let padding = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 16)
    private let iconView = UIImageView()
    /// Right-side reveal button, present only for secure fields.
    private var revealButton: UIButton?

    init(placeholder: String, symbol: String, secure: Bool = false) {
        super.init(frame: .zero)

        backgroundColor = XTTTheme.surface
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor
        textColor = XTTTheme.textPrimary
        tintColor = XTTTheme.accent
        font = XTTTheme.fontBody()
        isSecureTextEntry = secure
        autocapitalizationType = .none
        autocorrectionType = .no

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: XTTTheme.textTertiary]
        )

        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = XTTTheme.textSecondary
        iconView.contentMode = .scaleAspectFit
        iconView.frame = CGRect(x: 16, y: 0, width: 22, height: 22)
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 48, height: 52))
        iconView.center = CGPoint(x: 27, y: 26)
        container.addSubview(iconView)
        leftView = container
        leftViewMode = .always

        if secure {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
            button.tintColor = XTTTheme.textSecondary
            button.frame = CGRect(x: 0, y: 0, width: 44, height: 52)
            button.addTarget(self, action: #selector(toggleReveal), for: .touchUpInside)
            revealButton = button
            rightView = button
            rightViewMode = .always
        }

        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func toggleReveal() {
        isSecureTextEntry.toggle()
        let symbol = isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        revealButton?.setImage(UIImage(systemName: symbol), for: .normal)
        // Preserve caret position after toggling secure entry.
        if let existing = text {
            text = ""
            text = existing
        }
    }

    override func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: bounds.width - 44, y: 0, width: 44, height: bounds.height)
    }

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        bounds.inset(by: padding)
    }
}

// MARK: - Section header label

final class XTTSectionHeader: UILabel {
    init(_ title: String) {
        super.init(frame: .zero)
        text = title.uppercased()
        font = XTTTheme.fontCaption()
        textColor = XTTTheme.textTertiary
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Pill / chip label

final class XTTChip: UIView {

    private let label = UILabel()

    init(text: String, tint: UIColor) {
        super.init(frame: .zero)
        backgroundColor = tint.withAlphaComponent(0.18)
        layer.cornerRadius = 9
        layer.cornerCurve = .continuous

        label.text = text
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.textColor = tint
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            label.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Empty state

/// Centered empty-state placeholder with icon, title and message.
final class XTTEmptyStateView: UIView {

    init(symbol: String, title: String, message: String) {
        super.init(frame: .zero)

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = XTTTheme.textTertiary
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 46, weight: .regular)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = XTTTheme.fontHeadline()
        titleLabel.textColor = XTTTheme.textSecondary
        titleLabel.textAlignment = .center

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = XTTTheme.fontBody()
        messageLabel.textColor = XTTTheme.textTertiary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let stack = UIStackView(arrangedSubviews: [icon, titleLabel, messageLabel])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 10
        stack.setCustomSpacing(16, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -20),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -40)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
