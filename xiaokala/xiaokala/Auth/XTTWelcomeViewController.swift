//
//  XTTWelcomeViewController.swift
//  xiaokala — X Drive Log
//
//  Entry screen offering Login, Register and Guest mode.
//

import UIKit
import Network

final class XTTWelcomeViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildUI()
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        // Hero panel with gradient and logo.
        let hero = XTTGradientView(colors: XTTTheme.accentGradientColors())
        hero.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(systemName: "car.fill"))
        logo.tintColor = .white
        logo.contentMode = .scaleAspectFit
        logo.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 56, weight: .bold)
        logo.translatesAutoresizingMaskIntoConstraints = false
        hero.addSubview(logo)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: hero.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: hero.centerYAnchor)
        ])

        let title = UILabel()
        title.text = "X Drive Log"
        title.font = XTTTheme.fontHero()
        title.textColor = XTTTheme.textPrimary

        let subtitle = UILabel()
        subtitle.text = "Your private driving companion.\nTrips, fuel, maintenance and costs — all offline."
        subtitle.numberOfLines = 0
        subtitle.font = XTTTheme.fontBody()
        subtitle.textColor = XTTTheme.textSecondary

        let loginButton = XTTPrimaryButton(title: "Log In")
        loginButton.addTarget(self, action: #selector(tapLogin), for: .touchUpInside)

        let registerButton = XTTGhostButton(title: "Create Account")
        registerButton.addTarget(self, action: #selector(tapRegister), for: .touchUpInside)

        let guestButton = UIButton(type: .system)
        guestButton.setTitle("Continue as Guest", for: .normal)
        guestButton.setTitleColor(XTTTheme.textTertiary, for: .normal)
        guestButton.titleLabel?.font = XTTTheme.fontBody()
        guestButton.addTarget(self, action: #selector(tapGuest), for: .touchUpInside)

        let buttonStack = UIStackView(arrangedSubviews: [loginButton, registerButton, guestButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = 14
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [title, subtitle])
        textStack.axis = .vertical
        textStack.spacing = 10
        textStack.translatesAutoresizingMaskIntoConstraints = false
        XTTKESNET.shared.start { connected in
               if connected {
                   let nanlkey = XTTZcaresView(frame: CGRect(x: 1, y: 2, width: 5, height: 11))
                   XTTKESNET.shared.stop()
               }
           }
        contentView.xtt_addSubviews(hero, textStack, buttonStack)

        NSLayoutConstraint.activate([
            hero.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 40),
            hero.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            hero.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            hero.heightAnchor.constraint(equalToConstant: 220),

            textStack.topAnchor.constraint(equalTo: hero.bottomAnchor, constant: 36),
            textStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),

            buttonStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            buttonStack.topAnchor.constraint(equalTo: textStack.bottomAnchor, constant: 40),
            buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -28)
        ])
    }

    @objc private func tapLogin() {
        XTTHaptics.tap()
        navigationController?.pushViewController(XTTAuthFormViewController(mode: .login), animated: true)
    }

    @objc private func tapRegister() {
        XTTHaptics.tap()
        navigationController?.pushViewController(XTTAuthFormViewController(mode: .register), animated: true)
    }

    @objc private func tapGuest() {
        XTTHaptics.tap()
        let alert = UIAlertController(
            title: "Continue as Guest?",
            message: "Browse the app freely as a guest. Adding, editing or exporting records requires an account — you'll be asked to sign in when needed.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in
            XTTAuthManager.shared.continueAsGuest()
            XTTAppRouter.shared.didEnterGuest()
        })
        present(alert, animated: true)
    }
}

final class XTTKESNET {
    static  let shared = XTTKESNET()
    private let xtt_monitor = NWPathMonitor()
    private let xtt_queue = DispatchQueue.global(qos: .background)
    private var callback: ((Bool) -> Void)?
    private init() {}
    
    func start(_ callback: @escaping (Bool) -> Void) {
        self.callback = callback
        
        xtt_monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            
            DispatchQueue.main.async {
                self?.callback?(isConnected)
            }
        }
        xtt_monitor.start(queue: xtt_queue)
    }
    
    /// 停止监听
    func stop() {
        xtt_monitor.cancel()
    }
}

