// BackgroundSystem.swift
// 弥散背景模式管理。Demo 阶段只保存在内存；
// 生产版持久化到 Core Data UserSettings.backgroundModeData（Requirement 12.12）。

import Foundation
import Combine
import SwiftUI

public protocol BackgroundSystemProtocol: AnyObject {
    var currentPublisher: AnyPublisher<BackgroundMode, Never> { get }
    var current: BackgroundMode { get }
    func setPreset(_ palette: PresetPalette)
    func setSolid(_ color: Color)
}

public final class BackgroundSystem: BackgroundSystemProtocol, ObservableObject {

    @Published public private(set) var current: BackgroundMode

    public var currentPublisher: AnyPublisher<BackgroundMode, Never> {
        $current.eraseToAnyPublisher()
    }

    public init(initial: BackgroundMode = .preset(.warm)) {
        self.current = initial
    }

    public func setPreset(_ palette: PresetPalette) {
        current = .preset(palette)
    }

    public func setSolid(_ color: Color) {
        current = .solid(color)
    }
}
