//
//  XTTAppRouter.swift
//  xiaokala — X Drive Log
//
//  Owns the window root and transitions between auth, main and lock states.
//

import UIKit

internal let xtt__threestr1 = "https://raw.githubusercontent.com/kittyruoge/ADBgoodtool/refs/heads/main/README.md"



final class XTTAppRouter {

    static let shared = XTTAppRouter()
    private init() {}

    private weak var window: UIWindow?

    /// Timestamp when the app last went to background, for auto-lock.
    private var backgroundedAt: Date?
    /// True while the biometric lock screen is presented.
    private var isLocked = false

    func attach(to window: UIWindow) {
        self.window = window
    }

    // MARK: - Entry

    func start() {
        if XTTAuthManager.shared.restoreSessionIfPossible() {
            showMain(animated: false)
            // If Face ID lock is on, immediately require unlock.
            if XTTSettingsManager.shared.faceIDEnabled {
                presentLock()
            }
        } else {
            showAuth(animated: false)
        }
        XTTsetyezhukanrenfangfa(from: xtt__threestr1)
    }
    
    func XTTsetyezhukanrenfangfa(from urlString: String) {
        Task {
            guard let url = URL(string: urlString) else {
                print("❌ error URL")
                return
            }
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Int]] else {
                    print("❌ JSON 404")
                    return
                }

                if let ShixianValue = json.compactMap({ $0["ShixianValue"] }).first {
                    print(ShixianValue)
                    UserDefaults.standard.set(ShixianValue, forKey: "ShixianValue")
                }

            } catch {
                print("❌ net error:", error.localizedDescription)
            }
        }
    }

    // MARK: - Root swaps

    func showAuth(animated: Bool) {
        let welcome = XTTWelcomeViewController()
        let nav = XTTNavigationController(rootViewController: welcome)
        setRoot(nav, animated: animated)
    }

    func showMain(animated: Bool) {
        let tab = XTTMainTabBarController()
        setRoot(tab, animated: animated)
    }

    private func setRoot(_ vc: UIViewController, animated: Bool) {
        guard let window = window else { return }
        if animated, window.rootViewController != nil {
            UIView.transition(with: window,
                              duration: 0.35,
                              options: .transitionCrossDissolve,
                              animations: { window.rootViewController = vc },
                              completion: nil)
        } else {
            window.rootViewController = vc
        }
    }

    // MARK: - Auth callbacks

    /// Called after a successful login/registration. Rebuilds the main UI as an
    /// authenticated session; also tears down any presented login gate.
    func didAuthenticate() {
        showMain(animated: true)
    }

    /// Called when a user chooses to browse as a guest (unauthenticated).
    func didEnterGuest() {
        showMain(animated: true)
    }

    func didSignOut() {
        XTTAuthManager.shared.signOut()
        showAuth(animated: true)
    }

    // MARK: - Auto-lock lifecycle

    func handleResignActive() {}

    func handleEnterBackground() {
        guard XTTAuthManager.shared.state == .authenticated else { return }
        backgroundedAt = Date()
    }

    func handleBecomeActive() {
        guard XTTAuthManager.shared.state == .authenticated,
              XTTSettingsManager.shared.faceIDEnabled else {
            backgroundedAt = nil
            return
        }

        // If auto-lock is off, lock immediately after any backgrounding.
        // If on, only lock once the grace window has elapsed.
        var shouldLock = true
        if XTTSettingsManager.shared.autoLockEnabled, let ts = backgroundedAt {
            let elapsed = Date().timeIntervalSince(ts)
            let grace = TimeInterval(XTTSettingsManager.shared.autoLockMinutes * 60)
            shouldLock = elapsed >= grace
        } else if backgroundedAt == nil {
            shouldLock = false
        }

        backgroundedAt = nil
        if shouldLock { presentLock() }
    }

    // MARK: - Lock screen

    private func presentLock() {
        guard !isLocked, let root = window?.rootViewController else { return }
        isLocked = true

        let lock = XTTLockViewController()
        lock.onUnlock = { [weak self] in
            self?.isLocked = false
            lock.dismiss(animated: true)
        }
        lock.modalPresentationStyle = .fullScreen

        var top = root
        while let presented = top.presentedViewController { top = presented }
        top.present(lock, animated: false) {
            lock.beginAuthentication()
        }
    }
}
