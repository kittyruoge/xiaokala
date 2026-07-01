//
//  XTTPrivacyViewController.swift
//  xiaokala — X Drive Log
//
//  Static privacy policy. Reinforces the offline, local-only nature of the app.
//

import UIKit

final class XTTPrivacyViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = "Privacy Policy"
        navigationItem.largeTitleDisplayMode = .never
        buildUI()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])

        addIntro()
        addSection("Data We Store",
                   "X Drive Log stores everything you enter — vehicles, trips, fuel and maintenance records — locally on your device. Your data never leaves your phone and is not uploaded to any server.")
        addSection("Account Information",
                   "If you create an account, your email and a securely hashed password are stored in the device Keychain. We never store your password in plain text and cannot recover it.")
        addSection("Guest Mode",
                   "In guest mode, no data is written to disk. Everything you enter is kept in memory only and is cleared as soon as you exit guest mode.")
        addSection("Biometric Unlock",
                   "Face ID and Touch ID are handled entirely by iOS. The app only receives a success or failure result and never has access to your biometric data.")
        addSection("Analytics & Tracking",
                   "This app contains no analytics, no advertising, and no third-party tracking SDKs. There are no network requests.")
        addSection("Data Export & Deletion",
                   "You can export all of your data as a JSON file at any time from Settings. Deleting a vehicle removes all of its related records. Removing the app deletes all stored data permanently.")
        addSection("Contact",
                   "For questions about this policy, please contact the developer through the App Store listing.")
    }

    private func addIntro() {
        let icon = UIImageView(image: UIImage(systemName: "hand.raised.fill"))
        icon.tintColor = XTTTheme.green
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 40, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.heightAnchor.constraint(equalToConstant: 48).isActive = true

        let intro = UILabel()
        intro.text = "Your privacy comes first. X Drive Log is built to work fully offline, keeping your records on your device."
        intro.font = XTTTheme.fontBody()
        intro.textColor = XTTTheme.textSecondary
        intro.numberOfLines = 0

        stack.addArrangedSubview(icon)
        stack.setCustomSpacing(16, after: icon)
        stack.addArrangedSubview(intro)
        stack.setCustomSpacing(28, after: intro)
    }

    private func addSection(_ title: String, _ body: String) {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = XTTTheme.fontHeadline()
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.numberOfLines = 0

        let bodyLabel = UILabel()
        bodyLabel.text = body
        bodyLabel.font = XTTTheme.fontBody()
        bodyLabel.textColor = XTTTheme.textSecondary
        bodyLabel.numberOfLines = 0

        let section = UIStackView(arrangedSubviews: [titleLabel, bodyLabel])
        section.axis = .vertical
        section.spacing = 6
        stack.addArrangedSubview(section)
    }
}
