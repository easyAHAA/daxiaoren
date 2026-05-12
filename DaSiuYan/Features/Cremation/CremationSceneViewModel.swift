// CremationSceneViewModel.swift
// 焚化仪式：拖拽命中 → 组合动画 → Blessing 生成 → 持久化 CremationRecord。
// Requirement 9 / Property 12 / 13 / 14。

import Foundation
import SwiftUI

@MainActor
public final class CremationSceneViewModel: ObservableObject {

    public enum State: Equatable {
        case ready
        case dragging
        case animating
        case completed
        case persistFailed
    }

    @Published public private(set) var state: State = .ready
    @Published public var dragOffset: CGSize = .zero
    @Published public var isOverCenser: Bool = false
    @Published public var cremationTrigger: CremationTrigger?
    @Published public private(set) var blessing: BlessingResult?
    @Published public private(set) var errorMessage: String?
    @Published public var effigy: PaperEffigy

    private let audioEngine: AudioEngineProtocol
    private var storage: StorageServicing?
    private var effigyManager: PaperEffigyManager?

    private var rng: any RandomNumberGenerator

    public init(
        effigy: PaperEffigy,
        audioEngine: AudioEngineProtocol,
        storage: StorageServicing? = nil,
        effigyManager: PaperEffigyManager? = nil,
        rng: any RandomNumberGenerator = SystemRandomNumberGenerator()
    ) {
        self.effigy = effigy
        self.audioEngine = audioEngine
        self.storage = storage
        self.effigyManager = effigyManager
        self.rng = rng
    }

    public func setServices(storage: StorageServicing, effigyManager: PaperEffigyManager) {
        self.storage = storage
        self.effigyManager = effigyManager
    }

    public func onDragChanged(translation: CGSize, effigyCenter: CGPoint, censerRect: CGRect) {
        guard state == .ready || state == .dragging else { return }
        state = .dragging
        dragOffset = translation
        let currentCenter = CGPoint(
            x: effigyCenter.x + translation.width,
            y: effigyCenter.y + translation.height
        )
        isOverCenser = censerRect.contains(currentCenter)
    }

    public func onDragEnded(effigyCenter: CGPoint, censerRect: CGRect) {
        guard state == .dragging else { return }

        let droppedCenter = CGPoint(
            x: effigyCenter.x + dragOffset.width,
            y: effigyCenter.y + dragOffset.height
        )

        if censerRect.contains(droppedCenter) {
            startCremation(at: CGPoint(x: censerRect.midX, y: censerRect.midY))
        } else {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                dragOffset = .zero
                isOverCenser = false
            }
            state = .ready
        }
    }

    public func startCremation(at point: CGPoint) {
        guard state != .animating else { return }
        state = .animating
        isOverCenser = false

        cremationTrigger = CremationTrigger(point: point) { [weak self] in
            Task { @MainActor in
                await self?.completeCremation()
            }
        }

        Task { await audioEngine.playCremation() }
    }

    public func retryPersist() {
        guard let blessing = blessing else { return }
        Task { @MainActor in
            await persist(blessing: blessing)
        }
    }

    private func completeCremation() async {
        let result = Self.generateBlessing(using: &rng)
        blessing = result
        await persist(blessing: result)
    }

    private func persist(blessing: BlessingResult) async {
        guard let storage = storage else {
            withAnimation(.easeIn(duration: 0.4)) { state = .completed }
            return
        }
        do {
            let record = CremationRecord(
                effigyID: effigy.id,
                nameSnapshot: effigy.name,
                blessingText: blessing.text,
                dice: blessing.dice,
                strikeCountAtCremation: effigy.strikeCount
            )
            try storage.saveCremationRecord(record)
            try effigyManager?.markArchived(id: effigy.id)
            withAnimation(.easeIn(duration: 0.4)) { state = .completed }
        } catch {
            errorMessage = "保存焚化记录失败：\(error.localizedDescription)"
            state = .persistFailed
        }
    }

    public static func generateBlessing<G: RandomNumberGenerator>(using rng: inout G) -> BlessingResult {
        let dice: DiceResult = {
            let r = Double.random(in: 0...1, using: &rng)
            if r < 0.85 { return .sacred }
            else if r < 0.95 { return .laughing }
            else { return .yin }
        }()
        let text = BlessingTexts.random(using: &rng)
        return BlessingResult(text: text, dice: dice)
    }
}
