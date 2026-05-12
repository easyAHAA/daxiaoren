// StrikeSpriteScene.swift
// SwiftUI 叠加层的 SpriteKit 粒子场景，用于打击时的碎纸 + 尘土飞散。
// 对应 Requirement 6.4、15.6。

import SpriteKit
import UIKit

public final class StrikeSpriteScene: SKScene {

    private var renderTier: RenderTier = .full

    public override func didMove(to view: SKView) {
        backgroundColor = .clear
        scaleMode = .resizeFill
        // 透明 scene，只显示粒子
        view.allowsTransparency = true
        view.backgroundColor = .clear
    }

    public func setRenderTier(_ tier: RenderTier) {
        self.renderTier = tier
    }

    /// 在指定位置喷射碎纸 + 尘土粒子。
    public func emitStrike(at point: CGPoint, isHeavy: Bool) {
        // SpriteKit 与 UIKit 坐标 Y 轴相反，需要翻转
        let flipped = CGPoint(x: point.x, y: size.height - point.y)

        emitPaperShreds(at: flipped, isHeavy: isHeavy)
        if renderTier == .full {
            emitDust(at: flipped, isHeavy: isHeavy)
        }
    }

    // MARK: - 碎纸粒子

    private func emitPaperShreds(at point: CGPoint, isHeavy: Bool) {
        let count = renderTier == .full ? (isHeavy ? 18 : 12) : 8

        for _ in 0..<count {
            let node = SKShapeNode(rectOf: CGSize(width: 8, height: 12))
            node.fillColor = randomPaperColor()
            node.strokeColor = .clear
            node.position = point
            node.zRotation = CGFloat.random(in: 0...(.pi * 2))

            addChild(node)

            // 随机方向 + 速度
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let speed: CGFloat = isHeavy ? .random(in: 120...220) : .random(in: 80...160)
            let dx = cos(angle) * speed
            let dy = sin(angle) * speed + 60  // 向上偏移

            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 0.8)
            let rotate = SKAction.rotate(byAngle: .random(in: -(.pi * 2)...(.pi * 2)), duration: 0.8)
            let fade = SKAction.fadeOut(withDuration: 0.8)
            let remove = SKAction.removeFromParent()
            node.run(SKAction.sequence([SKAction.group([move, rotate, fade]), remove]))
        }
    }

    private func randomPaperColor() -> UIColor {
        let variants: [UIColor] = [
            UIColor(white: 0.96, alpha: 1),
            UIColor(red: 0.92, green: 0.86, blue: 0.72, alpha: 1),
            UIColor(red: 0.85, green: 0.74, blue: 0.58, alpha: 1)
        ]
        return variants.randomElement() ?? .white
    }

    // MARK: - 尘土粒子

    private func emitDust(at point: CGPoint, isHeavy: Bool) {
        let count = isHeavy ? 8 : 5
        for _ in 0..<count {
            let node = SKShapeNode(circleOfRadius: CGFloat.random(in: 4...8))
            node.fillColor = UIColor(white: 0.72, alpha: 0.5)
            node.strokeColor = .clear
            node.position = point
            addChild(node)

            let dx: CGFloat = .random(in: -40...40)
            let dy: CGFloat = .random(in: 20...80)
            let move = SKAction.move(by: CGVector(dx: dx, dy: dy), duration: 1.0)
            let scale = SKAction.scale(to: 2.0, duration: 1.0)
            let fade = SKAction.fadeOut(withDuration: 1.0)
            node.run(SKAction.sequence([
                SKAction.group([move, scale, fade]),
                SKAction.removeFromParent()
            ]))
        }
    }
}
