// PaperEffigyManager.swift
// 纸片人 CRUD + 默认命名 + 10 存档上限。
// Requirement 1 / 2。

import Foundation
import UIKit

@MainActor
public final class PaperEffigyManager: ObservableObject {

    @Published public private(set) var effigies: [PaperEffigy] = []

    public var count: Int { effigies.count }
    public var canCreateMore: Bool { count < 10 }

    private let storage: StorageServicing

    public init(storage: StorageServicing) {
        self.storage = storage
        refresh()
    }

    // MARK: - 默认命名（Property 1）

    private static let chineseOrdinals: [String] = [
        "甲", "乙", "丙", "丁", "戊", "己", "庚", "辛", "壬", "癸"
    ]

    public static func generateDefaultName(existingCount: Int) -> String {
        if existingCount < chineseOrdinals.count {
            return "小人" + chineseOrdinals[existingCount]
        }
        return "小人 \(existingCount + 1)"
    }

    public func refresh() {
        effigies = (try? storage.fetchAllEffigies()) ?? []
    }

    @discardableResult
    public func create(name customName: String? = nil, note: String = "", image: UIImage?) throws -> PaperEffigy {
        guard canCreateMore else { throw StorageError.effigyCapReached }
        let finalName = (customName?.isEmpty == false ? customName! : Self.generateDefaultName(existingCount: count))
        let effigy = PaperEffigy(name: finalName, note: note)
        let saved = try storage.saveEffigy(effigy, image: image)
        effigies.insert(saved, at: 0)
        return saved
    }

    public func update(_ effigy: PaperEffigy) throws {
        try storage.updateEffigy(effigy)
        if let idx = effigies.firstIndex(where: { $0.id == effigy.id }) {
            effigies[idx] = effigy
        }
    }

    public func delete(id: UUID) throws {
        try storage.deleteEffigy(id: id)
        effigies.removeAll { $0.id == id }
    }

    public func markArchived(id: UUID) throws {
        try storage.markEffigyArchived(id: id)
        effigies.removeAll { $0.id == id }
    }

    public func clearAll() throws {
        try storage.clearAll()
        effigies = []
    }
}
