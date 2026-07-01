//
//  XTTFormControls.swift
//  xiaokala — X Drive Log
//
//  Reusable labelled form rows for the editor screens.
//

import UIKit

/// Labelled text input row used in editor forms.
final class XTTFormRow: UIView {

    let textField: UITextField

    init(title: String, placeholder: String, keyboard: UIKeyboardType = .default) {
        let field = XTTTextFieldPlain(placeholder: placeholder)
        field.keyboardType = keyboard
        self.textField = field
        super.init(frame: .zero)

        let label = UILabel()
        label.text = title.uppercased()
        label.font = XTTTheme.fontCaption()
        label.textColor = XTTTheme.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false

        field.translatesAutoresizingMaskIntoConstraints = false

        xtt_addSubviews(label, field)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -4),

            field.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            field.leadingAnchor.constraint(equalTo: leadingAnchor),
            field.trailingAnchor.constraint(equalTo: trailingAnchor),
            field.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    var value: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    var doubleValue: Double {
        Double((textField.text ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    var intValue: Int {
        Int(textField.text ?? "") ?? 0
    }
}

/// Plain padded text field (no leading icon) for form rows.
final class XTTTextFieldPlain: UITextField {

    private let padding = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

    init(placeholder: String) {
        super.init(frame: .zero)
        backgroundColor = XTTTheme.surface
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor
        textColor = XTTTheme.textPrimary
        tintColor = XTTTheme.accent
        font = XTTTheme.fontBody()
        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: XTTTheme.textTertiary])
        heightAnchor.constraint(equalToConstant: 52).isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: padding) }
}

/// Horizontal segmented selector styled for the dark theme.
final class XTTSegmentedRow: UIView {

    let segmented: UISegmentedControl

    init(title: String, items: [String]) {
        segmented = UISegmentedControl(items: items)
        super.init(frame: .zero)

        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = XTTTheme.accent
        segmented.backgroundColor = XTTTheme.surface
        segmented.setTitleTextAttributes([.foregroundColor: XTTTheme.textSecondary], for: .normal)
        segmented.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        segmented.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title.uppercased()
        label.font = XTTTheme.fontCaption()
        label.textColor = XTTTheme.textTertiary
        label.translatesAutoresizingMaskIntoConstraints = false

        xtt_addSubviews(label, segmented)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),

            segmented.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: leadingAnchor),
            segmented.trailingAnchor.constraint(equalTo: trailingAnchor),
            segmented.heightAnchor.constraint(equalToConstant: 44),
            segmented.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

/// A tappable row that presents a value and chevron, used for pickers/dates.
final class XTTDisclosureRow: UIControl {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = XTTTheme.surface
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor

        titleLabel.text = title
        titleLabel.font = XTTTheme.fontBody()
        titleLabel.textColor = XTTTheme.textSecondary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = XTTTheme.fontHeadline()
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = XTTTheme.textTertiary
        chevron.translatesAutoresizingMaskIntoConstraints = false

        xtt_addSubviews(titleLabel, valueLabel, chevron)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 52),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            chevron.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: centerYAnchor),

            valueLabel.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8),
            valueLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ text: String) { valueLabel.text = text }
}
