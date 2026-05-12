// BlessingResult.swift
// 焚化完成后生成的祈福结果（祈福文字 + 掷筊结果）
// 对应 Requirement 9.10、9.11、Property 13。

import Foundation

public struct BlessingResult: Equatable, Hashable {
    public let text: String       // 10-100 字符祈福文字（Property 13）
    public let dice: DiceResult   // 掷筊结果，P(圣筊) ≥ 0.80

    public init(text: String, dice: DiceResult) {
        self.text = text
        self.dice = dice
    }
}

// MARK: - Blessing 文本池（≥ 10 字符 ≤ 100 字符）

public enum BlessingTexts {
    public static let pool: [String] = [
        "送走小人 · 万事顺遂 · 心想事成 · 平安喜乐",
        "百邪辟除 · 吉星高照 · 财运亨通",
        "拨开云雾见青天 · 小人远离福自来",
        "洗去霉运 · 迎来好运 · 前途光明",
        "心诚则灵 · 诸事如意 · 福气盈门",
        "祈福无灾 · 出入平安 · 事业顺遂",
        "小人已去 · 贵人将至 · 福寿绵长"
    ]

    public static func random<G: RandomNumberGenerator>(using generator: inout G) -> String {
        pool.randomElement(using: &generator) ?? pool[0]
    }
}
