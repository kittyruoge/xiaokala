//
//  XTTFuelListViewController.swift
//  xiaokala — X Drive Log
//
//  Fuel entry history.
//

import UIKit

final class XTTFuelListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView(
        symbol: "fuelpump.fill",
        title: "No Fuel Records",
        message: "Tap + to log a fill-up.")

    private var entries: [XTTFuelEntry] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        setupTable()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(XTTLogCell.self, forCellReuseIdentifier: "fuel")
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)

        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view)
    }

    @objc private func refresh() {
        entries = XTTDataStore.shared.fuelEntries.sorted { $0.date > $1.date }
        emptyState.isHidden = !entries.isEmpty
        tableView.reloadData()
    }
}

extension XTTFuelListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        entries.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fuel", for: indexPath) as! XTTLogCell
        let entry = entries[indexPath.row]
        let vehicleName = XTTDataStore.shared.vehicle(withID: entry.vehicleID)?.name ?? "Vehicle"
        var subtitle = vehicleName
        if entry.liters > 0 {
            subtitle += " · \(XTTFormat.volume(entry.liters))"
        }
        if !entry.station.isEmpty {
            subtitle += " · \(entry.station)"
        }
        cell.configure(symbol: "fuelpump.fill",
                       tint: XTTTheme.amber,
                       title: XTTFormat.currency(entry.amount),
                       subtitle: subtitle,
                       value: XTTFormat.distanceInt(entry.odometer),
                       date: entry.date)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let entry = entries[indexPath.row]
        XTTAuthGate.require("Editing a fuel entry", from: self) { [weak self] in
            guard let self = self else { return }
            let editor = XTTFuelEditViewController(entry: entry, defaultVehicleID: entry.vehicleID)
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let entry = entries[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            XTTAuthGate.require("Deleting a fuel entry", from: self) {
                XTTDataStore.shared.deleteFuel(entry)
                XTTHaptics.success()
            }
            done(true)
        }
        delete.backgroundColor = XTTTheme.danger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
