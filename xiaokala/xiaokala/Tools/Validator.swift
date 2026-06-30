//
//  Validator.swift
//  xiaokala
//
//  常用输入校验工具
//

import Foundation

/// 常用输入校验
struct Validator {

    /// 校验邮箱格式
    static func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return matches(email, pattern: pattern)
    }

    /// 校验中国大陆手机号（11 位，1 开头）
    static func isValidChinaPhone(_ phone: String) -> Bool {
        let pattern = "^1[3-9]\\d{9}$"
        return matches(phone, pattern: pattern)
    }

    /// 校验 URL 格式（http / https）
    static func isValidURL(_ urlString: String) -> Bool {
        let pattern = "^https?://[\\w.-]+(:\\d+)?(/.*)?$"
        return matches(urlString, pattern: pattern)
    }

    /// 校验是否为纯数字
    static func isNumeric(_ input: String) -> Bool {
        guard !input.isEmpty else { return false }
        return input.allSatisfy { $0.isNumber }
    }

    /// 校验长度区间
    static func isLength(_ input: String, min: Int, max: Int) -> Bool {
        return input.count >= min && input.count <= max
    }

    // MARK: - Private

    private static func matches(_ input: String, pattern: String) -> Bool {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return false
        }
        let range = NSRange(input.startIndex..., in: input)
        return regex.firstMatch(in: input, range: range) != nil
    }
}
