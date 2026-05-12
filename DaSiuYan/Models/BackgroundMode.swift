// BackgroundMode.swift
// 背景模式 + 预设弥散配色方案
// 对应 Requirement 12.2、12.12。

import SwiftUI

// MARK: - 预设配色方案

public enum PresetPalette: String, Codable, CaseIterable, Identifiable {
    case warm       // 暖红（默认）
    case bamboo     // 青竹
    case mist       // 晨雾
    case nightLamp  // 夜灯（深色优先）
    case ritualRed  // 祭红

    public var id: String { rawValue }

    public var chineseName: String {
        switch self {
        case .warm: return "暖红"
        case .bamboo: return "青竹"
        case .mist: return "晨雾"
        case .nightLamp: return "夜灯"
        case .ritualRed: return "祭红"
        }
    }

    /// 三段渐变色（自顶到底）
    public var stops: [Color] {
        switch self {
        case .warm:
            return [
                Color(red: 0.98, green: 0.92, blue: 0.84),  // 米色
                Color(red: 0.92, green: 0.72, blue: 0.60),  // 浅棕
                Color(red: 0.78, green: 0.36, blue: 0.32)   // 暖红
            ]
        case .bamboo:
            return [
                Color(red: 0.92, green: 0.95, blue: 0.90),
                Color(red: 0.68, green: 0.80, blue: 0.65),
                Color(red: 0.30, green: 0.48, blue: 0.38)
            ]
        case .mist:
            return [
                Color(red: 0.96, green: 0.94, blue: 0.90),
                Color(red: 0.82, green: 0.82, blue: 0.84),
                Color(red: 0.58, green: 0.66, blue: 0.72)
            ]
        case .nightLamp:
            return [
                Color(red: 0.12, green: 0.10, blue: 0.20),
                Color(red: 0.22, green: 0.10, blue: 0.28),
                Color(red: 0.42, green: 0.28, blue: 0.14)
            ]
        case .ritualRed:
            return [
                Color(red: 0.88, green: 0.30, blue: 0.28),
                Color(red: 0.70, green: 0.22, blue: 0.20),
                Color(red: 0.48, green: 0.20, blue: 0.16)
            ]
        }
    }

    /// 光晕点颜色（用于 Canvas 漂移径向渐变）
    public var glowTint: Color {
        switch self {
        case .warm: return Color(red: 1.0, green: 0.60, blue: 0.40).opacity(0.55)
        case .bamboo: return Color(red: 0.55, green: 0.85, blue: 0.65).opacity(0.45)
        case .mist: return Color(red: 0.90, green: 0.90, blue: 0.95).opacity(0.50)
        case .nightLamp: return Color(red: 0.85, green: 0.55, blue: 0.25).opacity(0.50)
        case .ritualRed: return Color(red: 1.0, green: 0.35, blue: 0.30).opacity(0.55)
        }
    }
}

// MARK: - 背景模式

public enum BackgroundMode: Equatable {
    case preset(PresetPalette)
    case solid(Color)
    case customImage(URL)
}
