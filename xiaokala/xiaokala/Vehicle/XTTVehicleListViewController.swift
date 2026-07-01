//
//  XTTVehicleListViewController.swift
//  xiaokala — X Drive Log
//
//  Lists all vehicles with add / edit / delete.
//

import UIKit

final class XTTVehicleListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView(
        symbol: "car.2.fill",
        title: "No Vehicles Yet",
        message: "Add your first vehicle to start logging trips, fuel and maintenance.")

    private var vehicles: [XTTVehicle] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationItem.largeTitleDisplayMode = .always
        setupNav()
        setupTable()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    private func setupNav() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add, target: self, action: #selector(tapAdd))
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(XTTVehicleCell.self, forCellReuseIdentifier: "vehicle")
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)

        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view.safeAreaLayoutGuide)
    }

    @objc private func refresh() {
        vehicles = XTTDataStore.shared.vehicles.sorted { $0.createdAt < $1.createdAt }
        emptyState.isHidden = !vehicles.isEmpty
        tableView.reloadData()
    }

    @objc private func tapAdd() {
        XTTHaptics.tap()
        XTTAuthGate.require("Adding a vehicle", from: self) { [weak self] in
            guard let self = self else { return }
            let editor = XTTVehicleEditViewController(vehicle: nil)
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }
}

extension XTTVehicleListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        vehicles.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "vehicle", for: indexPath) as! XTTVehicleCell
        cell.configure(with: vehicles[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vehicle = vehicles[indexPath.row]
        XTTAuthGate.require("Editing a vehicle", from: self) { [weak self] in
            guard let self = self else { return }
            let editor = XTTVehicleEditViewController(vehicle: vehicle)
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let vehicle = vehicles[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            XTTAuthGate.require("Deleting a vehicle", from: self) {
                self.confirmDelete(vehicle)
            }
            done(true)
        }
        delete.backgroundColor = XTTTheme.danger
        return UISwipeActionsConfiguration(actions: [delete])
    }

    private func confirmDelete(_ vehicle: XTTVehicle) {
        let alert = UIAlertController(
            title: "Delete \(vehicle.name)?",
            message: "This also removes all related trips, fuel and maintenance records. This cannot be undone.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteVehicle(vehicle)
            XTTHaptics.success()
        })
        present(alert, animated: true)
    }
}

// MARK: - Cell

final class XTTVehicleCell: UITableViewCell {

    private let card = XTTCardView()
    private let colorBar = UIView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let odoLabel = UILabel()
    private let fuelChipContainer = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func buildUI() {
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        colorBar.layer.cornerRadius = 4
        colorBar.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = XTTTheme.fontHeadline()
        nameLabel.textColor = XTTTheme.textPrimary
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = XTTTheme.fontCaption()
        subtitleLabel.textColor = XTTTheme.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        odoLabel.font = XTTTheme.fontMono(15, weight: .semibold)
        odoLabel.textColor = XTTTheme.accent
        odoLabel.textAlignment = .right
        odoLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [nameLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(colorBar, textStack, odoLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 76),

            colorBar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            colorBar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            colorBar.widthAnchor.constraint(equalToConstant: 8),
            colorBar.heightAnchor.constraint(equalToConstant: 44),

            textStack.leadingAnchor.constraint(equalTo: colorBar.trailingAnchor, constant: 14),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 14),

            odoLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            odoLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            odoLabel.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 8)
        ])
    }

    func configure(with vehicle: XTTVehicle) {
        nameLabel.text = vehicle.name
        subtitleLabel.text = "\(vehicle.displaySubtitle) · \(vehicle.fuelType.rawValue)"
        odoLabel.text = XTTFormat.distanceInt(vehicle.odometer)
        colorBar.backgroundColor = UIColor(xtt_hex: vehicle.colorHex) ?? XTTTheme.accent
    }
}

// MARK: - Hex colour init

extension UIColor {
    /// Creates a colour from a 6-digit hex string (no leading #).
    convenience init?(xtt_hex hex: String) {
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value), hex.count == 6 else { return nil }
        let r = CGFloat((value & 0xFF0000) >> 16) / 255
        let g = CGFloat((value & 0x00FF00) >> 8) / 255
        let b = CGFloat(value & 0x0000FF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
