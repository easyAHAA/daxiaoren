// CremationHistoryView.swift
// 焚化历史记录列表 + 详情。
// Requirement 10。

import SwiftUI

struct CremationHistoryView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    @State private var records: [CremationRecord] = []
    @State private var selected: CremationRecord?

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                if records.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 56))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("尚无焚化记录").font(.system(size: 16, weight: .medium))
                        Text("完成焚化仪式后，记录会显示在这里")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(records) { record in
                                Button {
                                    selected = record
                                } label: {
                                    recordCard(record)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("焚化历史")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear { reload() }
            .sheet(item: $selected) { record in
                CremationDetailView(record: record, onDelete: {
                    try? env.storage.deleteCremation(id: record.id)
                    selected = nil
                    reload()
                })
                .environmentObject(env)
            }
        }
        .navigationViewStyle(.stack)
    }

    private func reload() {
        records = (try? env.storage.fetchAllCremations()) ?? []
    }

    private func recordCard(_ record: CremationRecord) -> some View {
        GlassmorphicCard(cornerRadius: 18) {
            HStack(spacing: 14) {
                VStack(spacing: 2) {
                    Text(diceShort(record.dice))
                        .font(.system(size: 26, weight: .black, design: .serif))
                        .foregroundStyle(diceColor(record.dice))
                    Text(record.dice.chineseName)
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(record.nameSnapshot).font(.system(size: 16, weight: .semibold))
                    Text(record.blessingText)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    HStack(spacing: 10) {
                        Label("\(record.strikeCountAtCremation)", systemImage: "hand.tap")
                            .font(.caption2)
                        Text(record.createdAt, style: .date).font(.caption2)
                    }
                    .foregroundStyle(.tertiary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(14)
        }
    }

    private func diceShort(_ d: DiceResult) -> String {
        switch d {
        case .sacred: return "圣"
        case .laughing: return "笑"
        case .yin: return "阴"
        }
    }

    private func diceColor(_ d: DiceResult) -> Color {
        switch d {
        case .sacred: return .orange
        case .laughing: return .yellow
        case .yin: return .gray
        }
    }
}

struct CremationDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss
    let record: CremationRecord
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: .preset(.nightLamp))

                ScrollView {
                    VStack(spacing: 20) {
                        Text(record.nameSnapshot)
                            .font(.system(size: 20, weight: .bold))
                            .padding(.top, 16)

                        GlassmorphicCard(cornerRadius: 22) {
                            VStack(spacing: 16) {
                                Text("掷筊结果").font(.system(size: 13)).foregroundStyle(.secondary)
                                Text(record.dice.chineseName)
                                    .font(.system(size: 54, weight: .black, design: .serif))
                                    .foregroundStyle(
                                        LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                                    )
                                Text(record.dice.subtitle).font(.system(size: 14, weight: .semibold))

                                Divider().background(.white.opacity(0.2))

                                Text(record.blessingText)
                                    .font(.system(size: 15))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 10)

                                Divider().background(.white.opacity(0.2))

                                HStack(spacing: 30) {
                                    VStack {
                                        Text("打击次数").font(.caption).foregroundStyle(.secondary)
                                        Text("\(record.strikeCountAtCremation)").font(.system(size: 17, weight: .semibold))
                                    }
                                    VStack {
                                        Text("焚化时间").font(.caption).foregroundStyle(.secondary)
                                        Text(record.createdAt, style: .date).font(.system(size: 13))
                                    }
                                }
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("焚化详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash").foregroundStyle(.red)
                    }
                }
            }
            .alert("删除此条记录？", isPresented: $showDeleteConfirm) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    onDelete()
                    dismiss()
                }
            } message: {
                Text("此操作不可恢复")
            }
        }
        .navigationViewStyle(.stack)
    }
}
