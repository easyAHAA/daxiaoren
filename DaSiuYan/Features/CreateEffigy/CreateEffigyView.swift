// CreateEffigyView.swift
// 照片导入 → Vision 人像检测 → Core Image 纸扎风格化 → 保存。
// Requirement 1 / 16.4。

import SwiftUI

struct CreateEffigyView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var name: String = ""
    @State private var note: String = ""
    @State private var showPrivacyNotice = false

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                ScrollView {
                    VStack(spacing: 20) {
                        culturalTip
                        previewArea
                        PhotoPickerView(selected: $selectedImage)
                        formSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("新建纸片人")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPrivacyNotice) {
                PrivacyNoticeView {
                    env.settingsService.update { $0.privacyAccepted = true }
                    showPrivacyNotice = false
                }
                .interactiveDismissDisabled(true)
            }
            .alert("提示", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if !env.settingsService.settings.privacyAccepted {
                    showPrivacyNotice = true
                }
            }
            .onChange(of: selectedImage) { image in
                guard let image = image else { return }
                Task { await processImage(image) }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var culturalTip: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill").foregroundStyle(.orange)
            Text("建议不要输入真实姓名。本应用仅供娱乐与文化体验用途。")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10).fill(.ultraThinMaterial)
        )
    }

    @ViewBuilder
    private var previewArea: some View {
        ZStack {
            if let image = processedImage ?? selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )

                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.4)
                        VStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("正在识别并生成纸扎效果…")
                                .font(.system(size: 13))
                                .foregroundStyle(.white)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                }
            } else {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.ultraThinMaterial)
                    .frame(height: 260)
                    .overlay(
                        VStack(spacing: 10) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("请选择一张含人像的照片")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        }
                    )
            }
        }
    }

    private var formSection: some View {
        VStack(spacing: 14) {
            HStack {
                Text("名称").font(.system(size: 14, weight: .medium)).frame(width: 50, alignment: .leading)
                TextField("默认：\(PaperEffigyManager.generateDefaultName(existingCount: env.effigyManager.count))", text: $name)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(alignment: .top) {
                Text("备注").font(.system(size: 14, weight: .medium)).frame(width: 50, alignment: .leading).padding(.top, 6)
                if #available(iOS 16.0, *) {
                    TextField("可选（最多 200 字符）", text: $note, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.roundedBorder)
                } else {
                    TextField("可选（最多 200 字符）", text: $note)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14).fill(.ultraThinMaterial)
        )
    }

    private var canSave: Bool {
        (processedImage != nil || selectedImage != nil) &&
        !isProcessing &&
        note.count <= 200 &&
        name.count <= 20
    }

    private func processImage(_ image: UIImage) async {
        isProcessing = true
        defer { isProcessing = false }
        do {
            let subject = try await env.imageProcessor.detectSubject(in: image)
            let cropped: UIImage
            if let rect = subject {
                cropped = env.imageProcessor.crop(image, to: rect)
            } else {
                errorMessage = "未识别到人像，将使用原图。为获得更好效果请选择包含人物的照片。"
                cropped = image
            }
            let styled = try await env.imageProcessor.applyPaperStyle(cropped)
            await MainActor.run { self.processedImage = styled }
        } catch {
            await MainActor.run {
                errorMessage = "处理失败：\(error.localizedDescription)"
                processedImage = image
            }
        }
    }

    private func save() {
        guard env.effigyManager.canCreateMore else {
            errorMessage = "已达到存档上限（10 个）"
            return
        }
        let finalImage = processedImage ?? selectedImage
        do {
            _ = try env.effigyManager.create(
                name: name.isEmpty ? nil : name,
                note: note,
                image: finalImage
            )
            dismiss()
        } catch {
            errorMessage = "保存失败：\(error.localizedDescription)"
        }
    }
}

// MARK: - Privacy Notice

struct PrivacyNoticeView: View {
    let onAgree: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
                .padding(.top, 30)

            Text("隐私保护").font(.system(size: 22, weight: .bold))

            VStack(alignment: .leading, spacing: 10) {
                Text("• 照片与生成结果仅保存在本机或您的 iCloud 中")
                Text("• 不会上传任何服务器，不进行人脸识别数据收集")
                Text("• 您可随时在设置中清除全部数据")
            }
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 24)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    onAgree()
                } label: {
                    Text("同意并继续")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [.orange, Color.red.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                }
                .buttonStyle(.plain)

                Button("取消") { dismiss() }
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
    }
}

// MARK: - Cultural Disclaimer (首启)

struct CulturalDisclaimerView: View {
    let onAccept: () -> Void

    var body: some View {
        ZStack {
            DiffusedBackground(mode: .preset(.warm))

            VStack(spacing: 24) {
                Spacer()
                Image(systemName: "scroll.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                    )

                Text("欢迎使用「打小人」")
                    .font(.system(size: 26, weight: .bold, design: .serif))

                VStack(alignment: .leading, spacing: 14) {
                    bullet("本应用仅供娱乐与文化体验用途")
                    bullet("以现代方式呈现中国传统民俗「打小人」")
                    bullet("所有数据均保存在本机，不上传任何服务器")
                    bullet("请勿对他人使用或用作不良用途")
                }
                .font(.system(size: 14))
                .padding(.horizontal, 32)

                Spacer()

                Button { onAccept() } label: {
                    Text("我已了解")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            Capsule().fill(
                                LinearGradient(colors: [.orange, Color.red.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                            )
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 10)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("·").foregroundStyle(.orange).font(.system(size: 16, weight: .bold))
            Text(text)
        }
    }
}
