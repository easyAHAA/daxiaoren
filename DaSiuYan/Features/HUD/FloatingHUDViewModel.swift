// FloatingHUDViewModel.swift
// 右上角悬浮按钮淡化状态机。
// Requirement 12.6 / 12.7 / 12.8、Property 15。

import Foundation
import SwiftUI
import Combine

@MainActor
public final class FloatingHUDViewModel: ObservableObject {

    /// opacity ∈ [0.3, 1.0]，Property 15 边界
    @Published public private(set) var opacity: Double = 1.0

    private var idleTask: Task<Void, Never>?
    private let idleDelay: Double = 5.0       // 闲置 5s 开始淡化
    private let boostAfterStrike: Double = 3.0 // 打击后额外 3s 保持
    private let fadedOpacity: Double = 0.3
    private let fadeDuration: Double = 1.0

    public init() {
        startIdleCountdown()
    }

    deinit {
        idleTask?.cancel()
    }

    /// 用户触碰 HUD 按钮或附近区域（Requirement 12.7：300ms 恢复）
    public func onUserActivity() {
        restoreOpacityImmediately()
        startIdleCountdown()
    }

    /// 发生打击事件（Requirement 12.8：额外保持 3s）
    public func onStrike() {
        restoreOpacityImmediately()
        startBoostedCountdown()
    }

    // MARK: - 内部

    private func restoreOpacityImmediately() {
        withAnimation(.easeInOut(duration: 0.3)) {
            opacity = 1.0
        }
    }

    private func startIdleCountdown() {
        idleTask?.cancel()
        idleTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.idleDelay * 1_000_000_000))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: self.fadeDuration)) {
                self.opacity = self.fadedOpacity
            }
        }
    }

    private func startBoostedCountdown() {
        idleTask?.cancel()
        idleTask = Task { @MainActor [weak self] in
            guard let self = self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.boostAfterStrike * 1_000_000_000))
            if Task.isCancelled { return }
            // 打击保持期结束后进入常规 idle 倒计时
            self.startIdleCountdown()
        }
    }
}
