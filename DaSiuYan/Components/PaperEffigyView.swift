// PaperEffigyView.swift
// 示例纸片人视图（Demo 阶段使用形状 + emoji 占位，生产版替换为由用户照片生成的纸扎图层）。
// 对应 Requirement 4.2（六部位） / 6.x（分部位动画）。

import SwiftUI

public struct PaperEffigyView: View {
    /// 每个部位最近受击时间（用于触发局部动画）
    public let hitPart: EffigyBodyPart?
    public let hitSalt: Int  // 每次打击递增，用于触发相同 part 连续动画
    public let damage: Int   // 0...100 控制整体暗化

    @State private var headShake: CGFloat = 0
    @State private var leftArmAngle: Angle = .zero
    @State private var rightArmAngle: Angle = .zero
    @State private var leftLegAngle: Angle = .zero
    @State private var rightLegAngle: Angle = .zero
    @State private var torsoShake: CGFloat = 0

    public init(hitPart: EffigyBodyPart?, hitSalt: Int, damage: Int) {
        self.hitPart = hitPart
        self.hitSalt = hitSalt
        self.damage = damage
    }

    public var body: some View {
        // 基于 300x400 的设计稿
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                // 阴影
                Ellipse()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: size.width * 0.55, height: 16)
                    .offset(y: size.height * 0.48)
                    .blur(radius: 6)

                // 躯干
                paperShape(cornerRadius: 14)
                    .fill(paperFill)
                    .frame(width: size.width * 0.46, height: size.height * 0.42)
                    .offset(y: size.height * 0.05)
                    .offset(x: torsoShake)
                    .overlay(torsoCracks)

                // 左臂
                paperShape(cornerRadius: 10)
                    .fill(paperFill)
                    .frame(width: size.width * 0.18, height: size.height * 0.32)
                    .rotationEffect(leftArmAngle + .degrees(-35), anchor: .top)
                    .offset(x: -size.width * 0.28, y: -size.height * 0.02)

                // 右臂
                paperShape(cornerRadius: 10)
                    .fill(paperFill)
                    .frame(width: size.width * 0.18, height: size.height * 0.32)
                    .rotationEffect(rightArmAngle + .degrees(35), anchor: .top)
                    .offset(x: size.width * 0.28, y: -size.height * 0.02)

                // 左腿
                paperShape(cornerRadius: 8)
                    .fill(paperFill)
                    .frame(width: size.width * 0.18, height: size.height * 0.34)
                    .rotationEffect(leftLegAngle + .degrees(-8), anchor: .top)
                    .offset(x: -size.width * 0.12, y: size.height * 0.3)

                // 右腿
                paperShape(cornerRadius: 8)
                    .fill(paperFill)
                    .frame(width: size.width * 0.18, height: size.height * 0.34)
                    .rotationEffect(rightLegAngle + .degrees(8), anchor: .top)
                    .offset(x: size.width * 0.12, y: size.height * 0.3)

                // 头部
                headView
                    .frame(width: size.width * 0.36, height: size.width * 0.36)
                    .offset(y: -size.height * 0.35)
                    .offset(x: headShake)
            }
            .frame(width: size.width, height: size.height)
            // damage 越高，整体越暗
            .brightness(-Double(damage) / 400.0)
            .saturation(1.0 - Double(damage) / 300.0)
        }
        .onChange(of: hitSalt) { _ in
            triggerAnimation(for: hitPart)
        }
    }

    private var paperFill: Color {
        Color(red: 0.95, green: 0.88, blue: 0.72)
    }

    private var paperStroke: Color {
        Color(red: 0.38, green: 0.22, blue: 0.12).opacity(0.8)
    }

    private func paperShape(cornerRadius: CGFloat) -> some Shape {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    }

    // MARK: - 头部

    private var headView: some View {
        ZStack {
            Circle()
                .fill(paperFill)
            // 眉
            HStack(spacing: 10) {
                Capsule().fill(paperStroke).frame(width: 14, height: 3)
                Capsule().fill(paperStroke).frame(width: 14, height: 3)
            }
            .offset(y: -8)
            // 眼
            HStack(spacing: 18) {
                Circle().fill(paperStroke).frame(width: 6, height: 6)
                Circle().fill(paperStroke).frame(width: 6, height: 6)
            }
            // 嘴（随 damage 变化）
            mouth
                .offset(y: 14)
        }
        .overlay(
            Circle().stroke(paperStroke.opacity(0.5), lineWidth: 0.8)
        )
    }

    @ViewBuilder
    private var mouth: some View {
        if damage < 40 {
            Capsule().fill(paperStroke).frame(width: 16, height: 2.5)
        } else if damage < 80 {
            // 歪嘴
            Capsule()
                .fill(paperStroke)
                .frame(width: 18, height: 3)
                .rotationEffect(.degrees(-15))
        } else {
            // 惊呼
            Circle()
                .stroke(paperStroke, lineWidth: 2)
                .frame(width: 10, height: 12)
        }
    }

    // MARK: - 躯干裂痕

    @ViewBuilder
    private var torsoCracks: some View {
        if damage >= 20 {
            CrackOverlay(layer: min(5, damage / 20))
                .allowsHitTesting(false)
        }
    }

    // MARK: - 动画调度

    private func triggerAnimation(for part: EffigyBodyPart?) {
        guard let part = part else { return }
        let spring = Animation.interpolatingSpring(stiffness: 300, damping: 10)

        switch part {
        case .head:
            withAnimation(spring) { headShake = 12 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(spring) { headShake = -8 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(spring) { headShake = 0 }
            }

        case .torso:
            withAnimation(spring) { torsoShake = 8 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(spring) { torsoShake = -6 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(spring) { torsoShake = 0 }
            }

        case .leftArm:
            withAnimation(spring) { leftArmAngle = .degrees(-25) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(spring) { leftArmAngle = .zero }
            }

        case .rightArm:
            withAnimation(spring) { rightArmAngle = .degrees(25) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(spring) { rightArmAngle = .zero }
            }

        case .leftLeg:
            withAnimation(spring) { leftLegAngle = .degrees(-12) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(spring) { leftLegAngle = .zero }
            }

        case .rightLeg:
            withAnimation(spring) { rightLegAngle = .degrees(12) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(spring) { rightLegAngle = .zero }
            }
        }
    }
}

// MARK: - 裂痕覆盖层

struct CrackOverlay: View {
    let layer: Int  // 1...5

    var body: some View {
        GeometryReader { geo in
            Path { p in
                let w = geo.size.width
                let h = geo.size.height
                for i in 0..<layer {
                    let y = h * (0.2 + CGFloat(i) * 0.15)
                    p.move(to: CGPoint(x: w * 0.15, y: y))
                    p.addLine(to: CGPoint(x: w * 0.35, y: y + 10))
                    p.addLine(to: CGPoint(x: w * 0.55, y: y - 5))
                    p.addLine(to: CGPoint(x: w * 0.85, y: y + 8))
                }
            }
            .stroke(Color.black.opacity(0.4), lineWidth: 1.2)
        }
    }
}
