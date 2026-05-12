// KnowledgeTabView.swift
// 传统知识栏目：4 个子条目 + 详情页。
// Requirement 11 / 16.2。

import SwiftUI

struct KnowledgeArticle: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let subtitle: String
    let body: String
}

enum KnowledgeLibrary {
    static let articles: [KnowledgeArticle] = [
        KnowledgeArticle(
            title: "习俗介绍",
            icon: "book.pages.fill",
            subtitle: "以打击纸扎人形象征性祛除霉运",
            body: """
            「打小人」是流行于中国广东、香港地区的传统民俗。人们相信通过打击纸扎人偶，可以象征性地驱赶身边的"小人"——指那些带来麻烦、传播是非的人。

            仪式通常包括：
            · 准备纸扎小人（白虎纸、小人纸等）
            · 由神婆或本人持鞋拍打
            · 口诵打小人口诀
            · 最后焚化纸人「送走」

            这是一种民间心理解压与情绪释放的方式，富有浓郁的市井文化气息。
            """
        ),
        KnowledgeArticle(
            title: "地区分布",
            icon: "map.fill",
            subtitle: "岭南地区为盛，香港最具代表",
            body: """
            · 香港铜锣湾鹅颈桥下是最著名的"打小人"圣地，每逢惊蛰前后尤为热闹
            · 广州、佛山、东莞等粤语地区民间亦有流传
            · 部分东南亚华人社区（新加坡、马来西亚）保留此俗
            · 2014 年香港打小人被列入非物质文化遗产名录

            各地在仪式细节、咒语念诵上略有差异，但核心结构一致。
            """
        ),
        KnowledgeArticle(
            title: "历史沿革",
            icon: "scroll.fill",
            subtitle: "源自古代祭白虎与驱邪仪式",
            body: """
            · 起源可追溯至古代祭白虎习俗。白虎为主凶星，主口舌是非
            · 《周礼》已有惊蛰日驱虫除害的记载
            · 明清时期民间将白虎祭祀与驱小人结合，发展为今天的形态
            · 20 世纪中后期在港澳、珠三角民间广泛流传并世俗化
            · 现多作为节日体验与心理疏导活动存在

            打小人体现了中国民间对"和谐"与"邪祟远离"的朴素追求。
            """
        ),
        KnowledgeArticle(
            title: "注意事项与禁忌",
            icon: "exclamationmark.triangle.fill",
            subtitle: "本应用仅供娱乐与文化体验用途",
            body: """
            使用本应用时，请注意：

            · 建议不要输入真实姓名
            · 请勿针对具体人身信息进行打击
            · 本应用仅为文化体验与情绪解压用途，非迷信工具
            · 请保持理性，不要将其作为处理人际关系的方式
            · 尊重传统民俗，不以此取笑或伤害他人
            · 若对他人心存不满，建议采取沟通或其他积极方式

            传统民俗本质上是人们对美好生活的一种心理寄托。
            """
        )
    ]
}

struct KnowledgeTabView: View {
    @EnvironmentObject private var env: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                DiffusedBackground(mode: env.backgroundSystem.current)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(KnowledgeLibrary.articles) { article in
                            NavigationLink {
                                ArticleDetailView(article: article)
                                    .environmentObject(env)
                            } label: {
                                articleRow(article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("传统知识")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private func articleRow(_ article: KnowledgeArticle) -> some View {
        GlassmorphicCard(cornerRadius: 18) {
            HStack(spacing: 14) {
                Image(systemName: article.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.orange)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.orange.opacity(0.15)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(article.title).font(.system(size: 16, weight: .semibold))
                    Text(article.subtitle)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding(16)
        }
    }
}

struct ArticleDetailView: View {
    @EnvironmentObject private var env: AppEnvironment
    let article: KnowledgeArticle

    var body: some View {
        ZStack {
            DiffusedBackground(mode: env.backgroundSystem.current)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 14) {
                        Image(systemName: article.icon)
                            .font(.system(size: 36))
                            .foregroundStyle(
                                LinearGradient(colors: [.orange, .red], startPoint: .top, endPoint: .bottom)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.title)
                                .font(.system(size: 24, weight: .bold, design: .serif))
                            Text(article.subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(.secondary)
                        }
                    }

                    GlassmorphicCard(cornerRadius: 16) {
                        Text(article.body)
                            .font(.system(size: 15))
                            .lineSpacing(8)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
