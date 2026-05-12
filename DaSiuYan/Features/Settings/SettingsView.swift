// SettingsView.swift
// 设置页：音效 / 触觉 / 咒语语言 / 主题 / 背景 / 渲染模式 / iCloud / 清除数据 / 自定义咒语。

import SwiftUI

// 隐藏 List 背景的 iOS 15/16+ 兼容 modifier
struct HiddenListBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollContentBackground(.hidden)
        } else {
            content.onAppear { UITableView.appearance().backgroundColor = .clear }
                   .onDisappear { UITableView.appearance().backgroundColor = nil }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var showBackgroundPicker = false
    @State private var showIncantationEditor = false
    @State private var showClearConfirm = false
    @State private var showCulturalDisclaimer = false

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                Form {
                    Section(header: Text("反馈").foregroundStyle(.secondary)) {
                        Toggle("音效", isOn: Binding(
                            get: { env.settingsService.settings.soundEnabled },
                            set: { v in env.settingsService.update { $0.soundEnabled = v } }
                        ))
                        Toggle("触觉反馈", isOn: Binding(
                            get: { env.settingsService.settings.hapticEnabled },
                            set: { v in env.settingsService.update { $0.hapticEnabled = v } }
                        ))
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section(header: Text("咒语").foregroundStyle(.secondary)) {
                        Picker("默认语言", selection: Binding(
                            get: { env.settingsService.settings.incantationLanguage },
                            set: { v in env.settingsService.update { $0.incantationLanguage = v } }
                        )) {
                            Text("粤语").tag(IncantationLanguage.cantonese)
                            Text("普通话").tag(IncantationLanguage.mandarin)
                        }
                        Button {
                            showIncantationEditor = true
                        } label: {
                            HStack {
                                Text("自定义咒语").foregroundStyle(.primary)
                                Spacer()
                                Text("\(env.incantationSystem.customIncantations.count)/20")
                                    .foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section(header: Text("外观").foregroundStyle(.secondary)) {
                        Picker("主题模式", selection: Binding(
                            get: { env.settingsService.settings.themeMode },
                            set: { v in env.settingsService.update { $0.themeMode = v } }
                        )) {
                            Text("跟随系统").tag(ThemeMode.system)
                            Text("浅色").tag(ThemeMode.light)
                            Text("深色").tag(ThemeMode.dark)
                        }
                        Button {
                            showBackgroundPicker = true
                        } label: {
                            HStack {
                                Text("背景设置").foregroundStyle(.primary)
                                Spacer()
                                Text(currentBackgroundName).foregroundStyle(.secondary)
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section(
                        header: Text("性能").foregroundStyle(.secondary),
                        footer: Text("自动：A12+ 设备启用 3D 完整粒子；老设备自动降级")
                    ) {
                        Picker("渲染模式", selection: Binding(
                            get: { env.settingsService.settings.renderModeOverride },
                            set: { v in env.settingsService.update { $0.renderModeOverride = v } }
                        )) {
                            Text("自动").tag(RenderOverride.auto)
                            Text("完整模式").tag(RenderOverride.full)
                            Text("轻量 2D").tag(RenderOverride.lite)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section(header: Text("数据与隐私").foregroundStyle(.secondary)) {
                        Toggle("iCloud 同步", isOn: Binding(
                            get: { env.settingsService.settings.iCloudSyncEnabled },
                            set: { v in env.settingsService.update { $0.iCloudSyncEnabled = v } }
                        ))
                        Button {
                            showClearConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash.fill")
                                Text("清除全部数据")
                            }
                            .foregroundStyle(.red)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))

                    Section(header: Text("关于").foregroundStyle(.secondary)) {
                        Button {
                            showCulturalDisclaimer = true
                        } label: {
                            HStack {
                                Text("文化声明").foregroundStyle(.primary)
                                Spacer()
                                Image(systemName: "info.circle").foregroundStyle(.tertiary)
                            }
                        }
                        HStack {
                            Text("版本")
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.08))
                }
                .modifier(HiddenListBackground())
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .sheet(isPresented: $showBackgroundPicker) {
                BackgroundPickerView().environmentObject(env)
            }
            .sheet(isPresented: $showIncantationEditor) {
                CustomIncantationEditorView().environmentObject(env)
            }
            .sheet(isPresented: $showCulturalDisclaimer) {
                CulturalDisclaimerView { showCulturalDisclaimer = false }
            }
            .alert("清除全部数据？", isPresented: $showClearConfirm) {
                Button("取消", role: .cancel) {}
                Button("确认清除", role: .destructive) {
                    try? env.effigyManager.clearAll()
                    env.incantationSystem.refreshCustoms()
                }
            } message: {
                Text("将删除所有纸片人、焚化记录、自定义咒语与照片。此操作不可恢复。")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var currentBackgroundName: String {
        switch env.settingsService.settings.backgroundMode {
        case .preset(let p): return p.chineseName
        case .solid: return "纯色"
        case .customImage: return "自定义图片"
        }
    }
}

// MARK: - 背景选择器

struct BackgroundPickerView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("预设弥散配色")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 14)], spacing: 14) {
                            ForEach(PresetPalette.allCases) { palette in
                                paletteCard(palette)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 12)
                }
            }
            .navigationTitle("背景设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func paletteCard(_ palette: PresetPalette) -> some View {
        let isSelected: Bool = {
            if case .preset(let p) = env.settingsService.settings.backgroundMode, p == palette {
                return true
            }
            return false
        }()

        return Button {
            env.settingsService.update { $0.backgroundMode = .preset(palette) }
            env.backgroundSystem.setPreset(palette)
        } label: {
            VStack(spacing: 8) {
                LinearGradient(colors: palette.stops, startPoint: .top, endPoint: .bottom)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? Color.orange : Color.white.opacity(0.2),
                                    lineWidth: isSelected ? 3 : 1)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                Text(palette.chineseName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
            }
        }
        .buttonStyle(.plain)
    }
}
