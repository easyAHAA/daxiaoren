// Incantation.swift
// 咒语领域模型 + 内置咒语数据源。
// 一期使用 AVSpeechSynthesizer 合成，不依赖音频资源。

import Foundation

public struct Incantation: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let cantoneseText: String  // 粤语文本（4-60 字符，Property 11）
    public let mandarinText: String   // 普通话文本
    public let isBuiltIn: Bool

    public init(
        id: UUID = UUID(),
        cantoneseText: String,
        mandarinText: String,
        isBuiltIn: Bool = true
    ) {
        self.id = id
        self.cantoneseText = cantoneseText
        self.mandarinText = mandarinText
        self.isBuiltIn = isBuiltIn
    }

    public func text(for language: IncantationLanguage) -> String {
        switch language {
        case .cantonese: return cantoneseText
        case .mandarin: return mandarinText
        }
    }
}

// MARK: - 内置咒语（≥ 6 条，满足 Requirement 8.1）

public enum BuiltInIncantations {
    public static let all: [Incantation] = [
        Incantation(
            cantoneseText: "打你个小人头，等你有气冇定摆",
            mandarinText: "打你小人头，让你心神不宁"
        ),
        Incantation(
            cantoneseText: "打到你有嘴冇敢出声",
            mandarinText: "打到你有嘴不敢说话"
        ),
        Incantation(
            cantoneseText: "打到你有食冇敢抢食",
            mandarinText: "打到你有食不敢抢食"
        ),
        Incantation(
            cantoneseText: "打到你有钱冇敢抢钱",
            mandarinText: "打到你有钱不敢抢钱"
        ),
        Incantation(
            cantoneseText: "打到你见亲我就愰",
            mandarinText: "打到你见我就发抖"
        ),
        Incantation(
            cantoneseText: "打走小人，事事顺利",
            mandarinText: "送走小人，万事顺遂"
        )
    ]
}
