// PropChipView.swift
// 底部道具选择条单项。
// Requirement 5.2 / 5.3 / 12.4。

import SwiftUI

public struct PropChipView: View {
    public let prop: Prop
    public let isSelected: Bool
    public let action: () -> Void

    public init(prop: Prop, isSelected: Bool, action: @escaping () -> Void) {
        self.prop = prop
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                PropIcon(prop: prop)
                    .frame(width: 52, height: 52)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        isSelected
                                            ? Color.orange.opacity(0.9)
                                            : Color.white.opacity(0.2),
                                        lineWidth: isSelected ? 2 : 0.5
                                    )
                            )
                    )
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? .orange.opacity(0.5) : .clear, radius: 8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)

                Text(prop.chineseName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Prop 图标（Demo 阶段使用 SF Symbol 占位 + 中文字符）

public struct PropIcon: View {
    public let prop: Prop

    public var body: some View {
        ZStack {
            switch prop {
            case .slipper:
                Text("👡").font(.system(size: 28))
            case .oldShoe:
                Text("👞").font(.system(size: 28))
            case .brick:
                Text("🧱").font(.system(size: 28))
            case .ruler:
                Text("📏").font(.system(size: 28))
            case .broom:
                Text("🧹").font(.system(size: 28))
            case .whiteTigerTalisman:
                Text("🐯").font(.system(size: 28))
            }
        }
    }
}
