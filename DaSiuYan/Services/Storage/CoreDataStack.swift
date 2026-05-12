// CoreDataStack.swift
// 程序化构造 Core Data Model（无需 .momd 编译），支持可选 iCloud 同步。

import Foundation
import CoreData

public final class CoreDataStack {
    public static let shared = CoreDataStack()
    public let container: NSPersistentContainer

    private init() {
        let model = Self.buildModel()
        let useCloud = UserDefaults.standard.bool(forKey: "icloud_sync_enabled")

        if useCloud {
            let c = NSPersistentCloudKitContainer(name: "DaSiuYan", managedObjectModel: model)
            c.persistentStoreDescriptions.first?.setOption(
                true as NSNumber, forKey: NSPersistentHistoryTrackingKey
            )
            container = c
        } else {
            container = NSPersistentContainer(name: "DaSiuYan", managedObjectModel: model)
        }

        // 使用自定义 store URL 避免默认 .momd 查找
        if let desc = container.persistentStoreDescriptions.first {
            let url = Self.storeURL
            desc.url = url
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                print("⚠️ Core Data load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    public var viewContext: NSManagedObjectContext { container.viewContext }

    private static var storeURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("DaSiuYan.sqlite")
    }

    // MARK: - 程序化 Model 定义

    private static func buildModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let effigy = NSEntityDescription()
        effigy.name = "CDPaperEffigy"
        effigy.managedObjectClassName = NSStringFromClass(CDPaperEffigy.self)
        effigy.properties = [
            attr("id", .UUIDAttributeType),
            attr("name", .stringAttributeType, default: ""),
            attr("note", .stringAttributeType, optional: true),
            attr("createdAt", .dateAttributeType),
            attr("imageRelativePath", .stringAttributeType, optional: true),
            attr("damageState", .integer16AttributeType, default: 0),
            attr("strikeCount", .integer32AttributeType, default: 0),
            attr("isArchived", .booleanAttributeType, default: false)
        ]

        let record = NSEntityDescription()
        record.name = "CDCremationRecord"
        record.managedObjectClassName = NSStringFromClass(CDCremationRecord.self)
        record.properties = [
            attr("id", .UUIDAttributeType),
            attr("effigyID", .UUIDAttributeType),
            attr("nameSnapshot", .stringAttributeType, default: ""),
            attr("createdAt", .dateAttributeType),
            attr("blessingText", .stringAttributeType, default: ""),
            attr("diceResult", .stringAttributeType, default: "sacred"),
            attr("strikeCountAtCremation", .integer32AttributeType, default: 0)
        ]

        let inc = NSEntityDescription()
        inc.name = "CDCustomIncantation"
        inc.managedObjectClassName = NSStringFromClass(CDCustomIncantation.self)
        inc.properties = [
            attr("id", .UUIDAttributeType),
            attr("text", .stringAttributeType, default: ""),
            attr("createdAt", .dateAttributeType),
            attr("isInCurrentPool", .booleanAttributeType, default: true)
        ]

        model.entities = [effigy, record, inc]
        return model
    }

    private static func attr(_ name: String, _ type: NSAttributeType, optional: Bool = false, default defaultValue: Any? = nil) -> NSAttributeDescription {
        let a = NSAttributeDescription()
        a.name = name
        a.attributeType = type
        a.isOptional = optional
        if let d = defaultValue { a.defaultValue = d }
        return a
    }
}

// MARK: - NSManagedObject 子类

public final class CDPaperEffigy: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var note: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var imageRelativePath: String?
    @NSManaged public var damageState: Int16
    @NSManaged public var strikeCount: Int32
    @NSManaged public var isArchived: Bool
}

public final class CDCremationRecord: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var effigyID: UUID
    @NSManaged public var nameSnapshot: String
    @NSManaged public var createdAt: Date
    @NSManaged public var blessingText: String
    @NSManaged public var diceResult: String
    @NSManaged public var strikeCountAtCremation: Int32
}

public final class CDCustomIncantation: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var createdAt: Date
    @NSManaged public var isInCurrentPool: Bool
}
