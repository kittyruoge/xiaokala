//
//  XTTStatViews.swift
//  xiaokala — X Drive Log
//
//  Dashboard stat tiles and lightweight charts drawn with Core Graphics.
//

import UIKit

// MARK: - Stat tile

/// Compact metric tile: icon, value and caption on a card.
final class XTTStatTile: UIView {

    private let iconView = UIImageView()
    private let valueLabel = UILabel()
    private let captionLabel = UILabel()
    private let iconBackground = UIView()

    init(symbol: String, tint: UIColor, caption: String) {
        super.init(frame: .zero)

        backgroundColor = XTTTheme.card
        layer.cornerRadius = XTTTheme.cardCornerRadius
        layer.cornerCurve = .continuous
        layer.borderWidth = 1
        layer.borderColor = XTTTheme.stroke.cgColor

        iconBackground.backgroundColor = tint.withAlphaComponent(0.18)
        iconBackground.layer.cornerRadius = 12
        iconBackground.translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: symbol)
        iconView.tintColor = tint
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        valueLabel.font = XTTTheme.fontMono(24, weight: .bold)
        valueLabel.textColor = XTTTheme.textPrimary
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.6
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        captionLabel.text = caption.uppercased()
        captionLabel.font = XTTTheme.fontCaption()
        captionLabel.textColor = XTTTheme.textTertiary
        captionLabel.translatesAutoresizingMaskIntoConstraints = false

        iconBackground.addSubview(iconView)
        xtt_addSubviews(iconBackground, valueLabel, captionLabel)

        NSLayoutConstraint.activate([
            iconBackground.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconBackground.widthAnchor.constraint(equalToConstant: 40),
            iconBackground.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 22),
            iconView.heightAnchor.constraint(equalToConstant: 22),

            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            valueLabel.topAnchor.constraint(equalTo: iconBackground.bottomAnchor, constant: 12),

            captionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            captionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            captionLabel.topAnchor.constraint(equalTo: valueLabel.bottomAnchor, constant: 2),
            captionLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setValue(_ value: String) {
        valueLabel.text = value
    }
}

// MARK: - Bar chart

/// Simple animated vertical bar chart drawn with CG. Values are non-negative.
final class XTTBarChartView: UIView {

    struct Item {
        let label: String
        let value: Double
    }

    private var items: [Item] = []
    private var barColor: UIColor = XTTTheme.accent

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(items: [Item], color: UIColor) {
        self.items = items
        self.barColor = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), !items.isEmpty else { return }

        let labelHeight: CGFloat = 20
        let chartRect = CGRect(x: 0, y: 0, width: rect.width, height: rect.height - labelHeight)
        let maxValue = max(items.map { $0.value }.max() ?? 1, 1)

        let count = CGFloat(items.count)
        let spacing: CGFloat = 10
        let totalSpacing = spacing * (count - 1)
        let barWidth = max((chartRect.width - totalSpacing) / count, 1)

        for (index, item) in items.enumerated() {
            let x = CGFloat(index) * (barWidth + spacing)
            let ratio = CGFloat(item.value / maxValue)
            let barHeight = max(chartRect.height * ratio, item.value > 0 ? 4 : 2)
            let y = chartRect.height - barHeight

            let barRect = CGRect(x: x, y: y, width: barWidth, height: barHeight)
            let path = UIBezierPath(roundedRect: barRect, cornerRadius: min(6, barWidth / 2))

            let fill = item.value > 0 ? barColor : XTTTheme.stroke
            ctx.setFillColor(fill.cgColor)
            path.fill()

            // Label under each bar.
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .medium),
                .foregroundColor: XTTTheme.textTertiary
            ]
            let labelSize = (item.label as NSString).size(withAttributes: attrs)
            let labelX = x + (barWidth - labelSize.width) / 2
            (item.label as NSString).draw(
                at: CGPoint(x: labelX, y: rect.height - labelHeight + 4),
                withAttributes: attrs
            )
        }
    }
}

// MARK: - Line chart

/// Smoothed line chart with a gradient area fill.
final class XTTLineChartView: UIView {

    private var values: [Double] = []
    private var lineColor: UIColor = XTTTheme.accent

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(values: [Double], color: UIColor) {
        self.values = values
        self.lineColor = color
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext(), values.count > 1 else {
            drawFlatLine(in: rect)
            return
        }

        let maxValue = max(values.max() ?? 1, 1)
        let minValue = min(values.min() ?? 0, 0)
        let range = max(maxValue - minValue, 1)
        let inset: CGFloat = 6
        let usableHeight = rect.height - inset * 2
        let stepX = rect.width / CGFloat(values.count - 1)

        func point(_ index: Int) -> CGPoint {
            let x = CGFloat(index) * stepX
            let ratio = CGFloat((values[index] - minValue) / range)
            let y = inset + usableHeight * (1 - ratio)
            return CGPoint(x: x, y: y)
        }

        let linePath = UIBezierPath()
        linePath.move(to: point(0))
        for i in 1..<values.count {
            linePath.addLine(to: point(i))
        }

        // Area fill.
        let areaPath = UIBezierPath(cgPath: linePath.cgPath)
        areaPath.addLine(to: CGPoint(x: rect.width, y: rect.height))
        areaPath.addLine(to: CGPoint(x: 0, y: rect.height))
        areaPath.close()

        ctx.saveGState()
        areaPath.addClip()
        let colors = [lineColor.withAlphaComponent(0.35).cgColor,
                      lineColor.withAlphaComponent(0.0).cgColor] as CFArray
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors,
                                     locations: [0, 1]) {
            ctx.drawLinearGradient(gradient,
                                   start: CGPoint(x: 0, y: 0),
                                   end: CGPoint(x: 0, y: rect.height),
                                   options: [])
        }
        ctx.restoreGState()

        lineColor.setStroke()
        linePath.lineWidth = 3
        linePath.lineJoinStyle = .round
        linePath.stroke()

        // End dot.
        let last = point(values.count - 1)
        let dot = UIBezierPath(arcCenter: last, radius: 4, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        lineColor.setFill()
        dot.fill()
    }

    private func drawFlatLine(in rect: CGRect) {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        XTTTheme.stroke.setStroke()
        path.lineWidth = 2
        path.stroke()
    }
}

// MARK: - Donut / ring chart

/// Category ring chart used by the cost summary.
final class XTTRingChartView: UIView {

    struct Slice {
        let value: Double
        let color: UIColor
    }

    private var slices: [Slice] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(slices: [Slice]) {
        self.slices = slices
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        let lineWidth: CGFloat = 18
        let radius = (min(rect.width, rect.height) - lineWidth) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let total = slices.reduce(0) { $0 + $1.value }

        // Track.
        let track = UIBezierPath(arcCenter: center, radius: radius,
                                 startAngle: 0, endAngle: .pi * 2, clockwise: true)
        XTTTheme.surface.setStroke()
        track.lineWidth = lineWidth
        track.stroke()

        guard total > 0 else { return }

        var startAngle = -CGFloat.pi / 2
        for slice in slices where slice.value > 0 {
            let sweep = CGFloat(slice.value / total) * .pi * 2
            let endAngle = startAngle + sweep
            let arc = UIBezierPath(arcCenter: center, radius: radius,
                                   startAngle: startAngle, endAngle: endAngle, clockwise: true)
            slice.color.setStroke()
            arc.lineWidth = lineWidth
            arc.lineCapStyle = .butt
            arc.stroke()
            startAngle = endAngle
        }
    }
}
