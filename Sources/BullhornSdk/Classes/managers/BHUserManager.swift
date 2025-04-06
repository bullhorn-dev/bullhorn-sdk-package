
import Foundation

protocol BHUserManagerListener: ObserverProtocol {
    func userManagerDidFetchPosts(_ manager: BHUserManager)
}

class BHUserManager {

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHUserManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHUserManager.Working", target: .global())

    private var dispatchQueue = DispatchQueue.global()

    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }

    fileprivate lazy var apiUsers = BHServerApiUsers.init(withApiType: .regular)

    var posts: [BHPost] = []

    var user: BHUser?

    var hasMore: Bool {
        return page < pages
    }
    
    fileprivate var page: Int = 0
    fileprivate var pages: Int = 0
    fileprivate var searchText: String = ""
     
    fileprivate var nextPage: Int {
        return min(page + 1, pages)
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
                case .failure(error: let error):
                    BHLog.w("User unfollow failed \(error.localizedDescription)")
                }
                completion(response)
            }
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
    
    func updatePlaybackCompleted(_ postId: String, completed: Bool) {
        var post = posts.first(where: { $0.id == postId })
        post?.isPlaybackCompleted = completed
        
        if let validPost = post, let row = posts.firstIndex(where: {$0.id == postId}) {
            posts[row] = validPost
            
            self.observersContainer.notifyObserversAsync {
                $0.userManagerDidFetchPosts(self)
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
