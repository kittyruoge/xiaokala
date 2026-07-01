//
//  XTTTripListViewController.swift
//  xiaokala — X Drive Log
//
//  Trip history list.
//

import UIKit

final class XTTTripListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = XTTEmptyStateView(
        symbol: "point.topleft.down.to.point.bottomright.curvepath.fill",
        title: "No Trips Logged",
        message: "Tap + to record your first trip.")

    private var trips: [XTTTrip] = []

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
        tableView.register(XTTLogCell.self, forCellReuseIdentifier: "trip")
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        tableView.showsVerticalScrollIndicator = false
        view.addSubview(tableView)
        tableView.xtt_pinEdges(to: view)

        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view)
    }

    @objc private func refresh() {
        trips = XTTDataStore.shared.trips.sorted { $0.date > $1.date }
        emptyState.isHidden = !trips.isEmpty
        tableView.reloadData()
    }
}

extension XTTTripListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trips.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "trip", for: indexPath) as! XTTLogCell
        let trip = trips[indexPath.row]
        let vehicleName = XTTDataStore.shared.vehicle(withID: trip.vehicleID)?.name ?? "Vehicle"
        cell.configure(symbol: trip.purpose.symbolName,
                       tint: XTTTheme.accent,
                       title: trip.route,
                       subtitle: "\(vehicleName) · \(trip.purpose.rawValue)",
                       value: XTTFormat.distance(trip.distance),
                       date: trip.date)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        XTTAuthGate.require("Editing a trip", from: self) { [weak self] in
            guard let self = self else { return }
            let editor = XTTTripEditViewController(trip: trip, defaultVehicleID: trip.vehicleID)
            self.present(XTTNavigationController(rootViewController: editor), animated: true)
        }
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath)
    -> UISwipeActionsConfiguration? {
        let trip = trips[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, done in
            guard let self = self else { done(false); return }
            XTTAuthGate.require("Deleting a trip", from: self) {
                XTTDataStore.shared.deleteTrip(trip)
                XTTHaptics.success()
            }
            done(true)
        }
        delete.backgroundColor = XTTTheme.danger
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

// MARK: - Shared log cell

/// Generic log row: coloured icon, title/subtitle, trailing value + date.
final class XTTLogCell: UITableViewCell {

    private let card = XTTCardView()
    private let iconBg = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let valueLabel = UILabel()
    private let dateLabel = UILabel()

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

        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(iconView)

        titleLabel.font = XTTTheme.fontHeadline()
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.numberOfLines = 1

        subtitleLabel.font = XTTTheme.fontCaption()
        subtitleLabel.textColor = XTTTheme.textSecondary
        subtitleLabel.numberOfLines = 1

        valueLabel.font = XTTTheme.fontMono(15, weight: .bold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        dateLabel.font = XTTTheme.fontCaption()
        dateLabel.textColor = XTTTheme.textTertiary
        dateLabel.textAlignment = .right

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let valueStack = UIStackView(arrangedSubviews: [valueLabel, dateLabel])
        valueStack.axis = .vertical
        valueStack.spacing = 2
        valueStack.alignment = .trailing
        valueStack.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(iconBg, textStack, valueStack)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 72),

            iconBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconBg.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 40),
            iconBg.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            valueStack.leadingAnchor.constraint(greaterThanOrEqualTo: textStack.trailingAnchor, constant: 10),
            valueStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            valueStack.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
    }

    func configure(symbol: String, tint: UIColor, title: String,
                   subtitle: String, value: String, date: Date) {
        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = tint
        iconBg.backgroundColor = tint.withAlphaComponent(0.18)
        titleLabel.text = title
        subtitleLabel.text = subtitle
        valueLabel.text = value
        dateLabel.text = XTTFormat.shortDate(date)
    }
}
