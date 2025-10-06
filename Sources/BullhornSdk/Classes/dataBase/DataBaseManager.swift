import Foundation
import UIKit
import CoreData

class DataBaseManager {
    
    // MARK: - Properties
    
    static let shared: DataBaseManager = DataBaseManager()
    
    let dataStack: DataStack
    
    init() {

        self.dataStack = DataStack(modelName: "Bullhorn", bundle: Bundle.module, storeType: .sqLite)
        
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func insertOrUpdateNetworkFeaturedUsers(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkFeaturedUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateNetworkFeaturedPosts(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkFeaturedPostsMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }
    
    // MARK: - Network Channels

    func fetchNetworkChannels(with id: String, completion: @escaping (BHServerApiNetwork.ChannelsResult) -> Void) {
        
        do {
            let channelsMO = try dataStack.fetch(id, inEntityNamed: NetworkChannelsMO.entityName) as? NetworkChannelsMO
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
    
    func insertOrUpdateNetworkChannels(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkChannelsMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateNetworkChannels(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: NetworkChannelsMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateNetworkUsers(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateNetworkUsers(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: NetworkUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateNetworkPosts(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkPostsMO.entityName)
            return updateDownloads()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateNetworkPosts(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: NetworkPostsMO.entityName)
            return updateDownloads()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
            let item = itemMO?.toDownloadItem()
            return item
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }
    
    func insertOrUpdateDownloadItem(with item: BHDownloadItem) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.insertOrUpdate(params, inEntityNamed: DownloadItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateDownloads() -> Bool {
        
        var result: Bool = true
        let items = BHDownloadsManager.shared.items

        for item in items {
            result = updateDownloadItem(with: item)
        }
        
        return result
    }

    func updateDownloadItem(with item: BHDownloadItem) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.update(item.id, with: params, inEntityNamed: DownloadItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func removeDownloadItem(with id: String) -> Bool {

        do {
            try dataStack.delete(id, inEntityNamed: DownloadItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
            let item = itemMO?.toQueueItem()
            return item
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }
    
    func insertOrUpdateQueueItem(with item: BHQueueItem) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.insertOrUpdate(params, inEntityNamed: QueueItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateQueue() -> Bool {
        
        var result: Bool = true
        let items = BHHybridPlayer.shared.playbackQueue

        for item in items {
            result = updateQueueItem(with: item)
        }
        
        return result
    }

    func updateQueueItem(with item: BHQueueItem) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.update(item.id, with: params, inEntityNamed: QueueItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func removeQueueItem(with id: String) -> Bool {

        do {
            try dataStack.delete(id, inEntityNamed: QueueItemMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }
    
    // MARK: - User Screen

    func fetchUser(with userId: String) -> BHUser? {
        
        do {
            let userMO = try dataStack.fetch(userId, inEntityNamed: UserMO.entityName) as? UserMO
            let user = userMO?.toUser()
            return user
        }
        catch {
            return nil
        }
    }
    
    func insertOrUpdateUser(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: UserMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }
    
    func updateUser(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: UserMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateUserPosts(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: UserPostsMO.entityName)
            return updateDownloads()
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateLikedPosts(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: LikedPostsMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateRecentUsers(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: RecentUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    // MARK: - Post Screen

    func fetchPost(with postId: String) -> BHPost? {
        
        do {
            let postMO = try dataStack.fetch(postId, inEntityNamed: PostMO.entityName) as? PostMO
            let post = postMO?.toPost()
            return post
        }
        catch {
            return nil
        }
    }
    
    func insertOrUpdatePost(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: PostMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updatePost(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: PostMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

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
    
    func insertOrUpdateRelatedUsers(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: RelatedUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateNetworkRadios(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: NetworkRadiosMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
            let item = itemMO?.toOffset()
            return item
        } catch {
            BHLog.w("\(#function) - \(error)")
            return nil
        }
    }
    
    func insertOrUpdateOffset(with item: BHOffset) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.insertOrUpdate(params, inEntityNamed: OffsetMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateOffsets() -> Bool {
        
        var result: Bool = true
        let items = BHOffsetsManager.shared.offsets

        for item in items {
            result = updateOffset(with: item)
        }
        
        return result
    }

    func updateOffset(with item: BHOffset) -> Bool {

        do {
            let params = try item.toDictionary()
            try dataStack.update(item.id, with: params, inEntityNamed: OffsetMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func removeOffset(with id: String) -> Bool {

        do {
            try dataStack.delete(id, inEntityNamed: OffsetMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
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
    
    func insertOrUpdateFollowedUsers(with params: [String : Any]) -> Bool {

        do {
            try dataStack.insertOrUpdate(params, inEntityNamed: FollowedUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    func updateFollowedUsers(with id: String, params: [String : Any]) -> Bool {

        do {
            try dataStack.update(id, with: params, inEntityNamed: FollowedUsersMO.entityName)
            return true
        } catch {
            BHLog.w("\(#function) - \(error)")
            return false
        }
    }

    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "Bullhorn")

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                BHLog.w("Unresolved error \(error), \(error.userInfo)")
            }
        })

        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {

        let context = persistentContainer.viewContext

        if context.hasChanges {

            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                BHLog.w("\(#function), Unresolved error \(nserror), \(nserror.userInfo)")
                trackError(error)
            }
        }
    }
    
    // MARK: - Notifications
    
    @objc func applicationWillTerminate(notification: Notification) {
        BHLog.p("\(#function)")
        
        saveContext()
    }
    
    // MARK: - GrayLog Tracker
    
    func trackError(_ error: Error) {
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .error, banner: .storageFailed, context: error.localizedDescription)
        BHTracker.shared.trackEvent(with: request)
    }
}


