// HapticEngine.swift
// Core Haptics 实现 + 降级到 UIImpactFeedbackGenerator。
// 对应 Requirement 7.7-7.10、Property 9。

import Foundation
import CoreHaptics
import UIKit

public protocol HapticEngineProtocol: AnyObject {
    var isSupported: Bool { get }
    var isEnabled: Bool { get set }
    func prepare()
    func trigger(for prop: Prop, profile: PropProfile)
    func triggerLight()   // 未命中反馈
    func stop()
}

public final class HapticEngine: HapticEngineProtocol {

    private var engine: CHHapticEngine?
    public private(set) var isSupported: Bool = false
    public var isEnabled: Bool = true

    /// 降级路径的 feedback generator（heavy/medium 对应重/轻击）
    private lazy var heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private lazy var lightImpact = UIImpactFeedbackGenerator(style: .light)

    public init() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }

    public func prepare() {
        guard isSupported, engine == nil else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            // 意外停止时自动重启
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            engine?.stoppedHandler = { _ in }
        } catch {
            // 启动失败则降级
            engine = nil
            isSupported = false
        }
    }

    public func trigger(for prop: Prop, profile: PropProfile) {
        guard isEnabled else { return }

        // 取区间中值作为实际参数
        let intensity = (profile.hapticIntensity.lowerBound + profile.hapticIntensity.upperBound) / 2
        let duration = (profile.hapticDuration.lowerBound + profile.hapticDuration.upperBound) / 2

        if isSupported, let engine = engine {
            playCoreHaptics(engine: engine, intensity: intensity, duration: duration)
        } else {
            // 降级路径
            (profile.isHeavy ? heavyImpact : mediumImpact).impactOccurred()
        }
    }

    public func triggerLight() {
        guard isEnabled else { return }
        lightImpact.impactOccurred(intensity: 0.4)
    }

    private func playCoreHaptics(engine: CHHapticEngine, intensity: Float, duration: TimeInterval) {
        let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
        let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: intensity)

        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [intensityParam, sharpnessParam],
            relativeTime: 0,
            duration: duration
        )

        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            // 失败时降级
            heavyImpact.impactOccurred()
        }
    }

    public func stop() {
        try? engine?.stop()
    }
}
