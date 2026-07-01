//
//  XTTVehicleEditViewController.swift
//  xiaokala — X Drive Log
//
//  Add / edit a vehicle.
//

import UIKit

final class XTTVehicleEditViewController: UIViewController {

    private let existing: XTTVehicle?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let nameRow = XTTFormRow(title: "Name", placeholder: "e.g. My Daily")
    private let makeRow = XTTFormRow(title: "Make", placeholder: "e.g. Toyota")
    private let modelRow = XTTFormRow(title: "Model", placeholder: "e.g. Corolla")
    private let yearRow = XTTFormRow(title: "Year", placeholder: "e.g. 2022", keyboard: .numberPad)
    private let plateRow = XTTFormRow(title: "Plate", placeholder: "e.g. ABC-1234")
    private let odoRow = XTTFormRow(title: "Odometer (km)", placeholder: "e.g. 25000", keyboard: .decimalPad)
    private let fuelRow = XTTSegmentedRow(title: "Fuel Type",
                                          items: XTTFuelType.allCases.map { $0.rawValue })

    private let colorSwatches = UIStackView()
    private var selectedColorHex = "3399FF"
    private let palette = ["3399FF", "FF9933", "40D186", "9973FF", "FF5A61", "FFD23F"]

    init(vehicle: XTTVehicle?) {
        self.existing = vehicle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = XTTTheme.background
        title = existing == nil ? "New Vehicle" : "Edit Vehicle"
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

        yearRow.textField.text = ""
        [nameRow, makeRow, modelRow, yearRow, plateRow, odoRow, fuelRow].forEach {
            stack.addArrangedSubview($0)
        }

        // Colour tag picker.
        let colorHeader = XTTSectionHeader("Tag Colour")
        stack.addArrangedSubview(colorHeader)

        colorSwatches.axis = .horizontal
        colorSwatches.spacing = 12
        colorSwatches.distribution = .fillEqually
        for hex in palette {
            colorSwatches.addArrangedSubview(makeSwatch(hex: hex))
        }
        stack.addArrangedSubview(colorSwatches)

        if existing != nil {
            let deleteButton = XTTPrimaryButton(title: "Delete Vehicle", fill: XTTTheme.danger)
            deleteButton.addTarget(self, action: #selector(tapDelete), for: .touchUpInside)
            stack.setCustomSpacing(30, after: colorSwatches)
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

    private func makeSwatch(hex: String) -> UIView {
        let button = UIButton(type: .custom)
        button.backgroundColor = UIColor(xtt_hex: hex) ?? XTTTheme.accent
        button.layer.cornerRadius = 20
        button.layer.cornerCurve = .continuous
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        button.accessibilityLabel = hex
        button.addAction(UIAction { [weak self] _ in
            self?.selectColor(hex)
        }, for: .touchUpInside)
        button.tag = palette.firstIndex(of: hex) ?? 0
        return button
    }

    private func selectColor(_ hex: String) {
        selectedColorHex = hex
        XTTHaptics.tap()
        for (index, view) in colorSwatches.arrangedSubviews.enumerated() {
            let isSelected = palette[index] == hex
            view.layer.borderWidth = isSelected ? 3 : 0
            view.layer.borderColor = XTTTheme.textPrimary.cgColor
        }
    }

    private func populate() {
        guard let v = existing else {
            selectColor(selectedColorHex)
            return
        }
        nameRow.value = v.name
        makeRow.value = v.make
        modelRow.value = v.model
        yearRow.value = v.year > 0 ? "\(v.year)" : ""
        plateRow.value = v.plate
        odoRow.value = "\(v.odometer)"
        if let idx = XTTFuelType.allCases.firstIndex(of: v.fuelType) {
            fuelRow.segmented.selectedSegmentIndex = idx
        }
        selectedColorHex = v.colorHex
        selectColor(v.colorHex)
    }

    // MARK: - Actions

    @objc private func cancel() { dismiss(animated: true) }

    @objc private func save() {
        view.endEditing(true)
        let name = nameRow.value.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else {
            presentValidation("Please enter a vehicle name.")
            return
        }

        let fuelType = XTTFuelType.allCases[fuelRow.segmented.selectedSegmentIndex]

        if var v = existing {
            v.name = name
            v.make = makeRow.value
            v.model = modelRow.value
            v.year = yearRow.intValue
            v.plate = plateRow.value
            v.odometer = odoRow.doubleValue
            v.fuelType = fuelType
            v.colorHex = selectedColorHex
            XTTDataStore.shared.updateVehicle(v)
        } else {
            let v = XTTVehicle(name: name,
                               make: makeRow.value,
                               model: modelRow.value,
                               year: yearRow.intValue,
                               plate: plateRow.value,
                               fuelType: fuelType,
                               odometer: odoRow.doubleValue,
                               colorHex: selectedColorHex)
            XTTDataStore.shared.addVehicle(v)
        }
        XTTHaptics.success()
        dismiss(animated: true)
    }

    @objc private func tapDelete() {
        guard let v = existing else { return }
        let alert = UIAlertController(
            title: "Delete \(v.name)?",
            message: "This also removes all related records. This cannot be undone.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            XTTDataStore.shared.deleteVehicle(v)
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
