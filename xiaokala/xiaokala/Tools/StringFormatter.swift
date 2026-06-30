//
//  StringFormatter.swift
//  xiaokala
//
//  字符串处理工具
//

import Foundation

/// 常用字符串处理工具
struct StringFormatter {

    /// 驼峰转下划线：myVariableName -> my_variable_name
    static func snakeCased(_ input: String) -> String {
        var result = ""
        for char in input {
            if char.isUppercase {
                if !result.isEmpty { result.append("_") }
                result.append(Character(char.lowercased()))
            } else {
                result.append(char)
            }
        }
        return result
    }

    /// 下划线转驼峰：my_variable_name -> myVariableName
    static func camelCased(_ input: String) -> String {
        let parts = input.split(separator: "_")
        guard let first = parts.first else { return "" }
        var result = String(first).lowercased()
        for part in parts.dropFirst() {
            result += part.prefix(1).uppercased() + part.dropFirst()
        }
        return result
    }

    /// 截断字符串并追加省略号
    static func truncate(_ input: String, limit: Int, ellipsis: String = "…") -> String {
        guard limit >= 0, input.count > limit else { return input }
        return String(input.prefix(limit)) + ellipsis
    }

    /// 反转字符串
    static func reversed(_ input: String) -> String {
        return String(input.reversed())
    }

    /// 是否为回文（忽略大小写和空格）
    static func isPalindrome(_ input: String) -> Bool {
        let cleaned = input.lowercased().filter { !$0.isWhitespace }
        return cleaned == String(cleaned.reversed())
    }

    /// 统计单词数量
    static func wordCount(_ input: String) -> Int {
        return input
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .count
    }

    /// 移除首尾空白
    static func trimmed(_ input: String) -> String {
        return input.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
