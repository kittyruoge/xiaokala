//
//  ColorHelper.swift
//  xiaokala
//
//  UIColor 与十六进制颜色互转工具
//

import UIKit

/// 颜色处理工具
struct ColorHelper {

    /// 十六进制字符串转 UIColor，支持 "#RRGGBB" / "RRGGBB" / "#RRGGBBAA"
    static func color(fromHex hex: String) -> UIColor? {
        var str = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if str.hasPrefix("#") {
            str.removeFirst()
        }
        guard str.count == 6 || str.count == 8 else { return nil }

        var value: UInt64 = 0
        guard Scanner(string: str).scanHexInt64(&value) else { return nil }

        let r, g, b, a: CGFloat
        if str.count == 8 {
            r = CGFloat((value >> 24) & 0xFF) / 255.0
            g = CGFloat((value >> 16) & 0xFF) / 255.0
            b = CGFloat((value >> 8) & 0xFF) / 255.0
            a = CGFloat(value & 0xFF) / 255.0
        } else {
            r = CGFloat((value >> 16) & 0xFF) / 255.0
            g = CGFloat((value >> 8) & 0xFF) / 255.0
            b = CGFloat(value & 0xFF) / 255.0
            a = 1.0
        }
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    /// UIColor 转十六进制字符串 "#RRGGBB"
    static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }

    /// 生成随机颜色
    static func random() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0...1),
            green: CGFloat.random(in: 0...1),
            blue: CGFloat.random(in: 0...1),
            alpha: 1.0
        )
    }
}
