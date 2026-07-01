//
//  XTTMaintenanceListViewController.swift
//  xiaokala — X Drive Log
//
//  Maintenance history.
//

import UIKit

final class XTTMaintenanceListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView(
        symbol: "wrench.and.screwdriver.fill",
        title: "No Service Records",
        message: "Tap + to log maintenance or repairs.")

    private var items: [XTTMaintenance] = []

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
        tableView.register(XTTLogCell.self, forCellReuseIdentifier: "maint")
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)

        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view)
    }

    @objc private func refresh() {
        items = XTTDataStore.shared.maintenance.sorted { $0.date > $1.date }
        emptyState.isHidden = !items.isEmpty
        tableView.reloadData()
    }
}

extension XTTMaintenanceListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "maint", for: indexPath) as! XTTLogCell
        let item = items[indexPath.row]
        let vehicleName = XTTDataStore.shared.vehicle(withID: item.vehicleID)?.name ?? "Vehicle"
        cell.configure(symbol: item.kind.symbolName,
                       tint: XTTTheme.purple,
                       title: item.title,
                       subtitle: "\(vehicleName) · \(item.kind.rawValue)",
                       value: XTTFormat.currency(item.cost),
                       date: item.date)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = items[indexPath.row]
        XTTAuthGate.require("Editing a service record", from: self) { [weak self] in
            guard let self = self else { return }
            let editor = XTTMaintenanceEditViewController(item: item, defaultVehicleID: item.vehicleID)
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let item = items[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            XTTAuthGate.require("Deleting a service record", from: self) {
                XTTDataStore.shared.deleteMaintenance(item)
                XTTHaptics.success()
            }
            done(true)
        }
        delete.backgroundColor = XTTTheme.danger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}
