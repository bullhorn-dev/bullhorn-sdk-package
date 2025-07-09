
import Foundation

protocol BHUserManagerListener: ObserverProtocol {
    func userManagerDidFetchPosts(_ manager: BHUserManager)
    func userManagerDidUpdatePosts(_ manager: BHUserManager)
    func userManagerDidUpdateFollowedUsers(_ manager: BHUserManager)
}

class BHUserManager {

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHUserManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHUserManager.Working", target: .global())

    private var dispatchQueue = DispatchQueue.global()

    static let shared = BHUserManager()

    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }

    fileprivate lazy var apiUsers = BHServerApiUsers.init(withApiType: .regular)

    var user: BHUser?
    
    ///

    var posts: [BHPost] = []

    var hasMore: Bool {
        return page < pages
    }
    
    fileprivate var page: Int = 0
    fileprivate var pages: Int = 0
    fileprivate var searchText: String = ""
     
    fileprivate var nextPage: Int {
        return min(page + 1, pages)
    }
    
    ///
    
    var followedUsers: [BHUser] = []
    
    var newEpisodesUsers: [BHUser] {
        return followedUsers.filter({ $0.unwatchedEpisodesCount > 0 })
    }

    init() {
        observersContainer = .init(notifyQueue: workingQueue)
    }
        
    // MARK: - Public listener

    func addListener(_ listener: BHUserManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHUserManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public
    
    func getUser(_ userId: String, context: String?, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiUsers.getUser(authToken: authToken, userId: userId, context: context) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    self.fetchStorageUser(userId)
                    self.user = user
                case .failure(error: let error):
                    BHLog.w("User load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    
    func getUserByUsername(_ username: String, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiUsers.getUser(authToken: authToken, username: username) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    self.fetchStorageUser(user.id)
                    self.user = user
                case .failure(error: let error):
                    BHLog.w("User by username load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func getUserPosts(_ userId: String, text: String?, completion: @escaping (BHServerApiBase.PaginatedPostsResult) -> Void) {
        
        if let validText = text, validText != searchText {
            page = 0
            pages = 0
        }
        
        searchText = text ?? ""

        apiUsers.getUserPosts(authToken: authToken, userId: userId, text: searchText, page: nextPage) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: _, page: let page, pages: let pages):
                    self.page = page
                    self.pages = pages
                    self.fetchStoragePosts(userId) { _ in }
                case .failure(error: let error):
                    BHLog.w("User posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func updatePost(_ post: BHPost) {
        if let row = posts.firstIndex(where: {$0.id == post.id}) {
            self.posts[row] = post
            
            self.observersContainer.notifyObserversAsync {
                $0.userManagerDidUpdatePosts(self)
            }
        }
    }
    
    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        var post = posts.first(where: { $0.id == postId })
        post?.updatePlaybackOffset(offset, completed: completed)
        
        if let validPost = post, let row = posts.firstIndex(where: {$0.id == postId}) {
            posts[row] = validPost
            
            self.observersContainer.notifyObserversAsync {
                $0.userManagerDidUpdatePosts(self)
            }
        }
    }
    
    func getUserRecommendations(_ userId: String, completion: @escaping (BHServerApiBase.UsersResult) -> Void) {

        apiUsers.getUserRecommendations(authToken: authToken, userId: userId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: _):
                    break
                case .failure(error: let error):
                    BHLog.w("User recommendations load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func followUser(_ userId: String, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiUsers.followUser(authToken: authToken, userId: userId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    BHNetworkManager.shared.updateNetworkUser(user)
                    
                    /// track event
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .followPodcast, context: user.shareLink?.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
                    BHTracker.shared.trackEvent(with: request)

                case .failure(error: let error):
                    BHLog.w("User follow failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func unfollowUser(_ userId: String, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiUsers.unfollowUser(authToken: authToken, userId: userId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    BHNetworkManager.shared.updateNetworkUser(user)
                    self.followedUsers.removeAll(where: { $0.id == userId })
                                        
                    /// track event
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .unfollowPodcast, context: user.shareLink?.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
                    BHTracker.shared.trackEvent(with: request)

                case .failure(error: let error):
                    BHLog.w("User unfollow failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getFollowedUsers(_ userId: String, completion: @escaping (BHServerApiBase.UsersResult) -> Void) {

        apiUsers.getFollowedUsers(userId, authToken: authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users):
                    self.followedUsers = users
                case .failure(error: let error):
                    BHLog.w("User following load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func updateFollowedUser(_ user: BHUser) {
        
        if let validUser = self.user, validUser.id == user.id {
            self.user?.outgoingStatus = user.outgoingStatus
            self.user?.receiveNotifications = user.receiveNotifications
        }
        
        if user.isFollowed {
            let row = followedUsers.firstIndex(where: {$0.id == user.id})
            if row == nil {
                self.followedUsers.append(user)
            }
        } else {
            followedUsers.removeAll(where: { $0.id == user.id })
        }
        
        if let selfUserId = BHAccountManager.shared.user?.id {
            let params: [String : Any] = [
                "id": selfUserId,
                "followed_users": followedUsers
            ]
            
            if !DataBaseManager.shared.insertOrUpdateFollowedUsers(with: params) {
                BHLog.w("Failed to save followed users")
            }
        }

        self.observersContainer.notifyObserversAsync {
            $0.userManagerDidUpdateFollowedUsers(self)
        }
    }
    
    func updateUserNotifications(_ user: BHUser) {

        if let validUser = self.user, validUser.id == user.id {
            self.user?.receiveNotifications = user.receiveNotifications
            self.user?.autoDownload = user.autoDownload
        }
        
        if let row = followedUsers.firstIndex(where: {$0.id == user.id}) {
            self.followedUsers[row] = user
        }

        if let selfUserId = BHAccountManager.shared.user?.id {
            let params: [String : Any] = [
                "id": selfUserId,
                "followed_users": followedUsers
            ]
            
            if !DataBaseManager.shared.insertOrUpdateFollowedUsers(with: params) {
                BHLog.w("Failed to save followed users")
            }
        }
    }
    
    func getNewEpisodesCount(_ completion: @escaping (BHServerApiUsers.NewEpisodesCountResult) -> Void) {

        apiUsers.getNewEpisodesCount(authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(count: _):
                    break
                case .failure(error: let error):
                    BHLog.w("New episodes count load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func clearCounters(_ completion: @escaping (CommonResult) -> Void) {

        apiUsers.clearCounters(authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success:
                    BHLog.p("Cleared new episodes counters")
                    for index in self.followedUsers.indices {
                        self.followedUsers[index].newEpisodesCount = 0
                    }
                case .failure(error: let error):
                    BHLog.w("Clear counters failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func clearUserCounters(_ user: BHUser) {
        if let row = followedUsers.firstIndex(where: {$0.id == user.id}) {
            self.followedUsers[row].newEpisodesCount = 0
        }
    }

    // MARK: - Initial fetch for screen

    func fetch(_ userId: String, context: String?, completion: @escaping (CommonResult) -> Void) {

        page = 0
        pages = 0
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        getUser(userId, context: context) { response in
            switch response {
            case .success(user: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        getUserPosts(userId, text: nil) { response in
            switch response {
            case .success(posts: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.notify(queue: .main) {
            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
    
    func fetchFollowed(_ userId: String, completion: @escaping (CommonResult) -> Void) {

        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        getFollowedUsers(userId) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.notify(queue: .main) {
            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
        
    // MARK: - Storage Providers
    
    fileprivate func fetchStorageUser(_ userId: String) {
        user = DataBaseManager.shared.fetchUser(with: userId)
    }

    fileprivate func fetchStoragePosts(_ userId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchUserPosts(with: userId) { response in
            switch response {
            case .success(posts: let posts, page: let page, pages: let pages):
                if page > 1 {
                    self.posts += posts
                } else {
                    self.posts = posts
                }
                self.page = page
                self.pages = pages
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    func fetchStorageFollowedPodcasts(_ userId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchFollowedUsers(with: userId) { response in
            switch response {
            case .success(users: let users):
                self.followedUsers = users
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    func fetchStorage(_ userId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        fetchStorageUser(userId)

        fetchStoragePosts(userId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.notify(queue: .main) {
            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
}
