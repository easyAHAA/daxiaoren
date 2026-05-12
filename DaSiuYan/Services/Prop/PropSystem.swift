// PropSystem.swift
// 道具系统：注册、切换、按道具提供 haptic/audio/animation 配置。
// 对应 Requirement 5 + 7.8 + Property 6、9。

import Foundation

// MARK: - Prop 配置表

public struct PropProfile: Equatable {
    public let prop: Prop
    public let damagePerHit: Int                         // 每次打击累积的 Damage 增量 (1...5)
    public let hapticIntensity: ClosedRange<Float>       // Core Haptics intensity
    public let hapticDuration: ClosedRange<TimeInterval> // Haptic pattern duration
    public let soundDuration: ClosedRange<TimeInterval>  // 音效时长（Property 8）
    public let hasWhiteTigerOverlay: Bool                // 祭白虎令专属动画

    public var isHeavy: Bool {
        // Requirement 7.8：砖头/扫把/旧鞋/祭白虎令为重击
        hapticIntensity.lowerBound >= 0.7
    }
}

// MARK: - 协议

public protocol PropProviding {
    var allProps: [Prop] { get }
    func profile(for prop: Prop) -> PropProfile
}

// MARK: - 默认实现

public final class PropSystem: PropProviding {
    public init() {}

    public var allProps: [Prop] { Prop.allCases }

    public func profile(for prop: Prop) -> PropProfile {
        switch prop {
        case .slipper:
            return PropProfile(
                prop: .slipper,
                damagePerHit: 2,
                hapticIntensity: 0.3...0.5,
                hapticDuration: 0.05...0.15,
                soundDuration: 0.3...1.0,
                hasWhiteTigerOverlay: false
            )
        case .ruler:
            return PropProfile(
                prop: .ruler,
                damagePerHit: 2,
                hapticIntensity: 0.3...0.5,
                hapticDuration: 0.05...0.15,
                soundDuration: 0.3...1.0,
                hasWhiteTigerOverlay: false
            )
        case .oldShoe:
            return PropProfile(
                prop: .oldShoe,
                damagePerHit: 3,
                hapticIntensity: 0.7...1.0,
                hapticDuration: 0.15...0.30,
                soundDuration: 0.5...1.5,
                hasWhiteTigerOverlay: false
            )
        case .brick:
            return PropProfile(
                prop: .brick,
                damagePerHit: 5,
                hapticIntensity: 0.7...1.0,
                hapticDuration: 0.15...0.30,
                soundDuration: 0.5...1.5,
                hasWhiteTigerOverlay: false
            )
        case .broom:
            return PropProfile(
                prop: .broom,
                damagePerHit: 3,
                hapticIntensity: 0.7...1.0,
                hapticDuration: 0.15...0.30,
                soundDuration: 0.5...1.5,
                hasWhiteTigerOverlay: false
            )
        case .whiteTigerTalisman:
            return PropProfile(
                prop: .whiteTigerTalisman,
                damagePerHit: 4,
                hapticIntensity: 0.7...1.0,
                hapticDuration: 0.15...0.30,
                soundDuration: 0.5...2.0,
                hasWhiteTigerOverlay: true
            )
        }
    }
}
