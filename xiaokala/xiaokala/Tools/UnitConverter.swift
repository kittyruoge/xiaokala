//
//  UnitConverter.swift
//  xiaokala
//
//  常用单位换算工具
//

import Foundation

/// 常用单位换算
struct UnitConverter {

    // MARK: - 温度

    static func celsiusToFahrenheit(_ c: Double) -> Double {
        return c * 9.0 / 5.0 + 32.0
    }

    static func fahrenheitToCelsius(_ f: Double) -> Double {
        return (f - 32.0) * 5.0 / 9.0
    }

    static func celsiusToKelvin(_ c: Double) -> Double {
        return c + 273.15
    }

    // MARK: - 长度

    static func kilometersToMiles(_ km: Double) -> Double {
        return km * 0.621371
    }

    static func milesToKilometers(_ miles: Double) -> Double {
        return miles / 0.621371
    }

    static func metersToFeet(_ m: Double) -> Double {
        return m * 3.28084
    }

    // MARK: - 重量

    static func kilogramsToPounds(_ kg: Double) -> Double {
        return kg * 2.20462
    }

    static func poundsToKilograms(_ lb: Double) -> Double {
        return lb / 2.20462
    }

    // MARK: - 数据存储

    /// 字节转可读字符串：1536 -> "1.5 KB"
    static func humanReadableBytes(_ bytes: Int64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(bytes)
        var index = 0
        while value >= 1024 && index < units.count - 1 {
            value /= 1024
            index += 1
        }
        if index == 0 {
            return "\(Int(value)) \(units[index])"
        }
        return String(format: "%.1f %@", value, units[index])
    }
}
