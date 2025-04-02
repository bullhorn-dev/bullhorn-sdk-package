
import Foundation

protocol BHExploreManagerListener: ObserverProtocol {
    func exploreManagerDidFetch(_ manager: BHExploreManager)
}

class BHExploreManager {

    static let shared = BHExploreManager()

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHExploreManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHExploreManager.Working", target: .global())

    private var dispatchQueue = DispatchQueue.global()
    
    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }
    
    fileprivate lazy var apiNetwork = BHServerApiNetwork.init(withApiType: .regular)
    fileprivate lazy var apiExplore = BHServerApiExplore.init(withApiType: .regular)
    
    fileprivate var usersSearchText: String = ""
    fileprivate var postsSearchText: String = ""

    // MARK: - Episodes
    
    var posts: [BHPost] = []
    
    var hasMorePosts: Bool {
        return postsPage < postsPages
    }
    
    fileprivate var postsPage: Int = 0
    fileprivate var postsPages: Int = 0
    
    fileprivate var nextPostsPage: Int {
        return min(postsPage + 1, postsPages)
    }
    
    // MARK: - Search Users
    
    var users: [BHUser] = []
    
    var hasMoreUsers: Bool {
        return usersPage < usersPages
    }
    
    fileprivate var usersPage: Int = 0
    fileprivate var usersPages: Int = 0
    
    fileprivate var nextUsersPage: Int {
        return min(usersPage + 1, usersPages)
    }

    // MARK: - Recent Users
    
    var recentUsers: [BHUser] = []
    
    var hasMoreRecent: Bool {
        return recentPage < recentPages
    }
    
    fileprivate var recentPage: Int = 0
    fileprivate var recentPages: Int = 0
    
    fileprivate var nextRecentPage: Int {
        return min(recentPage + 1, recentPages)
    }

    // MARK: - Initialization
    
    init() {
        observersContainer = .init(notifyQueue: workingQueue)
    }
        
    // MARK: - Public listener

    func addListener(_ listener: BHExploreManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHExploreManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public
    
    func getPosts(_ networkId: String, text: String?, completion: @escaping (BHServerApiBase.PaginatedPostsResult) -> Void) {
        
        if let validText = text, validText != postsSearchText {
            postsPage = 0
            postsPages = 0
        }
        
        postsSearchText = text ?? ""
        
        apiNetwork.getNetworkPosts(authToken: authToken, networkId: networkId, text: postsSearchText, page: nextPostsPage, perPage: apiNetwork.defaultPageCount, shouldCache: false) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts, page: let page, pages: let pages):
                    if page > 1 {
                        self.posts += posts
                    } else {
                        self.posts = posts
                    }
                    self.postsPage = page
                    self.postsPages = pages
                case .failure(error: let error):
                    BHLog.w("Network episodes load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getUsers(_ networkId: String, text: String?, completion: @escaping (BHServerApiFeed.PaginatedUsersResult) -> Void) {
        
        if let validText = text, validText != usersSearchText {
            usersPage = 0
            usersPages = 0
        }
        
        usersSearchText = text ?? ""
        
        apiNetwork.getNetworkUsers(authToken: authToken, networkId: networkId, text: usersSearchText, page: nextUsersPage, perPage: apiNetwork.defaultPageCount, shouldCache: false) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users, page: let page, pages: let pages):
                    if page > 1 {
                        self.users += users
                    } else {
                        self.users = users
                    }
                    self.usersPage = page
                    self.usersPages = pages
                case .failure(error: let error):
                    BHLog.w("Network podcasts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func getRecentUsers(_ networkId: String, isFirstPage: Bool, completion: @escaping (BHServerApiFeed.PaginatedUsersResult) -> Void) {
        
        let page = isFirstPage ? 1 : nextRecentPage

        apiExplore.getRecentUsers(authToken: authToken, networkId: networkId, page: page) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users, page: let page, pages: let pages):
                    self.recentPage = page
                    self.recentPages = pages
                    self.recentUsers = users
                case .failure(error: let error):
                    BHLog.w("Recent podcasts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    // MARK: - Initial fetch for screen
    
    func fetch(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        
        postsPage = 0
        postsPages = 0
        usersPage = 0
        usersPages = 0
        recentPage = 0
        recentPages = 0
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
                        
        fetchGroup.enter()
        
        getPosts(networkId, text: nil) { response in
            switch response {
            case .success(posts: _, page: _, pages: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getUsers(networkId, text: nil) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()

        getRecentUsers(networkId, isFirstPage: true) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        observersContainer.notifyObserversAsync {
            $0.exploreManagerDidFetch(self)
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
                $0.exploreManagerDidFetch(self)
            }
        }
    }
    
    // MARK: - Storage Providers
    
    func fetchStorageRecentUsers(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchRecentUsers(with: networkId) { response in
            switch response {
            case .success(users: let users, page: let page, pages: let pages):
                if page > 1 {
                    self.recentUsers += users
                } else {
                    self.recentUsers = users
                }
                self.recentPage = page
                self.recentPages = pages
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
        
    func fetchStorage(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        fetchStorageRecentUsers(networkId) { response in
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

