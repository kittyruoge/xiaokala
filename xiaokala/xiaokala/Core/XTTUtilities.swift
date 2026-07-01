//
//  XTTUtilities.swift
//  xiaokala — X Drive Log
//
//  Shared extensions and formatting helpers.
//

import UIKit

// MARK: - Layout helpers

extension UIView {

    /// Pins the receiver to the edges of `view` with optional insets.
    func xtt_pinEdges(to view: UIView, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: view.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -insets.bottom)
        ])
    }

    /// Pins the receiver to the edges of a layout guide with optional insets.
    func xtt_pinEdges(to guide: UILayoutGuide, insets: UIEdgeInsets = .zero) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: insets.left),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -insets.right),
            topAnchor.constraint(equalTo: guide.topAnchor, constant: insets.top),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -insets.bottom)
        ])
    }

    func xtt_addSubviews(_ subviews: UIView...) {
        subviews.forEach { addSubview($0) }
    }

    /// Applies a soft dark drop shadow used across cards.
    func xtt_applyCardShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 14
        layer.shadowOffset = CGSize(width: 0, height: 8)
    }
}

// MARK: - Colour helpers

extension UIColor {
    /// Returns the colour blended with black to darken it by `amount` (0...1).
    func xtt_darkened(by amount: CGFloat) -> UIColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        let f = max(0, 1 - amount)
        return UIColor(red: r * f, green: g * f, blue: b * f, alpha: a)
    }
}

// MARK: - Formatting

/// Centralised value formatting so units are consistent across the app.
enum XTTFormat {

    static let currencySymbol = "$"

    static func currency(_ value: Double) -> String {
        String(format: "%@%.2f", currencySymbol, value)
    }

    static func currencyCompact(_ value: Double) -> String {
        if abs(value) >= 1000 {
            return String(format: "%@%.1fk", currencySymbol, value / 1000.0)
        }
        return String(format: "%@%.0f", currencySymbol, value)
    }

    static func distance(_ km: Double) -> String {
        String(format: "%.1f km", km)
    }

    static func distanceInt(_ km: Double) -> String {
        String(format: "%.0f km", km)
    }

    static func volume(_ liters: Double) -> String {
        String(format: "%.2f L", liters)
    }

    static func pricePerLiter(_ value: Double) -> String {
        String(format: "%@%.3f/L", currencySymbol, value)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    private static let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d"
        return f
    }()

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    static func date(_ date: Date) -> String { dateFormatter.string(from: date) }
    static func shortDate(_ date: Date) -> String { shortDateFormatter.string(from: date) }
    static func month(_ date: Date) -> String { monthFormatter.string(from: date) }
}

// MARK: - Haptics

enum XTTHaptics {
    static func tap() {
        let g = UIImpactFeedbackGenerator(style: .light)
        g.impactOccurred()
    }

    static func success() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.success)
    }

    static func warning() {
        let g = UINotificationFeedbackGenerator()
        g.notificationOccurred(.warning)
    }
}
