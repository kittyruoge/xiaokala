//
//  SceneDelegate.swift
//  xiaokala
//
//  X Drive Log
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        window.overrideUserInterfaceStyle = .dark
        window.backgroundColor = XTTTheme.background
        self.window = window

        XTTAppRouter.shared.attach(to: window)
        XTTAppRouter.shared.start()

        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {
        XTTAppRouter.shared.handleBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        XTTAppRouter.shared.handleResignActive()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {
        XTTAppRouter.shared.handleEnterBackground()
    }
}
