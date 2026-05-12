// RenderTierProvider.swift
// 按设备 Metal 特性族 + 热态自动判定 RenderTier，
// 支持用户手动覆盖 (Requirement 15.4/15.5)。

import Foundation
import Metal
import UIKit

public protocol RenderTierProviding {
    var currentTier: RenderTier { get }
}

public final class RenderTierProvider: RenderTierProviding {
    public init() {}

    public var currentTier: RenderTier {
        // 1. 热态动态降级
        let thermal = ProcessInfo.processInfo.thermalState
        if thermal == .serious || thermal == .critical {
            return .lite
        }

        // 2. Metal 特性族：Apple 4 = A11（iPhone 8/X），Apple 5 = A12（iPhone XS+）
        // 我们要求 A12+ 才启用 full 模式
        guard let device = MTLCreateSystemDefaultDevice() else { return .lite }
        if #available(iOS 15.0, *) {
            if device.supportsFamily(.apple5) {
                return .full
            }
        }
        return .lite
    }
}
