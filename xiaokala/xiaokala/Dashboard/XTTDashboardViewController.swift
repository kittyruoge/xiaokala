//
//  XTTDashboardViewController.swift
//  xiaokala — X Drive Log
//
//  Overview of vehicles, today's trips and monthly totals.
//

import UIKit

final class XTTDashboardViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    private let greetingLabel = UILabel()
    private let dateLabel = UILabel()

    private let distanceTile = XTTStatTile(symbol: "road.lanes", tint: XTTTheme.accent, caption: "This Month")
    private let costTile = XTTStatTile(symbol: "creditcard.fill", tint: XTTTheme.amber, caption: "Month Cost")
    private let tripsTile = XTTStatTile(symbol: "figure.walk.motion", tint: XTTTheme.green, caption: "Today Trips")
    private let vehiclesTile = XTTStatTile(symbol: "car.2.fill", tint: XTTTheme.purple, caption: "Vehicles")

    private let recentContainer = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationItem.largeTitleDisplayMode = .never
        buildUI()
        NotificationCenter.default.addObserver(self, selector: #selector(refresh),
                                               name: .xttDataChanged, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refresh()
    }

    deinit { NotificationCenter.default.removeObserver(self) }

    // MARK: - UI

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 8),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])

        buildHeader()
        buildStatGrid()
        buildQuickActions()
        buildRecent()
    }

    private func buildHeader() {
        greetingLabel.font = XTTTheme.fontHero()
        greetingLabel.textColor = XTTTheme.textPrimary

        dateLabel.font = XTTTheme.fontBody()
        dateLabel.textColor = XTTTheme.textSecondary
        dateLabel.text = XTTFormat.date(Date())

        let header = UIStackView(arrangedSubviews: [greetingLabel, dateLabel])
        header.axis = .vertical
        header.spacing = 4
        contentStack.addArrangedSubview(header)
    }

    private func buildStatGrid() {
        let topRow = UIStackView(arrangedSubviews: [distanceTile, costTile])
        topRow.axis = .horizontal
        topRow.spacing = 14
        topRow.distribution = .fillEqually

        let bottomRow = UIStackView(arrangedSubviews: [tripsTile, vehiclesTile])
        bottomRow.axis = .horizontal
        bottomRow.spacing = 14
        bottomRow.distribution = .fillEqually

        [distanceTile, costTile, tripsTile, vehiclesTile].forEach {
            $0.heightAnchor.constraint(equalToConstant: 120).isActive = true
        }

        let grid = UIStackView(arrangedSubviews: [topRow, bottomRow])
        grid.axis = .vertical
        grid.spacing = 14
        contentStack.addArrangedSubview(grid)
    }

    private func buildQuickActions() {
        let header = XTTSectionHeader("Quick Add")
        contentStack.addArrangedSubview(header)

        let actions: [(String, String, UIColor, Selector)] = [
            ("Trip", "point.topleft.down.to.point.bottomright.curvepath.fill", XTTTheme.accent, #selector(addTrip)),
            ("Fuel", "fuelpump.fill", XTTTheme.amber, #selector(addFuel)),
            ("Service", "wrench.and.screwdriver.fill", XTTTheme.purple, #selector(addMaintenance))
        ]

        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 14
        row.distribution = .fillEqually

        for (title, symbol, tint, selector) in actions {
            row.addArrangedSubview(makeQuickAction(title: title, symbol: symbol, tint: tint, selector: selector))
        }
        contentStack.addArrangedSubview(row)
    }

    private func makeQuickAction(title: String, symbol: String, tint: UIColor, selector: Selector) -> UIView {
        let card = XTTCardView()
        card.translatesAutoresizingMaskIntoConstraints = false
        card.heightAnchor.constraint(equalToConstant: 92).isActive = true

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        icon.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = XTTTheme.fontCaption()
        label.textColor = XTTTheme.textSecondary
        label.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(icon, label)
        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            icon.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            label.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 12)
        ])

        let tap = UITapGestureRecognizer(target: self, action: selector)
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        return card
    }

    private func buildRecent() {
        let header = XTTSectionHeader("Recent Activity")
        contentStack.addArrangedSubview(header)

        recentContainer.axis = .vertical
        recentContainer.spacing = 10
        contentStack.addArrangedSubview(recentContainer)
    }

    // MARK: - Data

    @objc private func refresh() {
        greetingLabel.text = greeting()

        let store = XTTDataStore.shared
        let calendar = Calendar.current
        let now = Date()

        // Month distance from trips.
        let monthTrips = store.trips.filter {
            calendar.isDate($0.date, equalTo: now, toGranularity: .month)
        }
        let monthDistance = monthTrips.reduce(0) { $0 + $1.distance }
        distanceTile.setValue(XTTFormat.distanceInt(monthDistance))

        // Month cost = fuel + maintenance in current month.
        let monthFuel = store.fuelEntries
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        let monthMaint = store.maintenance
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.cost }
        costTile.setValue(XTTFormat.currencyCompact(monthFuel + monthMaint))

        // Today's trips.
        let todayTrips = store.trips.filter { calendar.isDateInToday($0.date) }.count
        tripsTile.setValue("\(todayTrips)")

        vehiclesTile.setValue("\(store.vehicles.count)")

        rebuildRecent()
    }

    private func rebuildRecent() {
        recentContainer.arrangedSubviews.forEach {
            recentContainer.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        let store = XTTDataStore.shared
        var rows: [(date: Date, symbol: String, tint: UIColor, title: String, detail: String)] = []

        for t in store.trips {
            let vehicleName = store.vehicle(withID: t.vehicleID)?.name ?? "Vehicle"
            rows.append((t.date, "point.topleft.down.to.point.bottomright.curvepath.fill",
                         XTTTheme.accent, t.route, "\(vehicleName) · \(XTTFormat.distance(t.distance))"))
        }
        for f in store.fuelEntries {
            let vehicleName = store.vehicle(withID: f.vehicleID)?.name ?? "Vehicle"
            rows.append((f.date, "fuelpump.fill", XTTTheme.amber,
                         "Fuel · \(XTTFormat.currency(f.amount))", vehicleName))
        }
        for m in store.maintenance {
            let vehicleName = store.vehicle(withID: m.vehicleID)?.name ?? "Vehicle"
            rows.append((m.date, m.kind.symbolName, XTTTheme.purple,
                         m.title, "\(vehicleName) · \(XTTFormat.currency(m.cost))"))
        }

        let recent = rows.sorted { $0.date > $1.date }.prefix(5)

        if recent.isEmpty {
            let empty = makeInfoCard(text: "No activity yet. Add your first trip, fuel or service entry to see it here.")
            recentContainer.addArrangedSubview(empty)
            return
        }

        for row in recent {
            recentContainer.addArrangedSubview(
                makeActivityRow(symbol: row.symbol, tint: row.tint,
                                title: row.title, detail: row.detail, date: row.date)
            )
        }
    }

    private func makeActivityRow(symbol: String, tint: UIColor,
                                 title: String, detail: String, date: Date) -> UIView {
        let card = XTTCardView()

        let iconBg = UIView()
        iconBg.backgroundColor = tint.withAlphaComponent(0.18)
        iconBg.layer.cornerRadius = 10
        iconBg.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: symbol))
        icon.tintColor = tint
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        iconBg.addSubview(icon)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = XTTTheme.fontHeadline()
        titleLabel.textColor = XTTTheme.textPrimary
        titleLabel.numberOfLines = 1

        let detailLabel = UILabel()
        detailLabel.text = detail
        detailLabel.font = XTTTheme.fontCaption()
        detailLabel.textColor = XTTTheme.textSecondary
        detailLabel.numberOfLines = 1

        let dateBadge = UILabel()
        dateBadge.text = XTTFormat.shortDate(date)
        dateBadge.font = XTTTheme.fontCaption()
        dateBadge.textColor = XTTTheme.textTertiary
        dateBadge.setContentHuggingPriority(.required, for: .horizontal)

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(iconBg, textStack, dateBadge)
        dateBadge.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 66),

            iconBg.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            iconBg.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            iconBg.widthAnchor.constraint(equalToConstant: 40),
            iconBg.heightAnchor.constraint(equalToConstant: 40),

            icon.centerXAnchor.constraint(equalTo: iconBg.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: iconBg.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20),

            textStack.leadingAnchor.constraint(equalTo: iconBg.trailingAnchor, constant: 12),
            textStack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: card.topAnchor, constant: 12),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -12),

            dateBadge.leadingAnchor.constraint(equalTo: textStack.trailingAnchor, constant: 10),
            dateBadge.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            dateBadge.centerYAnchor.constraint(equalTo: card.centerYAnchor)
        ])
        return card
    }

    private func makeInfoCard(text: String) -> UIView {
        let card = XTTCardView()
        let label = UILabel()
        label.text = text
        label.font = XTTTheme.fontBody()
        label.textColor = XTTTheme.textSecondary
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)
        label.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 18, left: 16, bottom: 18, right: 16))
        return card
    }

    private func greeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let period: String
        switch hour {
        case 5..<12: period = "Good morning"
        case 12..<17: period = "Good afternoon"
        case 17..<22: period = "Good evening"
        default: period = "Welcome back"
        }
        return period
    }

    // MARK: - Quick add routing

    private func ensureVehicleThen(_ action: (XTTVehicle) -> Void) {
        guard let vehicle = XTTDataStore.shared.vehicles.first else {
            let alert = UIAlertController(
                title: "Add a Vehicle First",
                message: "You need at least one vehicle before adding records.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Add Vehicle", style: .default) { _ in
                self.present(XTTNavigationController(rootViewController: XTTVehicleEditViewController(vehicle: nil)),
                             animated: true)
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
            return
        }
        action(vehicle)
    }

    @objc private func addTrip() {
        XTTHaptics.tap()
        XTTAuthGate.require("Adding a trip", from: self) { [weak self] in
            self?.ensureVehicleThen { vehicle in
                let editor = XTTTripEditViewController(trip: nil, defaultVehicleID: vehicle.id)
                self?.present(XTTNavigationController(rootViewController: editor), animated: true)
            }
        }
    }

    @objc private func addFuel() {
        XTTHaptics.tap()
        XTTAuthGate.require("Adding a fuel entry", from: self) { [weak self] in
            self?.ensureVehicleThen { vehicle in
                let editor = XTTFuelEditViewController(entry: nil, defaultVehicleID: vehicle.id)
                self?.present(XTTNavigationController(rootViewController: editor), animated: true)
            }
        }
    }

    @objc private func addMaintenance() {
        XTTHaptics.tap()
        XTTAuthGate.require("Adding a service record", from: self) { [weak self] in
            self?.ensureVehicleThen { vehicle in
                let editor = XTTMaintenanceEditViewController(item: nil, defaultVehicleID: vehicle.id)
                self?.present(XTTNavigationController(rootViewController: editor), animated: true)
            }
        }
    }
}
