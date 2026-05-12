// SpriteKitBridges.swift
// SwiftUI → SpriteKit 桥接视图，用于打击粒子与焚化粒子。

import SwiftUI
import SpriteKit

// MARK: - 打击粒子层

public struct StrikeParticleLayer: UIViewRepresentable {
    @Binding public var strikeEvent: StrikeEmitEvent?
    public let renderTier: RenderTier

    public init(strikeEvent: Binding<StrikeEmitEvent?>, renderTier: RenderTier) {
        self._strikeEvent = strikeEvent
        self.renderTier = renderTier
    }

    public func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.isAsynchronous = true
        let scene = StrikeSpriteScene(size: CGSize(width: 400, height: 600))
        scene.setRenderTier(renderTier)
        view.presentScene(scene)
        return view
    }

    public func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? StrikeSpriteScene else { return }
        // 让 scene 大小随视图变化
        if scene.size != view.bounds.size, view.bounds.size != .zero {
            scene.size = view.bounds.size
        }
        scene.setRenderTier(renderTier)

        if let event = strikeEvent {
            scene.emitStrike(at: event.point, isHeavy: event.isHeavy)
            // 消费后置空
            DispatchQueue.main.async {
                self.strikeEvent = nil
            }
        }
    }
}

public struct StrikeEmitEvent: Equatable {
    public let point: CGPoint
    public let isHeavy: Bool
    public let salt: UUID

    public init(point: CGPoint, isHeavy: Bool) {
        self.point = point
        self.isHeavy = isHeavy
        self.salt = UUID()
    }
}

// MARK: - 焚化粒子层

public struct CremationParticleLayer: UIViewRepresentable {
    @Binding public var trigger: CremationTrigger?

    public init(trigger: Binding<CremationTrigger?>) {
        self._trigger = trigger
    }

    public func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.allowsTransparency = true
        view.backgroundColor = .clear
        view.ignoresSiblingOrder = true
        view.isAsynchronous = true
        let scene = CremationSpriteScene(size: CGSize(width: 400, height: 600))
        view.presentScene(scene)
        return view
    }

    public func updateUIView(_ view: SKView, context: Context) {
        guard let scene = view.scene as? CremationSpriteScene else { return }
        if scene.size != view.bounds.size, view.bounds.size != .zero {
            scene.size = view.bounds.size
        }
        if let trigger = trigger {
            let completion = trigger.completion
            scene.startCremation(at: trigger.point) {
                completion()
            }
            DispatchQueue.main.async {
                self.trigger = nil
            }
        }
    }
}

public struct CremationTrigger {
    public let point: CGPoint
    public let completion: () -> Void

    public init(point: CGPoint, completion: @escaping () -> Void) {
        self.point = point
        self.completion = completion
    }
}
