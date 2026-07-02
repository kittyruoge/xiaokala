//
//  XTTAuthFormViewController.swift
//  xiaokala — X Drive Log
//
//  Shared login / register form.
//

import UIKit

final class XTTAuthFormViewController: UIViewController {

    enum Mode {
        case login
        case register

        var title: String { self == .login ? "Log In" : "Create Account" }
        var action: String { self == .login ? "Log In" : "Register" }
    }

    private let mode: Mode
    /// When set, the form was presented as a modal gate for this feature.
    private let gateFeature: String?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private lazy var nameField = XTTTextField(placeholder: "Display Name", symbol: "person.fill")
    private lazy var emailField = XTTTextField(placeholder: "Account", symbol: "envelope.fill")
    private lazy var passwordField = XTTTextField(placeholder: "Password", symbol: "lock.fill", secure: true)
    private lazy var submitButton = XTTPrimaryButton(title: mode.action)
    private let errorLabel = UILabel()

    private var isGate: Bool { gateFeature != nil }

    init(mode: Mode, gateFeature: String? = nil) {
        self.mode = mode
        self.gateFeature = gateFeature
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = mode.title
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.largeTitleDisplayMode = .always
        if isGate {
            navigationItem.leftBarButtonItem = UIBarButtonItem(
                barButtonSystemItem: .cancel, target: self, action: #selector(tapCancel))
        }
        buildUI()
        registerKeyboardHandlers()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        emailField.keyboardType = .emailAddress
        emailField.textContentType = .username
        passwordField.textContentType = mode == .login ? .password : .newPassword

        errorLabel.font = XTTTheme.fontCaption()
        errorLabel.textColor = XTTTheme.danger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let hint = UILabel()
        hint.font = XTTTheme.fontBody()
        hint.textColor = XTTTheme.textSecondary
        hint.numberOfLines = 0
        if let feature = gateFeature {
            hint.text = "\(feature) requires an account. Sign in or create one to continue — your data stays on this device."
        } else {
            hint.text = mode == .login
                ? "Welcome back. Sign in to access your saved records."
                : "Create a local account. Your credentials stay on this device — nothing is uploaded."
        }

        if mode == .register { stack.addArrangedSubview(nameField) }
        stack.addArrangedSubview(emailField)
        stack.addArrangedSubview(passwordField)
        stack.addArrangedSubview(errorLabel)
        stack.addArrangedSubview(submitButton)
        stack.setCustomSpacing(24, after: passwordField)

        submitButton.addTarget(self, action: #selector(tapSubmit), for: .touchUpInside)

        if isGate {
            // Gated: offer switching to registration instead of skipping.
            if mode == .login {
                let createButton = XTTGhostButton(title: "Create Account")
                createButton.addTarget(self, action: #selector(tapSwitchToRegister), for: .touchUpInside)
                stack.addArrangedSubview(createButton)
                stack.setCustomSpacing(14, after: submitButton)
            }
        } else {
            // Welcome flow: allow skipping straight into guest browsing.
            let skipButton = UIButton(type: .system)
            skipButton.setTitle("Skip · Continue as Guest", for: .normal)
            skipButton.setTitleColor(XTTTheme.textTertiary, for: .normal)
            skipButton.titleLabel?.font = XTTTheme.fontBody()
            skipButton.addTarget(self, action: #selector(tapSkip), for: .touchUpInside)
            stack.addArrangedSubview(skipButton)
            stack.setCustomSpacing(14, after: submitButton)
        }

        let headerStack = UIStackView(arrangedSubviews: [hint])
        headerStack.axis = .vertical
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        stack.insertArrangedSubview(headerStack, at: 0)
        stack.setCustomSpacing(24, after: headerStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -48)
        ])
    }

    // MARK: - Actions

    @objc private func tapCancel() {
        dismiss(animated: true)
    }

    @objc private func tapSwitchToRegister() {
        XTTHaptics.tap()
        let form = XTTAuthFormViewController(mode: .register, gateFeature: gateFeature)
        navigationController?.pushViewController(form, animated: true)
    }

    @objc private func tapSkip() {
        XTTHaptics.tap()
        let alert = UIAlertController(
            title: "Continue as Guest?",
            message: "Guest mode lets you browse the app. Records you add are temporary and require an account to save.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            XTTAuthManager.shared.continueAsGuest()
            XTTAppRouter.shared.didEnterGuest()
        })
        present(alert, animated: true)
    }

    @objc private func tapSubmit() {
        view.endEditing(true)
        errorLabel.isHidden = true

        let email = emailField.text?.trimmingCharacters(in: .whitespaces) ?? ""
        let password = passwordField.text ?? ""
        let name = nameField.text?.trimmingCharacters(in: .whitespaces) ?? ""

        do {
            switch mode {
            case .login:
                try XTTAuthManager.shared.login(email: email, password: password)
            case .register:
                try XTTAuthManager.shared.register(email: email, displayName: name, password: password)
            }
            XTTHaptics.success()
            XTTAppRouter.shared.didAuthenticate()
        } catch {
            XTTHaptics.warning()
            showError(error.localizedDescription)
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
        UIView.animate(withDuration: 0.2) { self.stack.layoutIfNeeded() }
    }

    // MARK: - Keyboard

    private func registerKeyboardHandlers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillChange(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillChange(_ note: Notification) {
        guard let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let overlap = view.bounds.height - view.convert(frame, from: nil).origin.y
        scrollView.contentInset.bottom = max(0, overlap)
        scrollView.verticalScrollIndicatorInsets.bottom = max(0, overlap)
    }

    @objc private func keyboardWillHide() {
        scrollView.contentInset.bottom = 0
        scrollView.verticalScrollIndicatorInsets.bottom = 0
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
