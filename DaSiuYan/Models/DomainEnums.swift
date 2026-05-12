// DomainEnums.swift
// 领域层枚举定义：Effigy_Body_Part、Prop、DiceResult 等。
// 所有枚举使用 String 原始值以便后续 JSON 序列化、Core Data 迁移与测试断言。

import Foundation

// MARK: - 纸片人六部位（Requirement 4.2）

public enum EffigyBodyPart: String, Codable, CaseIterable, Identifiable {
    case head      // 头部
    case leftArm   // 左手臂
    case rightArm  // 右手臂
    case torso     // 躯干
    case leftLeg   // 左腿
    case rightLeg  // 右腿

    public var id: String { rawValue }

    /// 中文显示名（用于提示文字）
    public var chineseName: String {
        switch self {
        case .head: return "头部"
        case .leftArm: return "左臂"
        case .rightArm: return "右臂"
        case .torso: return "躯干"
        case .leftLeg: return "左腿"
        case .rightLeg: return "右腿"
        }
    }
}

// MARK: - 打击道具（Requirement 5.1）

public enum Prop: String, Codable, CaseIterable, Identifiable {
    case slipper             // 拖鞋
    case oldShoe             // 旧鞋
    case brick               // 砖头
    case ruler               // 尺子
    case broom               // 扫把
    case whiteTigerTalisman  // 祭白虎令

    public var id: String { rawValue }

    public var chineseName: String {
        switch self {
        case .slipper: return "拖鞋"
        case .oldShoe: return "旧鞋"
        case .brick: return "砖头"
        case .ruler: return "尺子"
        case .broom: return "扫把"
        case .whiteTigerTalisman: return "祭白虎"
        }
    }

    /// SF Symbol 占位图标（Demo 阶段用系统图标；后续替换为自定义 Asset）
    public var sfSymbol: String {
        switch self {
        case .slipper: return "shoe.fill"           // iOS 17+；低版本 fallback 见 PropIcon
        case .oldShoe: return "shoe"
        case .brick: return "square.fill"
        case .ruler: return "ruler.fill"
        case .broom: return "paintbrush.fill"
        case .whiteTigerTalisman: return "flame.fill"
        }
    }
}

// MARK: - 咒语语言 / 模式（Requirement 8）

public enum IncantationLanguage: String, Codable, CaseIterable {
    case cantonese  // 粤语 zh-HK
    case mandarin   // 普通话 zh-CN

    /// 对应 `AVSpeechSynthesisVoice` 的 language code
    public var voiceLanguageCode: String {
        switch self {
        case .cantonese: return "zh-HK"
        case .mandarin: return "zh-CN"
        }
    }
}

public enum IncantationMode: String, Codable, CaseIterable {
    case auto     // 每次打击自动抽取
    case manual   // 用户手动点击播放
    case off      // 关闭
}

// MARK: - 掷筊结果（Requirement 9.10）

public enum DiceResult: String, Codable, CaseIterable {
    case sacred    // 圣筊 — 大吉
    case laughing  // 笑筊
    case yin       // 阴筊

    public var chineseName: String {
        switch self {
        case .sacred: return "圣筊"
        case .laughing: return "笑筊"
        case .yin: return "阴筊"
        }
    }

    public var subtitle: String {
        switch self {
        case .sacred: return "大吉 · 心想事成"
        case .laughing: return "再接再厉"
        case .yin: return "平心静气"
        }
    }
}

// MARK: - 渲染分级（Requirement 15.4）

public enum RenderTier {
    case full   // iPhone 11+ / iPad A12+：RealityKit + 完整粒子
    case lite   // 低性能设备：SpriteKit 2D + 简化粒子
}

// MARK: - 主题模式（Requirement 13.4）

public enum ThemeMode: String, Codable, CaseIterable {
    case system
    case light
    case dark
}
