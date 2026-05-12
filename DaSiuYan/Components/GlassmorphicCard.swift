// GlassmorphicCard.swift
// 半透明磨砂玻璃卡片，用于列表项 / 总结卡 / 提示卡。
// Requirement 12.3。

import SwiftUI

public struct GlassmorphicCard<Content: View>: View {
    public let cornerRadius: CGFloat
    public let content: () -> Content

    public init(cornerRadius: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    public var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                    )
            )
            .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
    }
}
