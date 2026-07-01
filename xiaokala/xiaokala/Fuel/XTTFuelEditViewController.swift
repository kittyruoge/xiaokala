//
//  XTTFuelEditViewController.swift
//  xiaokala — X Drive Log
//
//  Add / edit a fuel fill-up.
//

import UIKit

final class XTTFuelEditViewController: UIViewController {

    private let existing: XTTFuelEntry?
    private var vehicleID: UUID
    private var date: Date

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let vehicleRow = XTTDisclosureRow(title: "Vehicle")
    private let dateRow = XTTDisclosureRow(title: "Date")
    private let amountRow = XTTFormRow(title: "Total Cost", placeholder: "e.g. 55.00", keyboard: .decimalPad)
    private let litersRow = XTTFormRow(title: "Litres (optional)", placeholder: "e.g. 42.0", keyboard: .decimalPad)
    private let odoRow = XTTFormRow(title: "Odometer (km)", placeholder: "e.g. 25000", keyboard: .decimalPad)
    private let stationRow = XTTFormRow(title: "Station (optional)", placeholder: "e.g. Shell")
    private let fullRow = XTTSegmentedRow(title: "Fill Level", items: ["Full Tank", "Partial"])

    private let pricePreview = UILabel()

    init(entry: XTTFuelEntry?, defaultVehicleID: UUID) {
        self.existing = entry
        self.vehicleID = entry?.vehicleID ?? defaultVehicleID
        self.date = entry?.date ?? Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = existing == nil ? "New Fuel Entry" : "Edit Fuel Entry"
        setupNav()
        buildUI()
        populate()
        updatePricePreview()
    }

    private func setupNav() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Save", style: .done, target: self, action: #selector(save))
        navigationItem.rightBarButtonItem?.tintColor = XTTTheme.accent
    }

    private func buildUI() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.keyboardDismissMode = .interactive
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        vehicleRow.addTarget(self, action: #selector(tapVehicle), for: .touchUpInside)
        dateRow.addTarget(self, action: #selector(tapDate), for: .touchUpInside)
        amountRow.textField.addTarget(self, action: #selector(updatePricePreview), for: .editingChanged)
        litersRow.textField.addTarget(self, action: #selector(updatePricePreview), for: .editingChanged)

        pricePreview.font = XTTTheme.fontCaption()
        pricePreview.textColor = XTTTheme.amber
        pricePreview.textAlignment = .right

        [vehicleRow, dateRow, amountRow, litersRow, pricePreview, odoRow, stationRow, fullRow].forEach {
            stack.addArrangedSubview($0)
        }
        stack.setCustomSpacing(6, after: litersRow)

        if existing != nil {
            let deleteButton = XTTPrimaryButton(title: "Delete Entry", fill: XTTTheme.danger)
            deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
            stack.setCustomSpacing(30, after: fullRow)
            stack.addArrangedSubview(deleteButton)
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -40)
        ])
    }

    private func populate() {
        updateVehicleLabel()
        updateDateLabel()
        guard let e = existing else { return }
        amountRow.value = "\(e.amount)"
        litersRow.value = e.liters > 0 ? "\(e.liters)" : ""
        odoRow.value = "\(e.odometer)"
        stationRow.value = e.station
        fullRow.segmented.selectedSegmentIndex = e.isFull ? 0 : 1
    }

    private func updateVehicleLabel() {
        vehicleRow.setValue(XTTDataStore.shared.vehicle(withID: vehicleID)?.name ?? "Select")
    }

    private func updateDateLabel() {
        dateRow.setValue(XTTFormat.date(date))
    }

    @objc private func updatePricePreview() {
        let amount = amountRow.doubleValue
        let liters = litersRow.doubleValue
        if amount > 0, liters > 0 {
            pricePreview.text = "≈ \(XTTFormat.pricePerLiter(amount / liters))"
        } else {
            pricePreview.text = ""
        }
    }

    // MARK: - Actions

    @objc private func tapVehicle() {
        XTTVehiclePicker.present(from: self, current: vehicleID) { [weak self] vehicle in
            self?.vehicleID = vehicle.id
            self?.updateVehicleLabel()
        }
    }

    @objc private func tapDate() {
        view.endEditing(true)
        let picker = XTTDatePickerViewController(date: date) { [weak self] newDate in
            self?.date = newDate
            self?.updateDateLabel()
        }
        present(picker, animated: true)
    }

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func save() {
        view.endEditing(true)
        guard amountRow.doubleValue > 0 else {
            presentValidation("Please enter the total cost.")
            return
        }

        if var e = existing {
            e.vehicleID = vehicleID
            e.amount = amountRow.doubleValue
            e.liters = litersRow.doubleValue
            e.odometer = odoRow.doubleValue
            e.station = stationRow.value
            e.isFull = fullRow.segmented.selectedSegmentIndex == 0
            e.date = date
            XTTDataStore.shared.updateFuel(e)
        } else {
            let e = XTTFuelEntry(vehicleID: vehicleID,
                                 amount: amountRow.doubleValue,
                                 liters: litersRow.doubleValue,
                                 odometer: odoRow.doubleValue,
                                 isFull: fullRow.segmented.selectedSegmentIndex == 0,
                                 station: stationRow.value,
                                 date: date)
            XTTDataStore.shared.addFuel(e)
        }
        XTTHaptics.success()
        dismiss(animated: true)
    }

    @objc private func tapDelete() {
        guard let e = existing else { return }
        let alert = UIAlertController(title: "Delete Fuel Entry?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteFuel(e)
            XTTHaptics.success()
            self.dismiss(animated: true)
        })
        present(alert, animated: true)
    }

    private func presentValidation(_ message: String) {
        let alert = UIAlertController(title: "Missing Info", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
