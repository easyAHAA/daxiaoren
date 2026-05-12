// StorageService.swift
// 持久化服务 — Core Data CRUD + 沙盒图片文件管理。
// Requirement 2 / 3 / 9.12 / 9.14 / 10。

import Foundation
import UIKit
import CoreData

public struct CremationRecord: Identifiable, Equatable {
    public let id: UUID
    public let effigyID: UUID
    public let nameSnapshot: String
    public let createdAt: Date
    public let blessingText: String
    public let dice: DiceResult
    public let strikeCountAtCremation: Int

    public init(id: UUID = UUID(), effigyID: UUID, nameSnapshot: String,
                createdAt: Date = Date(), blessingText: String, dice: DiceResult,
                strikeCountAtCremation: Int) {
        self.id = id
        self.effigyID = effigyID
        self.nameSnapshot = nameSnapshot
        self.createdAt = createdAt
        self.blessingText = blessingText
        self.dice = dice
        self.strikeCountAtCremation = strikeCountAtCremation
    }
}

public struct CustomIncantation: Identifiable, Equatable, Hashable {
    public let id: UUID
    public let text: String
    public let createdAt: Date
    public let isInCurrentPool: Bool

    public init(id: UUID = UUID(), text: String, createdAt: Date = Date(), isInCurrentPool: Bool = true) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.isInCurrentPool = isInCurrentPool
    }
}

public enum StorageError: Error, LocalizedError {
    case nameInvalid
    case noteInvalid
    case customIncantationInvalid
    case customIncantationCapReached
    case effigyCapReached
    case notFound

    public var errorDescription: String? {
        switch self {
        case .nameInvalid: return "名称长度须在 1 到 20 个字符之间"
        case .noteInvalid: return "备注不能超过 200 个字符"
        case .customIncantationInvalid: return "咒语长度须在 1 到 60 个字符之间"
        case .customIncantationCapReached: return "已达到自定义咒语上限（20 条）"
        case .effigyCapReached: return "已达到存档上限（10 个）"
        case .notFound: return "未找到数据"
        }
    }
}

public protocol StorageServicing: AnyObject {
    func fetchAllEffigies() throws -> [PaperEffigy]
    func saveEffigy(_ effigy: PaperEffigy, image: UIImage?) throws -> PaperEffigy
    func updateEffigy(_ effigy: PaperEffigy) throws
    func deleteEffigy(id: UUID) throws

    func saveCremationRecord(_ record: CremationRecord) throws
    func markEffigyArchived(id: UUID) throws
    func fetchAllCremations() throws -> [CremationRecord]
    func deleteCremation(id: UUID) throws

    func fetchCustomIncantations() throws -> [CustomIncantation]
    func saveCustomIncantation(text: String) throws -> CustomIncantation
    func deleteCustomIncantation(id: UUID) throws

    func loadImage(relativePath: String) -> UIImage?
    func saveBackgroundImage(_ image: UIImage) throws -> String

    func clearAll() throws
}

public final class StorageService: StorageServicing {
    private let stack: CoreDataStack
    private let fileManager = FileManager.default

    public init(stack: CoreDataStack = .shared) {
        self.stack = stack
        ensureDirectories()
    }

    private lazy var documentsURL: URL = {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }()
    private var effigiesDir: URL { documentsURL.appendingPathComponent("Effigies", isDirectory: true) }
    private var backgroundsDir: URL { documentsURL.appendingPathComponent("Backgrounds", isDirectory: true) }

    private func ensureDirectories() {
        for dir in [effigiesDir, backgroundsDir] {
            try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Paper Effigy

    public func fetchAllEffigies() throws -> [PaperEffigy] {
        let req = NSFetchRequest<CDPaperEffigy>(entityName: "CDPaperEffigy")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        req.predicate = NSPredicate(format: "isArchived == NO")
        let items = try stack.viewContext.fetch(req)
        return items.map { $0.toDomain() }
    }

    public func saveEffigy(_ effigy: PaperEffigy, image: UIImage?) throws -> PaperEffigy {
        guard (1...20).contains(effigy.name.count) else { throw StorageError.nameInvalid }
        guard effigy.note.count <= 200 else { throw StorageError.noteInvalid }

        var relPath: String? = effigy.imageRelativePath
        if let image = image {
            let url = effigiesDir.appendingPathComponent("\(effigy.id.uuidString).jpg")
            if let data = image.jpegData(compressionQuality: 0.85) {
                try data.write(to: url, options: .atomic)
                relPath = "Effigies/\(effigy.id.uuidString).jpg"
            }
        }

        let ctx = stack.viewContext
        let cd = CDPaperEffigy(context: ctx)
        cd.id = effigy.id
        cd.name = effigy.name
        cd.note = effigy.note
        cd.createdAt = effigy.createdAt
        cd.damageState = Int16(effigy.damageState)
        cd.strikeCount = Int32(effigy.strikeCount)
        cd.isArchived = effigy.isArchived
        cd.imageRelativePath = relPath
        try ctx.save()

        var result = effigy
        result.imageRelativePath = relPath
        return result
    }

    public func updateEffigy(_ effigy: PaperEffigy) throws {
        guard (1...20).contains(effigy.name.count) else { throw StorageError.nameInvalid }
        guard effigy.note.count <= 200 else { throw StorageError.noteInvalid }

        let ctx = stack.viewContext
        guard let cd = try fetchCD(id: effigy.id, in: ctx) else { throw StorageError.notFound }
        cd.name = effigy.name
        cd.note = effigy.note
        cd.damageState = Int16(effigy.damageState)
        cd.strikeCount = Int32(effigy.strikeCount)
        cd.isArchived = effigy.isArchived
        try ctx.save()
    }

    public func deleteEffigy(id: UUID) throws {
        let ctx = stack.viewContext
        guard let cd = try fetchCD(id: id, in: ctx) else { throw StorageError.notFound }
        if let rel = cd.imageRelativePath {
            let url = documentsURL.appendingPathComponent(rel)
            try? fileManager.removeItem(at: url)
        }
        ctx.delete(cd)
        try ctx.save()
    }

    private func fetchCD(id: UUID, in ctx: NSManagedObjectContext) throws -> CDPaperEffigy? {
        let req = NSFetchRequest<CDPaperEffigy>(entityName: "CDPaperEffigy")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try ctx.fetch(req).first
    }

    // MARK: - Cremation

    public func saveCremationRecord(_ record: CremationRecord) throws {
        let ctx = stack.viewContext
        let cd = CDCremationRecord(context: ctx)
        cd.id = record.id
        cd.effigyID = record.effigyID
        cd.nameSnapshot = record.nameSnapshot
        cd.createdAt = record.createdAt
        cd.blessingText = record.blessingText
        cd.diceResult = record.dice.rawValue
        cd.strikeCountAtCremation = Int32(record.strikeCountAtCremation)
        try ctx.save()
    }

    public func markEffigyArchived(id: UUID) throws {
        let ctx = stack.viewContext
        guard let cd = try fetchCD(id: id, in: ctx) else { throw StorageError.notFound }
        cd.isArchived = true
        try ctx.save()
    }

    public func fetchAllCremations() throws -> [CremationRecord] {
        let req = NSFetchRequest<CDCremationRecord>(entityName: "CDCremationRecord")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let items = try stack.viewContext.fetch(req)
        return items.map { cd in
            CremationRecord(
                id: cd.id,
                effigyID: cd.effigyID,
                nameSnapshot: cd.nameSnapshot,
                createdAt: cd.createdAt,
                blessingText: cd.blessingText,
                dice: DiceResult(rawValue: cd.diceResult) ?? .sacred,
                strikeCountAtCremation: Int(cd.strikeCountAtCremation)
            )
        }
    }

    public func deleteCremation(id: UUID) throws {
        let ctx = stack.viewContext
        let req = NSFetchRequest<CDCremationRecord>(entityName: "CDCremationRecord")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        if let cd = try ctx.fetch(req).first {
            ctx.delete(cd)
            try ctx.save()
        }
    }

    // MARK: - Custom Incantation

    public func fetchCustomIncantations() throws -> [CustomIncantation] {
        let req = NSFetchRequest<CDCustomIncantation>(entityName: "CDCustomIncantation")
        req.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        let items = try stack.viewContext.fetch(req)
        return items.map {
            CustomIncantation(id: $0.id, text: $0.text, createdAt: $0.createdAt, isInCurrentPool: $0.isInCurrentPool)
        }
    }

    public func saveCustomIncantation(text: String) throws -> CustomIncantation {
        guard (1...60).contains(text.count) else { throw StorageError.customIncantationInvalid }
        let existing = try fetchCustomIncantations()
        guard existing.count < 20 else { throw StorageError.customIncantationCapReached }

        let ctx = stack.viewContext
        let cd = CDCustomIncantation(context: ctx)
        let new = CustomIncantation(text: text)
        cd.id = new.id
        cd.text = text
        cd.createdAt = new.createdAt
        cd.isInCurrentPool = true
        try ctx.save()
        return new
    }

    public func deleteCustomIncantation(id: UUID) throws {
        let ctx = stack.viewContext
        let req = NSFetchRequest<CDCustomIncantation>(entityName: "CDCustomIncantation")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        if let cd = try ctx.fetch(req).first {
            ctx.delete(cd)
            try ctx.save()
        }
    }

    // MARK: - Images

    public func loadImage(relativePath: String) -> UIImage? {
        guard !relativePath.isEmpty else { return nil }
        let url = documentsURL.appendingPathComponent(relativePath)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    public func saveBackgroundImage(_ image: UIImage) throws -> String {
        let name = "\(UUID().uuidString).jpg"
        let url = backgroundsDir.appendingPathComponent(name)
        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw StorageError.notFound
        }
        try data.write(to: url, options: .atomic)
        return "Backgrounds/\(name)"
    }

    public func clearAll() throws {
        let ctx = stack.viewContext
        for entity in ["CDPaperEffigy", "CDCremationRecord", "CDCustomIncantation"] {
            let req = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let del = NSBatchDeleteRequest(fetchRequest: req)
            _ = try? ctx.execute(del)
        }
        try ctx.save()

        for dir in [effigiesDir, backgroundsDir] {
            if let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files { try? fileManager.removeItem(at: f) }
            }
        }
    }
}

extension CDPaperEffigy {
    func toDomain() -> PaperEffigy {
        PaperEffigy(
            id: id,
            name: name,
            note: note ?? "",
            createdAt: createdAt,
            imageRelativePath: imageRelativePath,
            damageState: Int(damageState),
            strikeCount: Int(strikeCount),
            isArchived: isArchived
        )
    }
}
