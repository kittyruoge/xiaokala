//
//  XTTLockViewController.swift
//  xiaokala — X Drive Log
//
//  Biometric lock overlay shown when Face ID protection is enabled.
//

import UIKit

final class XTTLockViewController: UIViewController {

    /// Invoked once the user successfully authenticates.
    var onUnlock: (() -> Void)?

    private let unlockButton = XTTPrimaryButton(title: "Unlock")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        buildUI()
    }

    private func buildUI() {
        let icon = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        icon.tintColor = XTTTheme.accent
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 64, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "X Drive Log Locked"
        title.font = XTTTheme.fontTitle()
        title.textColor = XTTTheme.textPrimary
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Authenticate with \(XTTBiometricManager.shared.biometryLabel) to continue."
        subtitle.font = XTTTheme.fontBody()
        subtitle.textColor = XTTTheme.textSecondary
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        unlockButton.addTarget(self, action: #selector(beginAuthentication), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.setCustomSpacing(24, after: icon)
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.xtt_addSubviews(stack, unlockButton)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),

            unlockButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            unlockButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            unlockButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32)
        ])
    }

    @objc func beginAuthentication() {
        XTTBiometricManager.shared.authenticate(reason: "Unlock X Drive Log") { [weak self] success in
            if success {
                XTTHaptics.success()
                self?.onUnlock?()
            } else {
                XTTHaptics.warning()
            }
        }
    }
}
