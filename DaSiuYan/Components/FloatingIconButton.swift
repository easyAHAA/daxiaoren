// FloatingIconButton.swift
// 右上角悬浮功能按钮（音效 / 咒语）。
// Requirement 12.5-12.8。

import SwiftUI

public struct FloatingIconButton: View {
    public let systemImage: String
    public let label: String
    public var isActive: Bool
    public let action: () -> Void

    public init(
        systemImage: String,
        label: String,
        isActive: Bool = true,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.label = label
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(isActive ? Color.primary : Color.secondary)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
