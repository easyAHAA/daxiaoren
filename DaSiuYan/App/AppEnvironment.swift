// AppEnvironment.swift
// 依赖注入容器：服务单例 + 持久化。

import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppEnvironment: ObservableObject {

    // MARK: - Services

    public let storage: StorageServicing
    public let settingsService: SettingsService
    public let propSystem: PropProviding
    public let audioEngine: AudioEngineProtocol
    public let hapticEngine: HapticEngineProtocol
    public let incantationSystem: IncantationSystem
    public let imageProcessor: ImageProcessing
    public let renderTierProvider: RenderTierProviding
    public let backgroundSystem: BackgroundSystem
    public let effigyManager: PaperEffigyManager

    // MARK: - 导航

    @Published public var navigationTrigger: UUID = UUID()

    public var renderTier: RenderTier {
        switch settingsService.settings.renderModeOverride {
        case .full: return .full
        case .lite: return .lite
        case .auto: return renderTierProvider.currentTier
        }
    }

    public init() {
        let storage = StorageService()
        let settingsService = SettingsService()
        let audio = AudioEngine()
        let haptic = HapticEngine()
        let incantations = IncantationSystem(audioEngine: audio, storage: storage)

        self.storage = storage
        self.settingsService = settingsService
        self.propSystem = PropSystem()
        self.audioEngine = audio
        self.hapticEngine = haptic
        self.incantationSystem = incantations
        self.imageProcessor = ImageProcessor()
        self.renderTierProvider = RenderTierProvider()
        self.effigyManager = PaperEffigyManager(storage: storage)

        // 背景初始化
        let initialBG: BackgroundMode
        switch settingsService.settings.backgroundMode {
        case .preset(let p): initialBG = .preset(p)
        case .solid(let hex): initialBG = .solid(hex.color)
        case .customImage(let rel):
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
                .first!.appendingPathComponent(rel)
            initialBG = .customImage(url)
        }
        self.backgroundSystem = BackgroundSystem(initial: initialBG)

        // 应用初始偏好到引擎
        audio.isEnabled = settingsService.settings.soundEnabled
        haptic.isEnabled = settingsService.settings.hapticEnabled

        // 订阅设置变更
        settingsService.publisher
            .sink { [weak self] s in
                self?.audioEngine.isEnabled = s.soundEnabled
                self?.hapticEngine.isEnabled = s.hapticEnabled
                if !s.soundEnabled { self?.audioEngine.stopAll() }
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    public func popToRoot() {
        navigationTrigger = UUID()
    }
}

#if DEBUG
extension AppEnvironment {
    static let preview: AppEnvironment = AppEnvironment()
}
#endif
