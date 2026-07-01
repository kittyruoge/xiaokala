//
//  XTTPickerSupport.swift
//  xiaokala — X Drive Log
//
//  Helpers for presenting vehicle and date pickers from editor screens.
//

import UIKit

/// Presents a simple action-sheet vehicle picker.
enum XTTVehiclePicker {

    static func present(from vc: UIViewController,
                        current: UUID?,
                        onSelect: @escaping (XTTVehicle) -> Void) {
        let vehicles = XTTDataStore.shared.vehicles
        guard !vehicles.isEmpty else { return }

        let sheet = UIAlertController(title: "Select Vehicle", message: nil, preferredStyle: .actionSheet)
        for vehicle in vehicles {
            let mark = vehicle.id == current ? "✓ " : ""
            sheet.addAction(UIAlertAction(title: "\(mark)\(vehicle.name)", style: .default) { _ in
                onSelect(vehicle)
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = vc.view
            pop.sourceRect = CGRect(x: vc.view.bounds.midX, y: vc.view.bounds.midY, width: 0, height: 0)
            pop.permittedArrowDirections = []
        }
        vc.present(sheet, animated: true)
    }
}

/// A bottom-sheet style date picker presented modally.
final class XTTDatePickerViewController: UIViewController {

    private let picker = UIDatePicker()
    private var onDone: ((Date) -> Void)?

    init(date: Date, onDone: @escaping (Date) -> Void) {
        self.onDone = onDone
        super.init(nibName: nil, bundle: nil)
        picker.date = date
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)

        let container = UIView()
        container.backgroundColor = XTTTheme.surface
        container.layer.cornerRadius = 24
        container.layer.cornerCurve = .continuous
        container.translatesAutoresizingMaskIntoConstraints = false

        picker.datePickerMode = .date
        picker.preferredDatePickerStyle = .inline
        picker.tintColor = XTTTheme.accent
        picker.overrideUserInterfaceStyle = .dark
        picker.maximumDate = Date()
        picker.translatesAutoresizingMaskIntoConstraints = false

        let doneButton = XTTPrimaryButton(title: "Done")
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [picker, doneButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(stack)
        view.addSubview(container)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapBackground(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func tapBackground(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        for subview in view.subviews where subview.frame.contains(location) {
            return
        }
        dismiss(animated: true)
    }

    @objc private func done() {
        onDone?(picker.date)
        dismiss(animated: true)
    }
}
