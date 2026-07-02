//
//  XTTTheme.swift
//  xiaokala — X Drive Log
//
//  Central dark automotive design system.
//

import UIKit

/// Central palette, typography and metrics for the X Drive Log dark automotive UI.
enum XTTTheme {

    // MARK: - Core palette

    /// Near-black app background.
    static let background = UIColor(red: 0.04, green: 0.05, blue: 0.07, alpha: 1.0)
    /// Slightly lifted surface used for grouped sections.
    static let surface = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0)
    /// Card fill.
    static let card = UIColor(red: 0.11, green: 0.12, blue: 0.16, alpha: 1.0)
    /// Elevated card (pressed / highlighted).
    static let cardElevated = UIColor(red: 0.15, green: 0.16, blue: 0.21, alpha: 1.0)
    /// Hairline separators / strokes.
    static let stroke = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)

    // MARK: - Accents

    /// Primary electric blue accent.
    static let accent = UIColor(red: 0.20, green: 0.55, blue: 1.0, alpha: 1.0)
    /// Secondary amber accent (fuel / warnings).
    static let amber = UIColor(red: 1.0, green: 0.60, blue: 0.15, alpha: 1.0)
    /// Positive / success green.
    static let green = UIColor(red: 0.25, green: 0.82, blue: 0.52, alpha: 1.0)
    /// Danger / destructive red.
    static let danger = UIColor(red: 1.0, green: 0.35, blue: 0.38, alpha: 1.0)
    /// Muted purple used for maintenance.
    static let purple = UIColor(red: 0.60, green: 0.45, blue: 1.0, alpha: 1.0)

    // MARK: - Text

    static let textPrimary = UIColor(red: 0.96, green: 0.97, blue: 0.99, alpha: 1.0)
    static let textSecondary = UIColor(red: 0.64, green: 0.68, blue: 0.76, alpha: 1.0)
    static let textTertiary = UIColor(red: 0.42, green: 0.46, blue: 0.54, alpha: 1.0)

    // MARK: - Metrics

    static let cornerRadius: CGFloat = 18
    static let cardCornerRadius: CGFloat = 22
    static let spacing: CGFloat = 16

    // MARK: - Typography

    static func fontHero() -> UIFont {
        roundedIfPossible(size: 34, weight: .heavy)
    }

    static func fontTitle() -> UIFont {
        roundedIfPossible(size: 22, weight: .bold)
    }

    static func fontHeadline() -> UIFont {
        roundedIfPossible(size: 17, weight: .semibold)
    }

    static func fontBody() -> UIFont {
        UIFont.systemFont(ofSize: 15, weight: .regular)
    }

    static func fontCaption() -> UIFont {
        UIFont.systemFont(ofSize: 13, weight: .medium)
    }

    static func fontMono(_ size: CGFloat, weight: UIFont.Weight = .semibold) -> UIFont {
        UIFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
    }

    private static func roundedIfPossible(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let system = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = system.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return system
    }

    // MARK: - Gradients

    /// Signature diagonal accent gradient colours.
    static func accentGradientColors() -> [CGColor] {
        [accent.cgColor, UIColor(red: 0.35, green: 0.30, blue: 0.95, alpha: 1.0).cgColor]
    }

    static func amberGradientColors() -> [CGColor] {
        [amber.cgColor, UIColor(red: 1.0, green: 0.38, blue: 0.28, alpha: 1.0).cgColor]
    }
}
