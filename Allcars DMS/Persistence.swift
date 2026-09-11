import CoreData
import CloudKit

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentCloudKitContainer
    let privateStoreURL: URL
    let sharedStoreURL: URL

    private let cloudKitContainerIdentifier = "iCloud.com.Fafa.AllCarsDMS"

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "Allcars_DMS")

        let directory = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )

        privateStoreURL = directory.appendingPathComponent("AllCarsDMS-Private.sqlite")
        sharedStoreURL = directory.appendingPathComponent("AllCarsDMS-Shared.sqlite")

        let privateDescription = Self.storeDescription(
            url: inMemory ? URL(fileURLWithPath: "/dev/null/private") : privateStoreURL,
            containerIdentifier: cloudKitContainerIdentifier,
            scope: .private
        )
        let sharedDescription = Self.storeDescription(
            url: inMemory ? URL(fileURLWithPath: "/dev/null/shared") : sharedStoreURL,
            containerIdentifier: cloudKitContainerIdentifier,
            scope: .shared
        )

        container.persistentStoreDescriptions = [privateDescription, sharedDescription]
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
            print("CloudKit store loaded:", description.url?.lastPathComponent ?? "Unknown")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.transactionAuthor = "AllCarsDMS"
    }

    private static func storeDescription(
        url: URL,
        containerIdentifier: String,
        scope: CKDatabase.Scope
    ) -> NSPersistentStoreDescription {
        let description = NSPersistentStoreDescription(url: url)
        description.type = NSSQLiteStoreType
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        let options = NSPersistentCloudKitContainerOptions(
            containerIdentifier: containerIdentifier
        )
        options.databaseScope = scope
        description.cloudKitContainerOptions = options
        return description
    }

    var privateStore: NSPersistentStore? {
        store(at: privateStoreURL)
    }

    var sharedStore: NSPersistentStore? {
        store(at: sharedStoreURL)
    }

    private func store(at url: URL) -> NSPersistentStore? {
        container.persistentStoreCoordinator.persistentStores.first { $0.url == url }
    }

    @MainActor
    @discardableResult
    func dealership() throws -> Dealership {
        let context = container.viewContext
        let request = Dealership.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
        let dealerships = try context.fetch(request)

        // A participant must work in the accepted shared graph. The original
        // account continues to use its private graph on all of its devices.
        if let sharedStore,
           let accepted = dealerships.first(where: {
               $0.objectID.persistentStore == sharedStore
           }) {
            return accepted
        }

        if let privateStore,
           let owned = dealerships.first(where: {
               $0.objectID.persistentStore == privateStore
           }) {
            try attachOrphanedVehicles(to: owned, in: context)
            return owned
        }

        guard let privateStore else {
            throw PersistenceError.privateStoreUnavailable
        }

        let dealership = Dealership(context: context)
        dealership.id = UUID()
        dealership.name = "All Cars"
        dealership.createdAt = Date()
        context.assign(dealership, to: privateStore)
        try attachOrphanedVehicles(to: dealership, in: context)
        try context.save()
        return dealership
    }

    @MainActor
    private func attachOrphanedVehicles(
        to dealership: Dealership,
        in context: NSManagedObjectContext
    ) throws {
        let request = Vehicle.fetchRequest()
        request.predicate = NSPredicate(format: "dealership == nil")
        let rootStore = dealership.objectID.persistentStore

        for vehicle in try context.fetch(request)
        where vehicle.objectID.persistentStore == rootStore {
            vehicle.dealership = dealership
        }

        if context.hasChanges { try context.save() }
    }

    func sharingInformation(
        for dealership: Dealership,
        completion: @escaping (Result<(CKShare, CKContainer), Error>) -> Void
    ) {
        container.performBackgroundTask { context in
            do {
                let object = try context.existingObject(with: dealership.objectID)
                if let existing = try self.container.fetchShares(
                    matching: [dealership.objectID]
                )[dealership.objectID] {
                    completion(.success((
                        existing,
                        CKContainer(identifier: self.cloudKitContainerIdentifier)
                    )))
                    return
                }

                self.container.share([object], to: nil) {
                    _, share, cloudContainer, error in
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    guard let share, let cloudContainer,
                          let store = dealership.objectID.persistentStore else {
                        completion(.failure(PersistenceError.shareWasNotCreated))
                        return
                    }

                    share[CKShare.SystemFieldKey.title] =
                        (dealership.name ?? "All Cars Dealership") as CKRecordValue
                    share.publicPermission = .none
                    self.container.persistUpdatedShare(share, in: store) {
                        _, updateError in
                        if let updateError {
                            completion(.failure(updateError))
                        } else {
                            completion(.success((share, cloudContainer)))
                        }
                    }
                }
            } catch {
                completion(.failure(error))
            }
        }
    }

    func acceptShareInvitation(
        _ metadata: CKShare.Metadata,
        completion: @escaping (Error?) -> Void = { _ in }
    ) {
        guard let sharedStore else {
            completion(PersistenceError.sharedStoreUnavailable)
            return
        }

        container.acceptShareInvitations(from: [metadata], into: sharedStore) {
            _, error in
            DispatchQueue.main.async {
                if error == nil {
                    NotificationCenter.default.post(
                        name: .dealershipShareAccepted,
                        object: nil
                    )
                }
                completion(error)
            }
        }
    }

    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do { try context.save() }
        catch { print("Core Data save failed:", error.localizedDescription) }
    }
}

enum PersistenceError: LocalizedError {
    case privateStoreUnavailable
    case sharedStoreUnavailable
    case shareWasNotCreated

    var errorDescription: String? {
        switch self {
        case .privateStoreUnavailable: return "The private dealership store is unavailable."
        case .sharedStoreUnavailable: return "The shared dealership store is unavailable."
        case .shareWasNotCreated: return "CloudKit did not create the dealership share."
        }
    }
}

extension Notification.Name {
    static let dealershipShareAccepted = Notification.Name("AllCarsDMS.shareAccepted")
}
