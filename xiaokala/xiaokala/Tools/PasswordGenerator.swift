//
//  PasswordGenerator.swift
//  xiaokala
//
//  随机密码生成工具
//

import Foundation

/// 随机密码生成器
struct PasswordGenerator {

    /// 字符集选项
    struct Options {
        var length: Int = 12
        var includeLowercase = true
        var includeUppercase = true
        var includeDigits = true
        var includeSymbols = false

        static let `default` = Options()
    }

    private static let lowercase = "abcdefghijklmnopqrstuvwxyz"
    private static let uppercase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    private static let digits = "0123456789"
    private static let symbols = "!@#$%^&*()-_=+[]{}"

    /// 根据选项生成密码，参数非法时返回 nil
    static func generate(_ options: Options = .default) -> String? {
        guard options.length > 0 else { return nil }

        var pool = ""
        if options.includeLowercase { pool += lowercase }
        if options.includeUppercase { pool += uppercase }
        if options.includeDigits { pool += digits }
        if options.includeSymbols { pool += symbols }

        let chars = Array(pool)
        guard !chars.isEmpty else { return nil }

        var result = ""
        for _ in 0..<options.length {
            if let pick = chars.randomElement() {
                result.append(pick)
            }
        }
        return result
    }

    /// 快捷方法：生成指定长度的字母数字密码
    static func alphanumeric(length: Int = 16) -> String? {
        var opt = Options()
        opt.length = length
        opt.includeSymbols = false
        return generate(opt)
    }

    /// 估算密码强度，范围 0...4
    static func strength(of password: String) -> Int {
        var score = 0
        if password.count >= 8 { score += 1 }
        if password.count >= 12 { score += 1 }
        if password.contains(where: { $0.isNumber }) { score += 1 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 1 }
        return min(score, 4)
    }
}
