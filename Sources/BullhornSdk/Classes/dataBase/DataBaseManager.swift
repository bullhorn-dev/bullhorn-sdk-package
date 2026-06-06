import Foundation
import UIKit
import CoreData

class DataBaseManager {

    // MARK: - Properties

    static let shared: DataBaseManager = DataBaseManager()

    let dataStack: DataStack

    init() {
        self.dataStack = DataStack(modelName: "Bullhorn", bundle: Bundle.module, storeType: .sqLite)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Background write helper

    /// Runs `work` on a fresh background context. The context-based Sync helpers
    /// save the context themselves; that save merges into `viewContext` via
    /// DATAStack's `backgroundContextDidSave` observer.
    private func performWrite(_ work: @escaping (NSManagedObjectContext) throws -> Void) {
        dataStack.performInNewBackgroundContext { context in
            do {
                try work(context)
            } catch {
                BHLog.w("DataBaseManager background write failed - \(error)")
            }
        }
    }

    // MARK: - Background read helpers

    /// Reads a single record by `id` and runs the MO→value-type conversion (`map`) on a
    /// background context, then delivers the value-type result on the main queue. The
    /// relationship faulting and conversion (e.g. `toUsers()`/`toPosts()`) happen off the
    /// main thread, so large cached lists no longer block the UI. Uses the object's
    /// permanent ID, so it makes no entity/primary-key assumptions.
    private func backgroundRead<Result>(
        _ id: Any,
        entityName: String,
        empty: Result,
        map: @escaping (NSManagedObject) -> Result,
        completion: @escaping (Result) -> Void
    ) {
        var objectID: NSManagedObjectID?
        do {
            objectID = try dataStack.fetch(id, inEntityNamed: entityName)?.objectID
        } catch {
            BHLog.w("\(#function) - \(error)")
        }
        guard let oid = objectID else {
            completion(empty)
            return
        }
        dataStack.performInNewBackgroundContext { context in
            let result: Result
            if let mo = try? context.existingObject(with: oid) {
                result = map(mo)
            } else {
                result = empty
            }
            DispatchQueue.main.async { completion(result) }
        }
    }

    /// Background read that prefetches the given to-many relationships, collapsing N+1
    /// fault storms into a couple of queries. Used for large lists. Assumes the entity's
    /// primary-key attribute is `id` (true for the cached container entities).
    private func backgroundReadPrefetching<Result>(
        _ id: String,
        entityName: String,
        prefetch: [String],
        empty: Result,
        map: @escaping (NSManagedObject) -> Result,
        completion: @escaping (Result) -> Void
    ) {
        dataStack.performInNewBackgroundContext { context in
            let request = NSFetchRequest<NSManagedObject>(entityName: entityName)
            request.predicate = NSPredicate(format: "id == %@", id)
            request.fetchLimit = 1
            request.relationshipKeyPathsForPrefetching = prefetch
            let mo = (try? context.fetch(request))?.first
            let result = mo.map(map) ?? empty
            DispatchQueue.main.async { completion(result) }
        }
    }

    // MARK: - Network Featured Users

    func fetchNetworkFeaturedUsers(with id: String, completion: @escaping (BHServerApiFeed.UsersResult) -> Void) {
        backgroundRead(id, entityName: NetworkFeaturedUsersMO.entityName,
                       empty: BHServerApiFeed.UsersResult.success(users: []),
                       map: { .success(users: ($0 as? NetworkFeaturedUsersMO)?.toUsers() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateNetworkFeaturedUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: NetworkFeaturedUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Network Featured Posts

    func fetchNetworkFeaturedPosts(with id: String, completion: @escaping (BHServerApiFeed.PostsResult) -> Void) {
        backgroundRead(id, entityName: NetworkFeaturedPostsMO.entityName,
                       empty: BHServerApiFeed.PostsResult.success(posts: []),
                       map: { .success(posts: ($0 as? NetworkFeaturedPostsMO)?.toPosts() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateNetworkFeaturedPosts(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: NetworkFeaturedPostsMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Network Channels

    func fetchChannels(with id: String, completion: @escaping (BHServerApiNetwork.ChannelsResult) -> Void) {
        backgroundRead(id, entityName: ChannelsMO.entityName,
                       empty: BHServerApiNetwork.ChannelsResult.success(channels: []),
                       map: { .success(channels: ($0 as? ChannelsMO)?.toChannels() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateChannels(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: ChannelsMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateChannels(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: ChannelsMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Network Users

    func fetchNetworkUsers(with id: String, completion: @escaping (BHServerApiFeed.UsersResult) -> Void) {
        backgroundReadPrefetching(id, entityName: NetworkUsersMO.entityName, prefetch: ["users"],
                                  empty: BHServerApiFeed.UsersResult.success(users: []),
                                  map: { .success(users: ($0 as? NetworkUsersMO)?.toNetworkUsers() ?? []) },
                                  completion: completion)
    }

    @discardableResult
    func insertOrUpdateNetworkUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: NetworkUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateNetworkUsers(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: NetworkUsersMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Network Posts

    func fetchNetworkPosts(with id: String, completion: @escaping (BHServerApiFeed.PaginatedPostsResult) -> Void) {
        backgroundReadPrefetching(id, entityName: NetworkPostsMO.entityName, prefetch: ["posts"],
                                  empty: BHServerApiFeed.PaginatedPostsResult.success(posts: [], page: 1, pages: 1),
                                  map: { mo in
                                      if let networkPosts = (mo as? NetworkPostsMO)?.toNetworkPosts() {
                                          return .success(posts: networkPosts.posts, page: networkPosts.page, pages: networkPosts.pages)
                                      }
                                      return .success(posts: [], page: 1, pages: 1)
                                  },
                                  completion: completion)
    }

    @discardableResult
    func insertOrUpdateNetworkPosts(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: NetworkPostsMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateNetworkPosts(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: NetworkPostsMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Downloads

    func fetchDownloads(completion: @escaping ([BHDownloadItem]) -> Void) {
        var items: [BHDownloadItem] = []
        let request: NSFetchRequest<DownloadItemMO> = DownloadItemMO.fetchRequest()
        if let moObjects = try? dataStack.viewContext.fetch(request) {
            for itemMO in moObjects {
                if let item = itemMO.toDownloadItem() {
                    items.append(item)
                }
            }
        }
        completion(items)
    }

    func fetchDownloadItem(with id: String) -> BHDownloadItem? {
        do {
            let itemMO = try dataStack.fetch(id, inEntityNamed: DownloadItemMO.entityName) as? DownloadItemMO
            return itemMO?.toDownloadItem()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }

    @discardableResult
    func insertOrUpdateDownloadItem(with item: BHDownloadItem) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: DownloadItemMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateDownloadItem(with item: BHDownloadItem) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.update(item.id, with: params, inEntityNamed: DownloadItemMO.entityName) as NSManagedObject?
        }
        return true
    }

    @discardableResult
    func removeDownloadItem(with id: String) -> Bool {
        performWrite { context in
            try context.delete(id, inEntityNamed: DownloadItemMO.entityName)
        }
        return true
    }

    // MARK: - Queue

    func fetchQueue(completion: @escaping ([BHQueueItem]) -> Void) {
        var items: [BHQueueItem] = []
        let request: NSFetchRequest<QueueItemMO> = QueueItemMO.fetchRequest()
        if let moObjects = try? dataStack.viewContext.fetch(request) {
            for itemMO in moObjects {
                if let item = itemMO.toQueueItem() {
                    items.append(item)
                }
            }
        }
        completion(items)
    }

    func fetchQueueItem(with id: String) -> BHQueueItem? {
        do {
            let itemMO = try dataStack.fetch(id, inEntityNamed: QueueItemMO.entityName) as? QueueItemMO
            return itemMO?.toQueueItem()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }

    @discardableResult
    func insertOrUpdateQueueItem(with item: BHQueueItem) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: QueueItemMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateQueueItem(with item: BHQueueItem) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.update(item.id, with: params, inEntityNamed: QueueItemMO.entityName) as NSManagedObject?
        }
        return true
    }

    @discardableResult
    func removeQueueItem(with id: String) -> Bool {
        performWrite { context in
            try context.delete(id, inEntityNamed: QueueItemMO.entityName)
        }
        return true
    }

    // MARK: - User Screen

    func fetchUser(with userId: String) -> BHUser? {
        do {
            let userMO = try dataStack.fetch(userId, inEntityNamed: UserMO.entityName) as? UserMO
            return userMO?.toUser()
        } catch {
            return nil
        }
    }

    @discardableResult
    func insertOrUpdateUser(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: UserMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateUser(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: UserMO.entityName) as NSManagedObject?
        }
        return true
    }

    func fetchUserPosts(with id: String, completion: @escaping (BHServerApiFeed.PaginatedPostsResult) -> Void) {
        backgroundRead(id, entityName: UserPostsMO.entityName,
                       empty: BHServerApiFeed.PaginatedPostsResult.success(posts: [], page: 1, pages: 1),
                       map: { mo in
                           if let userPosts = (mo as? UserPostsMO)?.toPosts() {
                               return .success(posts: userPosts.posts, page: userPosts.page, pages: userPosts.pages)
                           }
                           return .success(posts: [], page: 1, pages: 1)
                       },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateUserPosts(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: UserPostsMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Favorites

    func fetchLikedPosts(with id: String, completion: @escaping (BHServerApiFeed.PaginatedPostsResult) -> Void) {
        backgroundRead(id, entityName: LikedPostsMO.entityName,
                       empty: BHServerApiFeed.PaginatedPostsResult.success(posts: [], page: 1, pages: 1),
                       map: { mo in
                           if let likedPosts = (mo as? LikedPostsMO)?.toPosts() {
                               return .success(posts: likedPosts.posts, page: likedPosts.page, pages: likedPosts.pages)
                           }
                           return .success(posts: [], page: 1, pages: 1)
                       },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateLikedPosts(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: LikedPostsMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Recent Users

    func fetchRecentUsers(with id: String, completion: @escaping (BHServerApiBase.PaginatedUsersResult) -> Void) {
        backgroundRead(id, entityName: RecentUsersMO.entityName,
                       empty: BHServerApiBase.PaginatedUsersResult.success(users: [], page: 1, pages: 1),
                       map: { mo in
                           if let recentUsers = (mo as? RecentUsersMO)?.toUsers() {
                               return .success(users: recentUsers.users, page: recentUsers.page, pages: recentUsers.pages)
                           }
                           return .success(users: [], page: 1, pages: 1)
                       },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateRecentUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: RecentUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Post Screen

    func fetchPost(with postId: String) -> BHPost? {
        do {
            let postMO = try dataStack.fetch(postId, inEntityNamed: PostMO.entityName) as? PostMO
            return postMO?.toPost()
        } catch {
            return nil
        }
    }

    @discardableResult
    func insertOrUpdatePost(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: PostMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updatePost(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: PostMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Related Users

    func fetchRelatedUsers(with id: String, completion: @escaping (BHServerApiFeed.UsersResult) -> Void) {
        backgroundRead(id, entityName: RelatedUsersMO.entityName,
                       empty: BHServerApiFeed.UsersResult.success(users: []),
                       map: { .success(users: ($0 as? RelatedUsersMO)?.toUsers() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateRelatedUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: RelatedUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Network Radios

    func fetchNetworkRadios(with id: String, completion: @escaping (BHServerApiNetwork.RadiosResult) -> Void) {
        backgroundRead(id, entityName: NetworkRadiosMO.entityName,
                       empty: BHServerApiNetwork.RadiosResult.success(radios: []),
                       map: { .success(radios: ($0 as? NetworkRadiosMO)?.toRadios() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateNetworkRadios(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: NetworkRadiosMO.entityName) as NSManagedObject
        }
        return true
    }

    // MARK: - Offsets

    func fetchOffsets(completion: @escaping ([BHOffset]) -> Void) {
        var items: [BHOffset] = []
        let request: NSFetchRequest<OffsetMO> = OffsetMO.fetchRequest()
        if let moObjects = try? dataStack.viewContext.fetch(request) {
            for itemMO in moObjects {
                if let item = itemMO.toOffset() {
                    items.append(item)
                }
            }
        }
        completion(items)
    }

    func fetchOffset(with id: String) -> BHOffset? {
        do {
            let itemMO = try dataStack.fetch(id, inEntityNamed: OffsetMO.entityName) as? OffsetMO
            return itemMO?.toOffset()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }

    @discardableResult
    func insertOrUpdateOffset(with item: BHOffset) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: OffsetMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateOffset(with item: BHOffset) -> Bool {
        guard let params = try? item.toDictionary() else { return false }
        performWrite { context in
            _ = try context.update(item.id, with: params, inEntityNamed: OffsetMO.entityName) as NSManagedObject?
        }
        return true
    }

    @discardableResult
    func removeOffset(with id: String) -> Bool {
        performWrite { context in
            try context.delete(id, inEntityNamed: OffsetMO.entityName)
        }
        return true
    }

    // MARK: - Followed Users

    func fetchFollowedUsers(with id: String, completion: @escaping (BHServerApiFeed.UsersResult) -> Void) {
        backgroundRead(id, entityName: FollowedUsersMO.entityName,
                       empty: BHServerApiFeed.UsersResult.success(users: []),
                       map: { .success(users: ($0 as? FollowedUsersMO)?.toUsers() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateFollowedUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: FollowedUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateFollowedUsers(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: FollowedUsersMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Categories

    func fetchCategories(with id: String, completion: @escaping (BHServerApiCategories.CategoriesResult) -> Void) {
        backgroundRead(id, entityName: CategoriesMO.entityName,
                       empty: BHServerApiCategories.CategoriesResult.success(categories: []),
                       map: { .success(categories: ($0 as? CategoriesMO)?.toCategories() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateCategories(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: CategoriesMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateCategories(with id: String, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(id, with: params, inEntityNamed: CategoriesMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - Category Users

    func fetchCategoryUsers(with id: Int, completion: @escaping (BHServerApiBase.UsersResult) -> Void) {
        backgroundRead(NSNumber(integerLiteral: id), entityName: CategoryUsersMO.entityName,
                       empty: BHServerApiBase.UsersResult.success(users: []),
                       map: { .success(users: ($0 as? CategoryUsersMO)?.toUsers() ?? []) },
                       completion: completion)
    }

    @discardableResult
    func insertOrUpdateCategoryUsers(with params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.insertOrUpdate(params, inEntityNamed: CategoryUsersMO.entityName) as NSManagedObject
        }
        return true
    }

    @discardableResult
    func updateCategoryUsers(with id: Int, params: [String : Any]) -> Bool {
        performWrite { context in
            _ = try context.update(NSNumber(integerLiteral: id), with: params, inEntityNamed: CategoryUsersMO.entityName) as NSManagedObject?
        }
        return true
    }

    // MARK: - GrayLog Tracker

    func trackError(_ error: Error) {
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .error, banner: .storageFailed, context: error.localizedDescription)
        BHTracker.shared.trackEvent(with: request)
    }
}


