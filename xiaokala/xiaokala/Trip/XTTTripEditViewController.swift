//
//  XTTTripEditViewController.swift
//  xiaokala — X Drive Log
//
//  Add / edit a trip.
//

import UIKit

final class XTTTripEditViewController: UIViewController {

    private let existing: XTTTrip?
    private var vehicleID: UUID
    private var date: Date

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let vehicleRow = XTTDisclosureRow(title: "Vehicle")
    private let dateRow = XTTDisclosureRow(title: "Date")
    private let startRow = XTTFormRow(title: "Start", placeholder: "e.g. Home")
    private let endRow = XTTFormRow(title: "End", placeholder: "e.g. Office")
    private let distanceRow = XTTFormRow(title: "Distance (km)", placeholder: "e.g. 18.4", keyboard: .decimalPad)
    private let purposeRow = XTTSegmentedRow(title: "Purpose",
                                             items: XTTTripPurpose.allCases.map { $0.rawValue })
    private let noteRow = XTTFormRow(title: "Note (optional)", placeholder: "Add a note")

    init(trip: XTTTrip?, defaultVehicleID: UUID) {
        self.existing = trip
        self.vehicleID = trip?.vehicleID ?? defaultVehicleID
        self.date = trip?.date ?? Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = existing == nil ? "New Trip" : "Edit Trip"
        setupNav()
        buildUI()
        populate()
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

        [vehicleRow, dateRow, startRow, endRow, distanceRow, purposeRow, noteRow].forEach {
            stack.addArrangedSubview($0)
        }

        if existing != nil {
            let deleteButton = XTTPrimaryButton(title: "Delete Trip", fill: XTTTheme.danger)
            deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
            stack.setCustomSpacing(30, after: noteRow)
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
        guard let t = existing else { return }
        startRow.value = t.startPlace
        endRow.value = t.endPlace
        distanceRow.value = "\(t.distance)"
        noteRow.value = t.note
        if let idx = XTTTripPurpose.allCases.firstIndex(of: t.purpose) {
            purposeRow.segmented.selectedSegmentIndex = idx
        }
    }

    private func updateVehicleLabel() {
        vehicleRow.setValue(XTTDataStore.shared.vehicle(withID: vehicleID)?.name ?? "Select")
    }

    private func updateDateLabel() {
        dateRow.setValue(XTTFormat.date(date))
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
        let start = startRow.value.trimmingCharacters(in: .whitespaces)
        let end = endRow.value.trimmingCharacters(in: .whitespaces)
        guard !start.isEmpty, !end.isEmpty else {
            presentValidation("Please enter both a start and end location.")
            return
        }
        guard distanceRow.doubleValue > 0 else {
            presentValidation("Please enter a distance greater than zero.")
            return
        }

        let purpose = XTTTripPurpose.allCases[purposeRow.segmented.selectedSegmentIndex]

        if var t = existing {
            t.vehicleID = vehicleID
            t.startPlace = start
            t.endPlace = end
            t.distance = distanceRow.doubleValue
            t.purpose = purpose
            t.note = noteRow.value
            t.date = date
            XTTDataStore.shared.updateTrip(t)
        } else {
            let t = XTTTrip(vehicleID: vehicleID,
                            startPlace: start,
                            endPlace: end,
                            distance: distanceRow.doubleValue,
                            purpose: purpose,
                            note: noteRow.value,
                            date: date)
            XTTDataStore.shared.addTrip(t)
        }
        XTTHaptics.success()
        dismiss(animated: true)
    }

    @objc private func tapDelete() {
        guard let t = existing else { return }
        let alert = UIAlertController(title: "Delete Trip?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteTrip(t)
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
