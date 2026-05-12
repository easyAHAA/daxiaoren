// HomeView.swift
// 首页 — 悬浮弥散背景 + 纸片人卡片 + 顶部功能按钮 + 空态。
// Requirement 2 / 11 / 12.11 / 14.2 / 16.1。

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var env: AppEnvironment

    @State private var showCreate = false
    @State private var showKnowledge = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showCulturalDisclaimer = false
    @State private var selectedEffigy: PaperEffigy?
    @State private var showStrike = false
    @State private var deleteTarget: PaperEffigy?

    private var effigies: [PaperEffigy] { env.effigyManager.effigies }

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                VStack(spacing: 0) {
                    header
                    toolbar

                    if effigies.isEmpty {
                        emptyState
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(effigies) { effigy in
                                    EffigyCard(
                                        effigy: effigy,
                                        thumbnail: env.storage.loadImage(relativePath: effigy.imageRelativePath ?? ""),
                                        onTap: {
                                            selectedEffigy = effigy
                                            showStrike = true
                                        },
                                        onDelete: { deleteTarget = effigy }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                NavigationLink(destination: strikeDestination, isActive: $showStrike) { EmptyView() }.hidden()
            )
            .sheet(isPresented: $showCreate) {
                CreateEffigyView().environmentObject(env)
            }
            .sheet(isPresented: $showKnowledge) {
                KnowledgeTabView().environmentObject(env)
            }
            .sheet(isPresented: $showHistory) {
                CremationHistoryView().environmentObject(env)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView().environmentObject(env)
            }
            .fullScreenCover(isPresented: $showCulturalDisclaimer) {
                CulturalDisclaimerView {
                    env.settingsService.update { $0.culturalDisclaimerShown = true }
                    showCulturalDisclaimer = false
                }
            }
            .alert(item: $deleteTarget) { target in
                Alert(
                    title: Text("删除 \(target.name)？"),
                    message: Text("此操作不可恢复"),
                    primaryButton: .destructive(Text("删除")) {
                        try? env.effigyManager.delete(id: target.id)
                    },
                    secondaryButton: .cancel(Text("取消"))
                )
            }
            .onAppear {
                env.effigyManager.refresh()
                if !env.settingsService.settings.culturalDisclaimerShown {
                    showCulturalDisclaimer = true
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    @ViewBuilder
    private var strikeDestination: some View {
        if let effigy = selectedEffigy {
            StrikeSceneView(effigy: effigy).environmentObject(env)
        } else { EmptyView() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("打小人")
                    .font(.system(size: 30, weight: .bold, design: .serif))
                Text("\(effigies.count) / 10 个存档")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
    }

    private var toolbar: some View {
        HStack(spacing: 10) {
            Spacer()
            toolbarButton(icon: "plus", label: "新建", disabled: !env.effigyManager.canCreateMore) {
                showCreate = true
            }
            toolbarButton(icon: "book.closed.fill", label: "知识") { showKnowledge = true }
            toolbarButton(icon: "clock.fill", label: "历史") { showHistory = true }
            toolbarButton(icon: "gearshape.fill", label: "设置") { showSettings = true }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private func toolbarButton(icon: String, label: String, disabled: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(.ultraThinMaterial))
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.plain)
        .opacity(disabled ? 0.35 : 1)
        .disabled(disabled)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "figure.stand")
                .font(.system(size: 64))
                .foregroundStyle(.secondary.opacity(0.5))
            Text("还没有纸片人")
                .font(.system(size: 18, weight: .semibold))
            Text("点击右上角「新建」开始创建你的第一个纸片人")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button {
                showCreate = true
            } label: {
                Text("+ 新建纸片人")
                    .font(.system(size: 15, weight: .semibold))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .foregroundStyle(.white)
                    .background(
                        Capsule().fill(
                            LinearGradient(
                                colors: [.orange, Color.red.opacity(0.85)],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                    )
                    .shadow(color: .orange.opacity(0.4), radius: 10)
            }
            .buttonStyle(.plain)
            Spacer()
            Spacer()
        }
    }
}

private struct EffigyCard: View {
    let effigy: PaperEffigy
    let thumbnail: UIImage?
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        GlassmorphicCard(cornerRadius: 22) {
            HStack(spacing: 16) {
                thumbView
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 14))

                VStack(alignment: .leading, spacing: 4) {
                    Text(effigy.name)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    if !effigy.note.isEmpty {
                        Text(effigy.note)
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    HStack(spacing: 10) {
                        Label("\(effigy.strikeCount)", systemImage: "hand.tap.fill")
                            .font(.caption)
                        Label("\(effigy.damageState)%", systemImage: "flame.fill")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
        .contextMenu {
            Button(role: .destructive, action: onDelete) {
                Label("删除", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var thumbView: some View {
        if let img = thumbnail {
            Image(uiImage: img)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Circle().fill(Color.orange.opacity(0.15))
                Text("纸")
                    .font(.system(size: 22, weight: .bold, design: .serif))
            }
        }
    }
}
