// DamageMeterView.swift
// 左侧竖向受击值进度条。
// Requirement 6.5 / 12.6。

import SwiftUI

public struct DamageMeterView: View {
    public let damage: Int  // 0...100

    public init(damage: Int) {
        self.damage = max(0, min(100, damage))
    }

    public var body: some View {
        VStack(spacing: 8) {
            Text("受击值")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(0))

            // 竖向条形
            GeometryReader { geo in
                ZStack(alignment: .bottom) {
                    // 背景槽
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.ultraThinMaterial)

                    // 填充
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: geo.size.height * CGFloat(damage) / 100)
                        .animation(.easeOut(duration: 0.3), value: damage)
                }
            }
            .frame(width: 12)

            Text("\(damage)%")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 8)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        )
    }

    /// 绿→黄→红渐变（随 damage 推移视觉递进）
    private var gradientColors: [Color] {
        if damage < 40 {
            return [.green.opacity(0.9), .yellow.opacity(0.7)]
        } else if damage < 80 {
            return [.orange.opacity(0.9), .red.opacity(0.8)]
        } else {
            return [.red.opacity(0.95), Color(red: 0.7, green: 0.0, blue: 0.0)]
        }
    }
}
