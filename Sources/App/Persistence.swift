import Foundation
import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // Transformable 用の安全なアンアーカイブトランスフォーマを明示登録（保険）
        ValueTransformer.setValueTransformer(
            NSSecureUnarchiveFromDataTransformer(),
            forName: NSValueTransformerName("NSSecureUnarchiveFromDataTransformer")
        )

        // 明示的に .momd を読み込み、フレームワーク内部の名前解決問題を回避
        let model: NSManagedObjectModel = {
            let main = Bundle.main
            if let url = main.url(forResource: "DiaryPaymentsApp", withExtension: "momd") ??
                         main.url(forResource: "DiaryPaymentsApp", withExtension: "mom"),
               let objModel = NSManagedObjectModel(contentsOf: url) {
                return objModel
            }
            // フォールバック: マージドモデル or 空モデル
            if let merged = NSManagedObjectModel.mergedModel(from: [main]) {
                return merged
            }
            assertionFailure("Core Data model not found in main bundle; using empty model as fallback")
            return NSManagedObjectModel()
        }()

        container = NSPersistentContainer(name: "DiaryPaymentsApp", managedObjectModel: model)

        // ストアURLを明示し、軽量マイグレーションを有効化
        let storeDescription: NSPersistentStoreDescription
        if let first = container.persistentStoreDescriptions.first {
            storeDescription = first
        } else {
            storeDescription = NSPersistentStoreDescription()
        }

        if !inMemory {
            // Application Support/DiaryPaymentsApp.sqlite に保存
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let directory = appSupport.appendingPathComponent("DiaryPaymentsApp", isDirectory: true)
            try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let url = directory.appendingPathComponent("DiaryPaymentsApp.sqlite")
            storeDescription.url = url
        }
        storeDescription.shouldMigrateStoreAutomatically = true
        storeDescription.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [storeDescription]
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { [weak container] _, error in
            guard let error = error as NSError? else { return }
            assertionFailure("Core Data store load error: \(error), \(error.userInfo)")

            // 可能な限り自動回復: 破損/非互換ストアを削除して再試行
            if let url = storeDescription.url {
                let fm = FileManager.default
                let wal = url.deletingPathExtension().appendingPathExtension("sqlite-wal")
                let shm = url.deletingPathExtension().appendingPathExtension("sqlite-shm")
                _ = try? fm.removeItem(at: url)
                _ = try? fm.removeItem(at: wal)
                _ = try? fm.removeItem(at: shm)
            }

            container?.persistentStoreDescriptions = [storeDescription]
            container?.loadPersistentStores { _, retryError in
                if let retryError = retryError as NSError? {
                    assertionFailure("Core Data retry load failed: \(retryError), \(retryError.userInfo)")
                    // 最終手段: インメモリで起動継続（データは保持されない）
                    let mem = NSPersistentStoreDescription()
                    mem.type = NSInMemoryStoreType
                    self.container.persistentStoreDescriptions = [mem]
                    self.container.loadPersistentStores { _, _ in }
                }
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            assertionFailure("Core Data save error: \(nserror), \(nserror.userInfo)")
        }
    }
}


