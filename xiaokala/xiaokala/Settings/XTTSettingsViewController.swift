//
//  XTTSettingsViewController.swift
//  xiaokala — X Drive Log
//
//  Face ID, auto-lock, theme, export and privacy.
//

import UIKit

final class XTTSettingsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let faceIDSwitch = UISwitch()
    private let autoLockSwitch = UISwitch()
    private let autoLockRow = XTTDisclosureRow(title: "Auto-Lock After")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationItem.largeTitleDisplayMode = .always
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncControls()
    }

    // MARK: - UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        buildProfileCard()
        buildSecuritySection()
        buildAppearanceSection()
        buildDataSection()
        buildAboutSection()
        buildSignOut()
    }

    private func buildProfileCard() {
        let card = XTTGradientView(colors: XTTTheme.accentGradientColors())
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 96).isActive = true

        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = .white
        avatar.contentMode = .scaleAspectFit
        avatar.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .regular)
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        let subtitleLabel = UILabel()

        if XTTAuthManager.shared.state == .guest {
            nameLabel.text = "Guest"
            subtitleLabel.text = "Browsing · sign in to save data"
        } else {
            nameLabel.text = XTTAuthManager.shared.currentDisplayName
            subtitleLabel.text = XTTAuthManager.shared.currentEmail
        }
        nameLabel.font = XTTTheme.fontTitle()
        nameLabel.textColor = .white
        subtitleLabel.font = XTTTheme.fontCaption()
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.85)

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(avatar, textStack)
        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 56),
            avatar.heightAnchor.constraint(equalToConstant: 56),

            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 14),
            textStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        stack.addArrangedSubview(card)
        stack.setCustomSpacing(24, after: card)
    }

    private func buildSecuritySection() {
        stack.addArrangedSubview(XTTSectionHeader("Security"))

        faceIDSwitch.onTintColor = XTTTheme.accent
        faceIDSwitch.addTarget(self, action: #selector(toggleFaceID), for: .valueChanged)
        let faceRow = makeToggleRow(
            symbol: "faceid",
            title: XTTBiometricManager.shared.biometryLabel,
            control: faceIDSwitch)
        stack.addArrangedSubview(faceRow)

        autoLockSwitch.onTintColor = XTTTheme.accent
        autoLockSwitch.addTarget(self, action: #selector(toggleAutoLock), for: .valueChanged)
        let lockRow = makeToggleRow(
            symbol: "lock.rotation",
            title: "Auto-Lock",
            control: autoLockSwitch)
        stack.addArrangedSubview(lockRow)

        autoLockRow.addTarget(self, action: #selector(tapAutoLockInterval), for: .touchUpInside)
        stack.addArrangedSubview(autoLockRow)
        stack.setCustomSpacing(24, after: autoLockRow)
    }

    private func buildAppearanceSection() {
        stack.addArrangedSubview(XTTSectionHeader("Appearance"))
        let themeSwitch = UISwitch()
        themeSwitch.onTintColor = XTTTheme.accent
        themeSwitch.isOn = true
        themeSwitch.isEnabled = false // Dark-only by design.
        let row = makeToggleRow(symbol: "moon.stars.fill", title: "Dark Theme", control: themeSwitch)
        stack.addArrangedSubview(row)

        let note = UILabel()
        note.text = "X Drive Log is designed as a dark automotive experience."
        note.font = XTTTheme.fontCaption()
        note.textColor = XTTTheme.textTertiary
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
        stack.setCustomSpacing(24, after: note)
    }

    private func buildDataSection() {
        stack.addArrangedSubview(XTTSectionHeader("Data"))
        stack.addArrangedSubview(makeActionRow(symbol: "square.and.arrow.up.fill",
                                               title: "Export Data",
                                               tint: XTTTheme.accent,
                                               action: #selector(tapExport)))
        stack.setCustomSpacing(24, after: stack.arrangedSubviews.last!)
    }

    private func buildAboutSection() {
        stack.addArrangedSubview(XTTSectionHeader("About"))
        stack.addArrangedSubview(makeActionRow(symbol: "hand.raised.fill",
                                               title: "Privacy Policy",
                                               tint: XTTTheme.green,
                                               action: #selector(tapPrivacy)))

        let versionRow = XTTDisclosureRow(title: "Version")
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        versionRow.setValue(version)
        versionRow.isUserInteractionEnabled = false
        stack.addArrangedSubview(versionRow)
        stack.setCustomSpacing(30, after: versionRow)
    }

    private func buildSignOut() {
        if XTTAuthManager.shared.state == .guest {
            let button = XTTPrimaryButton(title: "Sign In / Create Account", fill: XTTTheme.accent)
            button.addTarget(self, action: #selector(tapGuestSignIn), for: .touchUpInside)
            stack.addArrangedSubview(button)
        } else {
            let button = XTTPrimaryButton(title: "Sign Out", fill: XTTTheme.danger)
            button.addTarget(self, action: #selector(tapSignOut), for: .touchUpInside)
            stack.addArrangedSubview(button)
        }
    }

    // MARK: - Row builders

    private func makeToggleRow(symbol: String, title: String, control: UIView) -> UIView {
        let card = XTTCardView(fill: XTTTheme.surface)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = XTTTheme.textSecondary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = XTTTheme.fontBody()
        label.textColor = XTTTheme.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        control.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(icon, label, control)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            control.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            control.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    private func makeActionRow(symbol: String, title: String, tint: UIColor, action: Selector) -> UIView {
        let card = XTTCardView(fill: XTTTheme.surface)
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 56).isActive = true

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = XTTTheme.fontBody()
        label.textColor = XTTTheme.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = XTTTheme.textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(icon, label, chevron)
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 22),
            icon.heightAnchor.constraint(equalToConstant: 22),

            label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])

        let tap = UITapGestureRecognizer(target: self, action: action)
        card.addGestureRecognizer(tap)
        return card
    }

    // MARK: - State

    private func syncControls() {
        let biometricAvailable = XTTBiometricManager.shared.isBiometricAvailable
        faceIDSwitch.isEnabled = biometricAvailable
        faceIDSwitch.isOn = biometricAvailable && XTTSettingsManager.shared.faceIDEnabled
        autoLockSwitch.isOn = XTTSettingsManager.shared.autoLockEnabled
        updateAutoLockRow()
        autoLockRow.alpha = XTTSettingsManager.shared.autoLockEnabled ? 1 : 0.4
        autoLockRow.isUserInteractionEnabled = XTTSettingsManager.shared.autoLockEnabled
    }

    private func updateAutoLockRow() {
        let minutes = XTTSettingsManager.shared.autoLockMinutes
        autoLockRow.setValue(minutes == 0 ? "Immediately" : "\(minutes) min")
    }

    // MARK: - Actions

    @objc private func toggleFaceID() {
        guard XTTBiometricManager.shared.isBiometricAvailable else {
            faceIDSwitch.setOn(false, animated: true)
            return
        }
        // App lock is an account feature; guests are prompted to sign in.
        if faceIDSwitch.isOn, !XTTAuthGate.isAuthenticated {
            faceIDSwitch.setOn(false, animated: true)
            XTTAuthGate.require("App lock", from: self) {}
            return
        }
        if faceIDSwitch.isOn {
            // Verify the user can authenticate before enabling.
            XTTBiometricManager.shared.authenticate(reason: "Enable \(XTTBiometricManager.shared.biometryLabel)") { [weak self] success in
                if success {
                    XTTSettingsManager.shared.faceIDEnabled = true
                    XTTHaptics.success()
                } else {
                    self?.faceIDSwitch.setOn(false, animated: true)
                }
            }
        } else {
            XTTSettingsManager.shared.faceIDEnabled = false
        }
    }

    @objc private func toggleAutoLock() {
        XTTSettingsManager.shared.autoLockEnabled = autoLockSwitch.isOn
        syncControls()
    }

    @objc private func tapAutoLockInterval() {
        let sheet = UIAlertController(title: "Auto-Lock After", message: nil, preferredStyle: .actionSheet)
        let options: [(String, Int)] = [("Immediately", 0), ("1 minute", 1), ("5 minutes", 5), ("15 minutes", 15)]
        for (title, minutes) in options {
            sheet.addAction(UIAlertAction(title: title, style: .default) { _ in
                XTTSettingsManager.shared.autoLockMinutes = minutes
                self.updateAutoLockRow()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = autoLockRow
            pop.sourceRect = autoLockRow.bounds
        }
        present(sheet, animated: true)
    }

    @objc private func tapExport() {
        XTTHaptics.tap()
        XTTAuthGate.require("Exporting data", from: self) { [weak self] in
            self?.performExport()
        }
    }

    private func performExport() {
        guard let data = XTTDataStore.shared.exportJSONData() else {
            let alert = UIAlertController(title: "Export Failed",
                                          message: "Could not prepare your data. Please try again.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        // Write to a temporary file so it can be shared as a document.
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("XDriveLog-Export.json")
        do {
            try data.write(to: url, options: .atomic)
        } catch {
            return
        }

        let share = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let pop = share.popoverPresentationController {
            pop.sourceView = view
            pop.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        present(share, animated: true)
    }

    @objc private func tapPrivacy() {
        XTTHaptics.tap()
        navigationController?.pushViewController(XTTPrivacyViewController(), animated: true)
    }

    @objc private func tapGuestSignIn() {
        XTTHaptics.tap()
        XTTAuthGate.require("Signing in", from: self) {}
    }

    @objc private func tapSignOut() {
        let alert = UIAlertController(
            title: "Sign Out?",
            message: "You can sign back in anytime.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { _ in
            XTTAppRouter.shared.didSignOut()
        })
        present(alert, animated: true)
    }
}
