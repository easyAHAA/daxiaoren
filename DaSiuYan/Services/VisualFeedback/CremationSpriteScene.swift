// CremationSpriteScene.swift
// 焚化场景的 2D 火焰 + 烟雾 + 灰烬粒子。
// 一期 Demo 统一使用 SpriteKit（design.md 中 A12+ 可替换为 RealityKit）。
// 对应 Requirement 9.8。

import SpriteKit
import UIKit

public final class CremationSpriteScene: SKScene {

    private var flameLayer: SKNode?
    private var smokeLayer: SKNode?
    private var isPlaying = false

    public override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        view.allowsTransparency = true
        view.backgroundColor = .clear
    }

    /// 触发完整焚化动画（3–6 秒）并在完成后回调。
    public func startCremation(at point: CGPoint, completion: @escaping () -> Void) {
        guard !isPlaying else { return }
        isPlaying = true

        // SpriteKit 坐标 Y 轴与 UIKit 相反
        let flipped = CGPoint(x: point.x, y: size.height - point.y)

        playFlames(at: flipped)
        playSmoke(at: flipped)
        playEmbers(at: flipped)

        // 总时长 5 秒（落在 3–6s 区间内）
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.isPlaying = false
            completion()
        }
    }

    // MARK: - 火焰粒子

    private func playFlames(at point: CGPoint) {
        for i in 0..<40 {
            let flame = SKShapeNode(circleOfRadius: CGFloat.random(in: 8...16))
            let colors: [UIColor] = [
                UIColor(red: 1.0, green: 0.6, blue: 0.1, alpha: 0.9),
                UIColor(red: 1.0, green: 0.4, blue: 0.05, alpha: 0.9),
                UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9),
                UIColor(red: 0.95, green: 0.3, blue: 0.08, alpha: 0.9)
            ]
            flame.fillColor = colors.randomElement() ?? .orange
            flame.strokeColor = .clear
            flame.blendMode = .add
            flame.position = CGPoint(
                x: point.x + .random(in: -30...30),
                y: point.y
            )
            addChild(flame)

            let delay = Double(i) * 0.05
            let rise = SKAction.moveBy(x: .random(in: -40...40), y: .random(in: 180...280), duration: .random(in: 1.2...1.8))
            let scale = SKAction.scale(to: .random(in: 0.3...0.6), duration: 1.5)
            let fade = SKAction.fadeOut(withDuration: 1.5)
            let seq = SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([rise, scale, fade]),
                SKAction.removeFromParent()
            ])
            flame.run(seq)
        }
    }

    // MARK: - 烟雾粒子

    private func playSmoke(at point: CGPoint) {
        for i in 0..<25 {
            let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 20...35))
            smoke.fillColor = UIColor(white: 0.3, alpha: 0.4)
            smoke.strokeColor = .clear
            smoke.position = CGPoint(x: point.x + .random(in: -40...40), y: point.y + 80)
            addChild(smoke)

            let delay = 0.3 + Double(i) * 0.08
            let rise = SKAction.moveBy(x: .random(in: -60...60), y: .random(in: 200...320), duration: 3.0)
            let scale = SKAction.scale(to: 2.5, duration: 3.0)
            let fade = SKAction.fadeOut(withDuration: 3.0)
            smoke.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([rise, scale, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }

    // MARK: - 灰烬粒子（焚化后期飘散）

    private func playEmbers(at point: CGPoint) {
        for i in 0..<18 {
            let ember = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...5))
            ember.fillColor = UIColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 0.9)
            ember.strokeColor = .clear
            ember.blendMode = .add
            ember.position = point
            addChild(ember)

            let delay = 2.5 + Double(i) * 0.05
            let drift = SKAction.moveBy(
                x: .random(in: -120...120),
                y: .random(in: 100...200),
                duration: 2.0
            )
            let twinkle = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.3),
                SKAction.fadeAlpha(to: 0.9, duration: 0.3)
            ])
            ember.run(SKAction.sequence([
                SKAction.wait(forDuration: delay),
                SKAction.group([
                    drift,
                    SKAction.repeatForever(twinkle)
                ]),
            ]))
            // 2 秒后移除
            ember.run(SKAction.sequence([
                SKAction.wait(forDuration: delay + 2.0),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ]))
        }
    }
}
