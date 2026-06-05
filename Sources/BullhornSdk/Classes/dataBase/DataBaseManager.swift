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

    // MARK: - Network Featured Users

    func fetchNetworkFeaturedUsers(with id: String, completion: @escaping (BHServerApiFeed.UsersResult) -> Void) {
        do {
            let featuredUsersMO = try dataStack.fetch(id, inEntityNamed: NetworkFeaturedUsersMO.entityName) as? NetworkFeaturedUsersMO
            let featuredUsers = featuredUsersMO?.toUsers() ?? []
            completion(.success(users: featuredUsers))
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: []))
        }
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
        do {
            let featuredPostsMO = try dataStack.fetch(id, inEntityNamed: NetworkFeaturedPostsMO.entityName) as? NetworkFeaturedPostsMO
            let featuredPosts = featuredPostsMO?.toPosts() ?? []
            completion(.success(posts: featuredPosts))
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(posts: []))
        }
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
        do {
            let channelsMO = try dataStack.fetch(id, inEntityNamed: ChannelsMO.entityName) as? ChannelsMO
            if let channels = channelsMO?.toChannels() {
                completion(.success(channels: channels))
            } else {
                completion(.success(channels: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(channels: []))
        }
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
        do {
            let networkUsersMO = try dataStack.fetch(id, inEntityNamed: NetworkUsersMO.entityName) as? NetworkUsersMO
            if let users = networkUsersMO?.toNetworkUsers() {
                completion(.success(users: users))
            } else {
                completion(.success(users: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: []))
        }
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
        do {
            let networkPostsMO = try dataStack.fetch(id, inEntityNamed: NetworkPostsMO.entityName) as? NetworkPostsMO
            if let networkPosts = networkPostsMO?.toNetworkPosts() {
                completion(.success(posts: networkPosts.posts, page: networkPosts.page, pages: networkPosts.pages))
            } else {
                completion(.success(posts: [], page: 1, pages: 1))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(posts: [], page: 1, pages: 1))
        }
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
        do {
            let postsMO = try dataStack.fetch(id, inEntityNamed: UserPostsMO.entityName) as? UserPostsMO
            if let userPosts = postsMO?.toPosts() {
                completion(.success(posts: userPosts.posts, page: userPosts.page, pages: userPosts.pages))
            } else {
                completion(.success(posts: [], page: 1, pages: 1))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(posts: [], page: 1, pages: 1))
        }
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
        do {
            let postsMO = try dataStack.fetch(id, inEntityNamed: LikedPostsMO.entityName) as? LikedPostsMO
            if let likedPosts = postsMO?.toPosts() {
                completion(.success(posts: likedPosts.posts, page: likedPosts.page, pages: likedPosts.pages))
            } else {
                completion(.success(posts: [], page: 1, pages: 1))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(posts: [], page: 1, pages: 1))
        }
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
        do {
            let usersMO = try dataStack.fetch(id, inEntityNamed: RecentUsersMO.entityName) as? RecentUsersMO
            if let recentUsers = usersMO?.toUsers() {
                completion(.success(users: recentUsers.users, page: recentUsers.page, pages: recentUsers.pages))
            } else {
                completion(.success(users: [], page: 1, pages: 1))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: [], page: 1, pages: 1))
        }
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
        do {
            let usersMO = try dataStack.fetch(id, inEntityNamed: RelatedUsersMO.entityName) as? RelatedUsersMO
            if let users = usersMO?.toUsers() {
                completion(.success(users: users))
            } else {
                completion(.success(users: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: []))
        }
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
        do {
            let radiosMO = try dataStack.fetch(id, inEntityNamed: NetworkRadiosMO.entityName) as? NetworkRadiosMO
            let radios = radiosMO?.toRadios() ?? []
            completion(.success(radios: radios))
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.failure(error: error))
        }
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
        do {
            let usersMO = try dataStack.fetch(id, inEntityNamed: FollowedUsersMO.entityName) as? FollowedUsersMO
            if let users = usersMO?.toUsers() {
                completion(.success(users: users))
            } else {
                completion(.success(users: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: []))
        }
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
        do {
            let categoriesMO = try dataStack.fetch(id, inEntityNamed: CategoriesMO.entityName) as? CategoriesMO
            if let categories = categoriesMO?.toCategories() {
                completion(.success(categories: categories))
            } else {
                completion(.success(categories: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(categories: []))
        }
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
        do {
            let usersMO = try dataStack.fetch(NSNumber(integerLiteral: id), inEntityNamed: CategoryUsersMO.entityName) as? CategoryUsersMO
            if let users = usersMO?.toUsers() {
                completion(.success(users: users))
            } else {
                completion(.success(users: []))
            }
        } catch {
            BHLog.w("\(#function) - \(error)")
            completion(.success(users: []))
        }
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

