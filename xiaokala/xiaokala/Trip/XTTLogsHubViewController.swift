//
//  XTTLogsHubViewController.swift
//  xiaokala — X Drive Log
//
//  Segmented hub over Trips, Fuel and Maintenance logs.
//

import UIKit

final class XTTLogsHubViewController: UIViewController {

    private let segmented = UISegmentedControl(items: ["Trips", "Fuel", "Service"])
    private let container = UIView()

    private lazy var tripsVC = XTTTripListViewController()
    private lazy var fuelVC = XTTFuelListViewController()
    private lazy var maintVC = XTTMaintenanceListViewController()
    private var current: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationItem.largeTitleDisplayMode = .always
        setupNav()
        setupSegmented()
        setupContainer()
        select(index: 0)
    }

    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(tapAdd))
    }

    private func setupSegmented() {
        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = XTTTheme.accent
        segmented.backgroundColor = XTTTheme.surface
        segmented.setTitleTextAttributes([.foregroundColor: XTTTheme.textSecondary], for: .normal)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        view.addSubview(segmented)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            segmented.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            segmented.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    private func setupContainer() {
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    @objc private func segmentChanged() {
        select(index: segmented.selectedSegmentIndex)
        XTTHaptics.tap()
    }

    private func select(index: Int) {
        let target: UIViewController
        switch index {
        case 1: target = fuelVC
        case 2: target = maintVC
        default: target = tripsVC
        }

        current?.willMove(toParent: nil)
        current?.view.removeFromSuperview()
        current?.removeFromParent()

        addChild(target)
        target.view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(target.view)
        target.view.xtt_pinEdges(to: container)
        target.didMove(toParent: self)
        current = target
    }

    @objc private func tapAdd() {
        XTTHaptics.tap()
        let feature: String
        switch segmented.selectedSegmentIndex {
        case 1: feature = "Adding a fuel entry"
        case 2: feature = "Adding a service record"
        default: feature = "Adding a trip"
        }

        XTTAuthGate.require(feature, from: self) { [weak self] in
            guard let self = self else { return }
            guard let vehicle = XTTDataStore.shared.vehicles.first else {
                let alert = UIAlertController(
                    title: "Add a Vehicle First",
                    message: "You need at least one vehicle before adding records.",
                    preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }

            let editor: UIViewController
            switch self.segmented.selectedSegmentIndex {
            case 1: editor = XTTFuelEditViewController(entry: nil, defaultVehicleID: vehicle.id)
            case 2: editor = XTTMaintenanceEditViewController(item: nil, defaultVehicleID: vehicle.id)
            default: editor = XTTTripEditViewController(trip: nil, defaultVehicleID: vehicle.id)
            }
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }
}
