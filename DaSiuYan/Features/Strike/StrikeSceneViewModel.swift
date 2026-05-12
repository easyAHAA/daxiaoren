// StrikeSceneViewModel.swift
// 打击场景核心协调者。
// Requirement 4 / 5 / 6 / 7 / 8 / 12。

import Foundation
import SwiftUI
import Combine

@MainActor
public final class StrikeSceneViewModel: ObservableObject {

    @Published public private(set) var effigy: PaperEffigy
    @Published public private(set) var strikeCount: Int = 0
    @Published public private(set) var damageState: Int = 0

    @Published public var currentProp: Prop = .slipper
    @Published public var incantationMode: IncantationMode = .auto
    @Published public var currentIncantationText: String = ""
    @Published public var incantationLanguage: IncantationLanguage = .cantonese

    @Published public var isSoundEnabled: Bool = true {
        didSet { audioEngine.isEnabled = isSoundEnabled }
    }
    @Published public var isHapticEnabled: Bool = true {
        didSet { hapticEngine.isEnabled = isHapticEnabled }
    }

    @Published public private(set) var lastHitPart: EffigyBodyPart?
    @Published public private(set) var hitSalt: Int = 0
    @Published public var pendingParticleEvent: StrikeEmitEvent?
    @Published public private(set) var hintVisible: Bool = true

    private var propSystem: PropProviding
    private var audioEngine: AudioEngineProtocol
    private var hapticEngine: HapticEngineProtocol
    private var incantationSystem: IncantationSystemProtocol
    private var effigyManager: PaperEffigyManager?
    public let hitTester: HitTester

    private var incantationHideTask: Task<Void, Never>?

    public init(
        effigy: PaperEffigy,
        propSystem: PropProviding,
        audioEngine: AudioEngineProtocol,
        hapticEngine: HapticEngineProtocol,
        incantationSystem: IncantationSystemProtocol,
        effigyManager: PaperEffigyManager? = nil,
        hitTester: HitTester = .default
    ) {
        self.effigy = effigy
        self.strikeCount = effigy.strikeCount
        self.damageState = effigy.damageState
        self.propSystem = propSystem
        self.audioEngine = audioEngine
        self.hapticEngine = hapticEngine
        self.incantationSystem = incantationSystem
        self.effigyManager = effigyManager
        self.hitTester = hitTester

        audioEngine.prepare()
        hapticEngine.prepare()
    }

    public func setServices(
        propSystem: PropProviding,
        audioEngine: AudioEngineProtocol,
        hapticEngine: HapticEngineProtocol,
        incantationSystem: IncantationSystemProtocol,
        effigyManager: PaperEffigyManager,
        language: IncantationLanguage
    ) {
        self.propSystem = propSystem
        self.audioEngine = audioEngine
        self.hapticEngine = hapticEngine
        self.incantationSystem = incantationSystem
        self.effigyManager = effigyManager
        self.incantationLanguage = language
        audioEngine.prepare()
        hapticEngine.prepare()
    }

    public func switchProp(_ prop: Prop) {
        currentProp = prop
    }

    public func toggleSound() {
        isSoundEnabled.toggle()
        if !isSoundEnabled { audioEngine.stopAll() }
    }

    public func cycleIncantationMode() {
        switch incantationMode {
        case .off: incantationMode = .auto
        case .auto: incantationMode = .manual
        case .manual: incantationMode = .off
        }
    }

    public var incantationModeIcon: String {
        switch incantationMode {
        case .auto: return "waveform.circle.fill"
        case .manual: return "hand.tap.fill"
        case .off: return "speaker.slash.fill"
        }
    }

    public var incantationModeLabel: String {
        switch incantationMode {
        case .auto: return "自动"
        case .manual: return "手动"
        case .off: return "静默"
        }
    }

    public func playRandomIncantation() {
        guard let inc = incantationSystem.pickRandom() else { return }
        showIncantation(inc)
    }

    public func handleStrike(at point: CGPoint, in bounds: CGRect) {
        guard let hitPart = hitTester.resolvePart(point: point, in: bounds) else {
            hapticEngine.triggerLight()
            return
        }

        let profile = propSystem.profile(for: currentProp)
        strikeCount += 1
        damageState = min(100, damageState + profile.damagePerHit)
        lastHitPart = hitPart
        hitSalt &+= 1

        if hintVisible {
            withAnimation(.easeOut(duration: 0.4)) { hintVisible = false }
        }

        pendingParticleEvent = StrikeEmitEvent(point: point, isHeavy: profile.isHeavy)
        audioEngine.playStrike(for: currentProp)
        audioEngine.playPaperTear()
        hapticEngine.trigger(for: currentProp, profile: profile)

        if incantationMode == .auto, let inc = incantationSystem.pickRandom() {
            showIncantation(inc)
        }
    }

    private func showIncantation(_ incantation: Incantation) {
        let text = incantation.text(for: incantationLanguage)
        withAnimation(.easeIn(duration: 0.2)) {
            currentIncantationText = text
        }
        incantationSystem.trigger(incantation, language: incantationLanguage)

        incantationHideTask?.cancel()
        incantationHideTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.4)) {
                    self?.currentIncantationText = ""
                }
            }
        }
    }

    public func prepareForExit() -> PaperEffigy {
        var updated = effigy
        updated.damageState = damageState
        updated.strikeCount = strikeCount
        audioEngine.stopAll()
        try? effigyManager?.update(updated)
        return updated
    }

    public func prepareForExitPassive() -> PaperEffigy {
        var updated = effigy
        updated.damageState = damageState
        updated.strikeCount = strikeCount
        return updated
    }
}
