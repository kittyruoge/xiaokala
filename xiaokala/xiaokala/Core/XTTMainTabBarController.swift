//
//  XTTMainTabBarController.swift
//  xiaokala — X Drive Log
//
//  Root tab bar with the five primary sections.
//

import UIKit

final class XTTMainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        applyStyle()
        buildTabs()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func applyStyle() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = XTTTheme.surface
        appearance.shadowColor = XTTTheme.stroke

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = XTTTheme.textTertiary
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: XTTTheme.textTertiary]
        itemAppearance.selected.iconColor = XTTTheme.accent
        itemAppearance.selected.titleTextAttributes = [.foregroundColor: XTTTheme.accent]
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = XTTTheme.accent
    }

    private func buildTabs() {
        
        let dashboard = wrap(XTTDashboardViewController(),
                             title: "Dashboard", symbol: "gauge.with.dots.needle.67percent")
        let vehicles = wrap(XTTVehicleListViewController(),
                            title: "Vehicles", symbol: "car.2.fill")
        let logs = wrap(XTTLogsHubViewController(),
                        title: "Logs", symbol: "list.bullet.rectangle.fill")
        let stats = wrap(XTTStatisticsViewController(),
                         title: "Stats", symbol: "chart.line.uptrend.xyaxis")
        let settings = wrap(XTTSettingsViewController(),
                            title: "Settings", symbol: "gearshape.fill")

        viewControllers = [dashboard, vehicles, logs, stats, settings]
    }

    private func wrap(_ vc: UIViewController, title: String, symbol: String) -> UINavigationController {
        vc.title = title
        let nav = XTTNavigationController(rootViewController: vc)
        nav.tabBarItem = UITabBarItem(title: title,
                                      image: UIImage(systemName: symbol),
                                      selectedImage: UIImage(systemName: symbol))
        return nav
    }
}
