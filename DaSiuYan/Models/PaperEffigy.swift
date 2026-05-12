// PaperEffigy.swift
// 纸片人领域值类型。Demo 阶段使用内存存储（Array + ObservableObject）；
// 生产版应由 Core Data PaperEffigy+CoreData.swift 作为持久化支撑，
// 再通过 `init(managed:)` 与 `toManaged(context:)` 做双向转换。

import Foundation
import SwiftUI

public struct PaperEffigy: Identifiable, Equatable, Hashable {
    public let id: UUID
    public var name: String
    public var note: String
    public let createdAt: Date
    /// Demo 阶段为 nil（使用占位）；生产版为沙盒路径
    public var imageRelativePath: String?
    public var damageState: Int       // 0...100
    public var strikeCount: Int       // 累积打击次数
    public var isArchived: Bool       // 焚化后置 true

    public init(
        id: UUID = UUID(),
        name: String,
        note: String = "",
        createdAt: Date = Date(),
        imageRelativePath: String? = nil,
        damageState: Int = 0,
        strikeCount: Int = 0,
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.note = note
        self.createdAt = createdAt
        self.imageRelativePath = imageRelativePath
        self.damageState = min(100, max(0, damageState))
        self.strikeCount = max(0, strikeCount)
        self.isArchived = isArchived
    }

    /// 返回新值：钳制 damageState 到 [0, 100] 并累加打击次数，满足 Property 7（单调非降）
    public func registeringStrike(addDamage: Int) -> PaperEffigy {
        var copy = self
        copy.damageState = min(100, copy.damageState + max(0, addDamage))
        copy.strikeCount += 1
        return copy
    }
}

// MARK: - Demo 示例数据

public extension PaperEffigy {
    static let sample = PaperEffigy(
        name: "小人甲",
        note: "示例纸片人",
        damageState: 0,
        strikeCount: 0
    )

    static let samples: [PaperEffigy] = [
        PaperEffigy(name: "小人甲"),
        PaperEffigy(name: "小人乙", damageState: 40, strikeCount: 12),
        PaperEffigy(name: "小人丙", damageState: 80, strikeCount: 45)
    ]
}
