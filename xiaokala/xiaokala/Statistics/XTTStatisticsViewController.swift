//
//  XTTStatisticsViewController.swift
//  xiaokala — X Drive Log
//
//  Cost summary and usage trends with lightweight charts.
//

import UIKit

final class XTTStatisticsViewController: UIViewController {

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()

    // Cost ring + legend
    private let ringChart = XTTRingChartView()
    private let legendStack = UIStackView()
    private let monthLabel = UILabel()
    private let totalLabel = UILabel()

    // Trend charts
    private let distanceChart = XTTBarChartView()
    private let costChart = XTTLineChartView()

    private let emptyState = XTTEmptyStateView(
        symbol: "chart.line.uptrend.xyaxis",
        title: "No Data Yet",
        message: "Add trips, fuel and service records to see your cost breakdown and trends.")

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        navigationItem.largeTitleDisplayMode = .always
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

        buildCostCard()
        buildDistanceCard()
        buildCostTrendCard()

        emptyState.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyState)
        emptyState.xtt_pinEdges(to: view.safeAreaLayoutGuide)
    }

    private func buildCostCard() {
        contentStack.addArrangedSubview(XTTSectionHeader("This Month's Cost"))

        let card = XTTCardView()
        card.translatesAutoresizingMaskIntoConstraints = false

        ringChart.translatesAutoresizingMaskIntoConstraints = false

        monthLabel.font = XTTTheme.fontCaption()
        monthLabel.textColor = XTTTheme.textSecondary
        monthLabel.textAlignment = .center

        totalLabel.font = XTTTheme.fontMono(24, weight: .bold)
        totalLabel.textColor = XTTTheme.textPrimary
        totalLabel.textAlignment = .center

        let centerStack = UIStackView(arrangedSubviews: [totalLabel, monthLabel])
        centerStack.axis = .vertical
        centerStack.spacing = 2
        centerStack.translatesAutoresizingMaskIntoConstraints = false

        legendStack.axis = .vertical
        legendStack.spacing = 10
        legendStack.translatesAutoresizingMaskIntoConstraints = false

        card.xtt_addSubviews(ringChart, centerStack, legendStack)

        NSLayoutConstraint.activate([
            ringChart.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            ringChart.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            ringChart.widthAnchor.constraint(equalToConstant: 130),
            ringChart.heightAnchor.constraint(equalToConstant: 130),
            ringChart.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -20),

            centerStack.centerXAnchor.constraint(equalTo: ringChart.centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: ringChart.centerYAnchor),
            centerStack.widthAnchor.constraint(lessThanOrEqualTo: ringChart.widthAnchor, constant: -30),

            legendStack.leadingAnchor.constraint(equalTo: ringChart.trailingAnchor, constant: 20),
            legendStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            legendStack.centerYAnchor.constraint(equalTo: ringChart.centerYAnchor)
        ])

        contentStack.addArrangedSubview(card)
    }

    private func buildDistanceCard() {
        contentStack.addArrangedSubview(XTTSectionHeader("Distance · Last 6 Months"))

        let card = XTTCardView()
        distanceChart.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(distanceChart)
        distanceChart.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 20, left: 20, bottom: 16, right: 20))
        distanceChart.heightAnchor.constraint(equalToConstant: 150).isActive = true
        contentStack.addArrangedSubview(card)
    }

    private func buildCostTrendCard() {
        contentStack.addArrangedSubview(XTTSectionHeader("Cost Trend · Last 6 Months"))

        let card = XTTCardView()
        costChart.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(costChart)
        costChart.xtt_pinEdges(to: card, insets: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20))
        costChart.heightAnchor.constraint(equalToConstant: 130).isActive = true
        contentStack.addArrangedSubview(card)
    }

    // MARK: - Data

    @objc private func refresh() {
        let store = XTTDataStore.shared
        let hasData = !store.trips.isEmpty || !store.fuelEntries.isEmpty || !store.maintenance.isEmpty
        emptyState.isHidden = hasData
        scrollView.isHidden = !hasData
        guard hasData else { return }

        refreshCostRing()
        refreshDistanceChart()
        refreshCostTrend()
    }

    private func refreshCostRing() {
        let store = XTTDataStore.shared
        let calendar = Calendar.current
        let now = Date()

        let fuel = store.fuelEntries
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
        let maintenance = store.maintenance
            .filter { calendar.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.cost }
        // "Other" is reserved for future categories; kept for a complete breakdown.
        let other = 0.0
        let total = fuel + maintenance + other

        monthLabel.text = XTTFormat.month(now)
        totalLabel.text = XTTFormat.currencyCompact(total)

        ringChart.configure(slices: [
            .init(value: fuel, color: XTTTheme.amber),
            .init(value: maintenance, color: XTTTheme.purple),
            .init(value: other, color: XTTTheme.accent)
        ])

        rebuildLegend(fuel: fuel, maintenance: maintenance, other: other)
    }

    private func rebuildLegend(fuel: Double, maintenance: Double, other: Double) {
        legendStack.arrangedSubviews.forEach {
            legendStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        let rows: [(String, Double, UIColor)] = [
            ("Fuel", fuel, XTTTheme.amber),
            ("Maintenance", maintenance, XTTTheme.purple),
            ("Other", other, XTTTheme.accent)
        ]
        for (name, value, color) in rows {
            legendStack.addArrangedSubview(makeLegendRow(name: name, value: value, color: color))
        }
    }

    private func makeLegendRow(name: String, value: Double, color: UIColor) -> UIView {
        let dot = UIView()
        dot.backgroundColor = color
        dot.layer.cornerRadius = 5
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 10).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 10).isActive = true

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = XTTTheme.fontCaption()
        nameLabel.textColor = XTTTheme.textSecondary

        let valueLabel = UILabel()
        valueLabel.text = XTTFormat.currency(value)
        valueLabel.font = XTTTheme.fontMono(13, weight: .semibold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [dot, nameLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    /// Returns the start dates of the last 6 months, oldest first.
    private func lastSixMonths() -> [Date] {
        let calendar = Calendar.current
        let now = Date()
        var months: [Date] = []
        for offset in stride(from: 5, through: 0, by: -1) {
            if let date = calendar.date(byAdding: .month, value: -offset, to: now) {
                let comps = calendar.dateComponents([.year, .month], from: date)
                if let start = calendar.date(from: comps) {
                    months.append(start)
                }
            }
        }
        return months
    }

    private func monthAbbrev(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    private func refreshDistanceChart() {
        let store = XTTDataStore.shared
        let calendar = Calendar.current
        let months = lastSixMonths()

        let items: [XTTBarChartView.Item] = months.map { monthStart in
            let distance = store.trips
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.distance }
            return .init(label: monthAbbrev(monthStart), value: distance)
        }
        distanceChart.configure(items: items, color: XTTTheme.accent)
    }

    private func refreshCostTrend() {
        let store = XTTDataStore.shared
        let calendar = Calendar.current
        let months = lastSixMonths()

        let values: [Double] = months.map { monthStart in
            let fuel = store.fuelEntries
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
            let maint = store.maintenance
                .filter { calendar.isDate($0.date, equalTo: monthStart, toGranularity: .month) }
                .reduce(0) { $0 + $1.cost }
            return fuel + maint
        }
        costChart.configure(values: values, color: XTTTheme.amber)
    }
}
