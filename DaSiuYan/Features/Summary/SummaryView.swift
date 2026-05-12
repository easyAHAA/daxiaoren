// SummaryView.swift
// 焚化完成总结页：居中悬浮磨砂卡片 + 祈福文字 + 掷筊结果。
// Requirement 9.15、12.10、12.15。

import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var env: AppEnvironment

    let effigy: PaperEffigy
    let blessing: BlessingResult

    @State private var showContent = false

    var body: some View {
        ZStack {
            DiffusedBackground(mode: .preset(.nightLamp))

            VStack(spacing: 24) {
                Spacer()

                // 标题
                VStack(spacing: 8) {
                    Text("焚化完成")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("送走小人 · 万事顺遂")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .yellow],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )

                    Text(blessing.text)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)

                // 掷筊卡片
                VStack(spacing: 16) {
                    GlassmorphicCard(cornerRadius: 24) {
                        VStack(spacing: 12) {
                            Text("掷筊结果")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text(blessing.dice.chineseName)
                                .font(.system(size: 64, weight: .black, design: .serif))
                                .foregroundStyle(diceColor)
                                .shadow(color: diceColor.opacity(0.4), radius: 10)

                            Text(blessing.dice.subtitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.primary)

                            Divider().background(.white.opacity(0.2))

                            HStack(spacing: 24) {
                                stat(title: "纸片人", value: effigy.name)
                                stat(title: "打击次数", value: "\(effigy.strikeCount)")
                            }
                        }
                        .padding(28)
                    }
                    .padding(.horizontal, 40)
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.92)
                }

                Spacer()

                // 底部按钮
                HStack(spacing: 16) {
                    Button {
                        // 返回首页（pop 到 root）
                        goHome()
                    } label: {
                        Text("返回首页")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(.ultraThinMaterial)
                            )
                    }
                    .buttonStyle(.plain)

                    Button {
                        goHome()
                    } label: {
                        Text("完成")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule().fill(
                                    LinearGradient(
                                        colors: [.orange, Color.red.opacity(0.9)],
                                        startPoint: .leading, endPoint: .trailing
                                    )
                                )
                            )
                            .shadow(color: .orange.opacity(0.4), radius: 10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .opacity(showContent ? 1 : 0)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            // CremationSceneViewModel 已 markArchived，这里仅做 UI 动画
            withAnimation(.easeOut(duration: 0.8)) {
                showContent = true
            }
        }
    }

    private var diceColor: Color {
        switch blessing.dice {
        case .sacred: return .orange
        case .laughing: return .yellow
        case .yin: return .gray
        }
    }

    private func stat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
        }
    }

    private func goHome() {
        env.popToRoot()
    }
}
