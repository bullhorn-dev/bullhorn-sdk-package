import CoreData


protocol SyncDelegate: AnyObject {
    /// Called before the JSON is used to create a new NSManagedObject.
    ///
    /// - parameter sync:        The Sync operation.
    /// - parameter json:        The JSON used for filling the contents of the NSManagedObject.
    /// - parameter entityNamed: The name of the entity to be created.
    /// - parameter parent:      The new item's parent. Do not mutate the contents of this element.
    ///
    /// - returns: The JSON used to create the new NSManagedObject.
    func sync(_ sync: Sync, willInsert json: [String: Any], in entityNamed: String, parent: NSManagedObject?) -> [String: Any]
}

@objcMembers
@objc class Sync: Operation {
    
    weak var delegate: SyncDelegate?

    struct OperationOptions: OptionSet {
        let rawValue: Int

        init(rawValue: Int) {
            self.rawValue = rawValue
        }

        static let insert = OperationOptions(rawValue: 1 << 0)
        static let update = OperationOptions(rawValue: 1 << 1)
        static let delete = OperationOptions(rawValue: 1 << 2)
        static let insertRelationships = OperationOptions(rawValue: 1 << 3)
        static let updateRelationships = OperationOptions(rawValue: 1 << 4)
        static let deleteRelationships = OperationOptions(rawValue: 1 << 5)
        static let all: OperationOptions = [.insert, .update, .delete, .insertRelationships, .updateRelationships, .deleteRelationships]

        func relationshipOperations() -> OperationOptions {
            var options = OperationOptions.all

            if !self.contains(.insertRelationships) {
                options.remove(.insert)
            }

            if !self.contains(.updateRelationships) {
                options.remove(.update)
            }

            if !self.contains(.deleteRelationships) {
                options.remove(.delete)
            }

            return options
        }
    }

    var downloadFinished = false
    var downloadExecuting = false
    var downloadCancelled = false

    override var isFinished: Bool {
        return self.downloadFinished
    }

    override var isExecuting: Bool {
        return self.downloadExecuting
    }

    override var isCancelled: Bool {
        return self.downloadCancelled
    }

    override var isAsynchronous: Bool {
        return !TestCheck.isTesting
    }

    var changes: [[String: Any]]
    var entityName: String
    var predicate: NSPredicate?
    var filterOperations = Sync.OperationOptions.all
    var parent: NSManagedObject?
    var parentRelationship: NSRelationshipDescription?
    var context: NSManagedObjectContext?
    unowned var dataStack: DataStack

    init(changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate? = nil, parent: NSManagedObject? = nil, parentRelationship: NSRelationshipDescription? = nil, context: NSManagedObjectContext? = nil, dataStack: DataStack, operations: Sync.OperationOptions = .all) {
        self.changes = changes
        self.entityName = entityName
        self.predicate = predicate
        self.parent = parent
        self.parentRelationship = parentRelationship
        self.context = context
        self.dataStack = dataStack
        self.filterOperations = operations
    }

    func updateExecuting(_ isExecuting: Bool) {
        self.willChangeValue(forKey: "isExecuting")
        self.downloadExecuting = isExecuting
        self.didChangeValue(forKey: "isExecuting")
    }

    func updateFinished(_ isFinished: Bool) {
        self.willChangeValue(forKey: "isFinished")
        self.downloadFinished = isFinished
        self.didChangeValue(forKey: "isFinished")
    }

    override func start() {
        if self.isCancelled {
            self.updateExecuting(false)
            self.updateFinished(true)
        } else {
            self.updateExecuting(true)
            if let context = self.context {
                context.perform {
                    self.perform(using: context)
                }
            } else {
                self.dataStack.performInNewBackgroundContext { backgroundContext in
                    self.perform(using: backgroundContext)
                }
            }
        }
    }

    func perform(using context: NSManagedObjectContext) {
        do {
            try Sync.changes(self.changes, inEntityNamed: self.entityName, predicate: self.predicate, parent: self.parent, parentRelationship: self.parentRelationship, inContext: context, operations: self.filterOperations, shouldContinueBlock: { () -> Bool in
                return !self.isCancelled
            }, objectJSONBlock: { objectJSON -> [String: Any] in
                return self.delegate?.sync(self, willInsert: objectJSON, in: self.entityName, parent: self.parent) ?? objectJSON
            })
        } catch let error as NSError {
            print("Failed syncing changes \(error)")
        }

        self.updateExecuting(false)
        self.updateFinished(true)
    }

    override func cancel() {
        func updateCancelled(_ isCancelled: Bool) {
            self.willChangeValue(forKey: "isCancelled")
            self.downloadCancelled = isCancelled
            self.didChangeValue(forKey: "isCancelled")
        }

        updateCancelled(true)
    }

    class func changes(_ changes: [[String: Any]], inEntityNamed entityName: String, predicate: NSPredicate?, parent: NSManagedObject?, parentRelationship: NSRelationshipDescription?, inContext context: NSManagedObjectContext, operations: Sync.OperationOptions, shouldContinueBlock: (() -> Bool)?, objectJSONBlock: ((_ objectJSON: [String: Any]) -> [String: Any])?) throws {
        guard let entity = NSEntityDescription.entity(forEntityName: entityName, in: context) else { fatalError("Entity named \(entityName) not found.") }

        let localPrimaryKey = entity.sync_localPrimaryKey()
        let remotePrimaryKey = entity.sync_remotePrimaryKey()
        let shouldLookForParent = parent == nil && predicate == nil

        var finalPredicate = predicate
        if let parentEntity = entity.sync_parentEntity(), shouldLookForParent {
            finalPredicate = NSPredicate(format: "%K = nil", parentEntity.name)
        }

        if localPrimaryKey.isEmpty {
            fatalError("Local primary key not found for entity: \(entityName), add a primary key named id or mark an existing attribute using sync.isPrimaryKey")
        }

        if remotePrimaryKey.isEmpty {
            fatalError("Remote primary key not found for entity: \(entityName), we were looking for id, if your remote ID has a different name consider using sync.remoteKey to map to the right value")
        }

        let dataFilterOperations = DataFilter.Operation(rawValue: operations.rawValue)
        DataFilter.changes(changes, inEntityNamed: entityName, predicate: finalPredicate, operations: dataFilterOperations, localPrimaryKey: localPrimaryKey, remotePrimaryKey: remotePrimaryKey, context: context, inserted: { JSON in
            let shouldContinue = shouldContinueBlock?() ?? true
            guard shouldContinue else { return }

            let created = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
            let interceptedJSON = objectJSONBlock?(JSON) ?? JSON
            created.sync_fill(with: interceptedJSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
        }) { JSON, updatedObject in
            let shouldContinue = shouldContinueBlock?() ?? true
            guard shouldContinue else { return }

            updatedObject.sync_fill(with: JSON, parent: parent, parentRelationship: parentRelationship, context: context, operations: operations, shouldContinueBlock: shouldContinueBlock, objectJSONBlock: objectJSONBlock)
        }
        
        // We have inserted, updated, and deleted objects. Now lets put them in the correct order if appropriate.
        if let parentRelationship = parentRelationship, parentRelationship.isOrdered, let parent = parent, let objects = parent.value(forKey: parentRelationship.name) as? NSOrderedSet {
            let changeIDs = (changes as NSArray).value(forKey: parentRelationship.destinationEntity!.sync_remotePrimaryKey()) as! NSArray
            
            for case let safeObject as NSManagedObject in objects.array {
                let currentID = safeObject.value(forKey: safeObject.entity.sync_localPrimaryKey())!
                let remoteIndex = changeIDs.index(of: currentID)
                let relatedObjects = parent.mutableOrderedSetValue(forKey: parentRelationship.name)
                
                let currentIndex = relatedObjects.index(of: safeObject)
                if currentIndex != remoteIndex && currentIndex != NSNotFound && currentIndex < relatedObjects.count && remoteIndex < relatedObjects.count {
                    relatedObjects.moveObjects(at: IndexSet(integer: currentIndex), to: remoteIndex)
                }
            }
        }

        if context.hasChanges {
            let shouldContinue = shouldContinueBlock?() ?? true
            if shouldContinue {
                try context.save()
            } else {
                context.reset()
            }
        }
    }

    class func verifyContextSafety(context: NSManagedObjectContext) {
        if Thread.isMainThread && context.concurrencyType == .privateQueueConcurrencyType {
            fatalError("Background context used in the main thread. Use context's `perform` method")
        }

        if !Thread.isMainThread && context.concurrencyType == .mainQueueConcurrencyType {
            fatalError("Main context used in a background thread. Use context's `perform` method.")
        }
    }
}
