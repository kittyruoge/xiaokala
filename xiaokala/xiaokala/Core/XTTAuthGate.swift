//
//  XTTAuthGate.swift
//  xiaokala — X Drive Log
//
//  Gates account-only actions. Guests may browse freely, but any core
//  feature that persists or mutates data prompts a forced login.
//

import UIKit

enum XTTAuthGate {

    /// True only when a real account session is active (not guest).
    static var isAuthenticated: Bool {
        XTTAuthManager.shared.state == .authenticated
    }

    /// Runs `onAuthorized` immediately when signed in. For guests, presents a
    /// login gate describing the `feature` that requires an account.
    static func require(_ feature: String,
                        from presenter: UIViewController,
                        onAuthorized: @escaping () -> Void) {
        if isAuthenticated {
            onAuthorized()
            return
        }
        XTTHaptics.warning()
        let form = XTTAuthFormViewController(mode: .login, gateFeature: feature)
        let nav = XTTNavigationController(rootViewController: form)
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }
}
