//
//  XTTMaintenanceEditViewController.swift
//  xiaokala — X Drive Log
//
//  Add / edit a maintenance record.
//

import UIKit

final class XTTMaintenanceEditViewController: UIViewController {

    private let existing: XTTMaintenance?
    private var vehicleID: UUID
    private var date: Date

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let vehicleRow = XTTDisclosureRow(title: "Vehicle")
    private let dateRow = XTTDisclosureRow(title: "Date")
    private let titleRow = XTTFormRow(title: "Title", placeholder: "e.g. Oil change")
    private let kindRow = XTTSegmentedRow(title: "Type",
                                          items: XTTMaintenanceKind.allCases.map { $0.rawValue })
    private let costRow = XTTFormRow(title: "Cost", placeholder: "e.g. 89.00", keyboard: .decimalPad)
    private let odoRow = XTTFormRow(title: "Odometer (km)", placeholder: "e.g. 25000", keyboard: .decimalPad)
    private let noteRow = XTTFormRow(title: "Note (optional)", placeholder: "Add a note")

    init(item: XTTMaintenance?, defaultVehicleID: UUID) {
        self.existing = item
        self.vehicleID = item?.vehicleID ?? defaultVehicleID
        self.date = item?.date ?? Date()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = existing == nil ? "New Service" : "Edit Service"
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

        [vehicleRow, dateRow, titleRow, kindRow, costRow, odoRow, noteRow].forEach {
            stack.addArrangedSubview($0)
        }

        if existing != nil {
            let deleteButton = XTTPrimaryButton(title: "Delete Record", fill: XTTTheme.danger)
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
        guard let m = existing else { return }
        titleRow.value = m.title
        costRow.value = "\(m.cost)"
        odoRow.value = "\(m.odometer)"
        noteRow.value = m.note
        if let idx = XTTMaintenanceKind.allCases.firstIndex(of: m.kind) {
            kindRow.segmented.selectedSegmentIndex = idx
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
        let recordTitle = titleRow.value.trimmingCharacters(in: .whitespaces)
        guard !recordTitle.isEmpty else {
            presentValidation("Please enter a title for this record.")
            return
        }

        let kind = XTTMaintenanceKind.allCases[kindRow.segmented.selectedSegmentIndex]

        if var m = existing {
            m.vehicleID = vehicleID
            m.title = recordTitle
            m.kind = kind
            m.cost = costRow.doubleValue
            m.odometer = odoRow.doubleValue
            m.note = noteRow.value
            m.date = date
            XTTDataStore.shared.updateMaintenance(m)
        } else {
            let m = XTTMaintenance(vehicleID: vehicleID,
                                   title: recordTitle,
                                   kind: kind,
                                   cost: costRow.doubleValue,
                                   odometer: odoRow.doubleValue,
                                   note: noteRow.value,
                                   date: date)
            XTTDataStore.shared.addMaintenance(m)
        }
        XTTHaptics.success()
        dismiss(animated: true)
    }

    @objc private func tapDelete() {
        guard let m = existing else { return }
        let alert = UIAlertController(title: "Delete Record?",
                                      message: "This cannot be undone.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteMaintenance(m)
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
