// CustomIncantationEditorView.swift
// 自定义咒语编辑器（最多 20 条，每条 1-60 字符）。
// Requirement 8.6 / 8.9 / 8.10。

import SwiftUI

struct CustomIncantationEditorView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var newText: String = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                VStack(spacing: 16) {
                    GlassmorphicCard(cornerRadius: 18) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("新增咒语")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)
                            if #available(iOS 16.0, *) {
                                TextField("输入咒语文本（1-60 字符）", text: $newText, axis: .vertical)
                                    .lineLimit(2...4)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                TextField("输入咒语文本（1-60 字符）", text: $newText)
                                    .textFieldStyle(.roundedBorder)
                            }

                            HStack {
                                Text("\(newText.count) / 60")
                                    .font(.caption)
                                    .foregroundStyle(newText.count > 60 ? .red : .secondary)
                                Spacer()
                                Button { add() } label: {
                                    Text("添加")
                                        .font(.system(size: 14, weight: .semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .foregroundStyle(.white)
                                        .background(Capsule().fill(canAdd ? Color.orange : Color.gray.opacity(0.5)))
                                }
                                .disabled(!canAdd)
                            }
                        }
                        .padding(14)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    List {
                        Section(header: Text("已有 \(env.incantationSystem.customIncantations.count) / 20 条")) {
                            ForEach(env.incantationSystem.customIncantations) { item in
                                HStack {
                                    Text(item.text).font(.system(size: 14))
                                    Spacer()
                                    Text(item.createdAt, style: .date)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .onDelete(perform: delete)
                        }
                        .listRowBackground(Color.white.opacity(0.08))
                    }
                    .modifier(HiddenListBackground())
                }
            }
            .navigationTitle("自定义咒语")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("提示", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("好") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .navigationViewStyle(.stack)
    }

    private var canAdd: Bool {
        let count = newText.trimmingCharacters(in: .whitespacesAndNewlines).count
        return count >= 1 && count <= 60 && env.incantationSystem.customIncantations.count < 20
    }

    private func add() {
        let trimmed = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        do {
            try env.incantationSystem.addCustom(text: trimmed)
            newText = ""
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func delete(at offsets: IndexSet) {
        for idx in offsets {
            let item = env.incantationSystem.customIncantations[idx]
            try? env.incantationSystem.deleteCustom(id: item.id)
        }
    }
}
