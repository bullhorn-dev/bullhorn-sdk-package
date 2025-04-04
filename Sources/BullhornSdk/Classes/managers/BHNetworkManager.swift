
import Foundation

protocol BHNetworkManagerListener: ObserverProtocol {
    func networkManagerDidFetchPosts(_ manager: BHNetworkManager)
}

class BHNetworkManager {

    static let shared = BHNetworkManager()

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHNetworkManagerListener>
    private let workingQueue = DispatchQueue.init(label: "BHNetworkManager.Working", target: .global())

    private var dispatchQueue = DispatchQueue.global()
    
    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }
    
    fileprivate lazy var apiNetwork = BHServerApiNetwork.init(withApiType: .regular)
    fileprivate lazy var apiExplore = BHServerApiExplore.init(withApiType: .regular)
    
    var network: BHNetwork?
    var liveNowPosts: [BHPost] = []
    var scheduledPosts: [BHPost] = []
    var featuredPosts: [BHPost] = []
    var featuredUsers: [BHUser] = []
    
    // MARK: - Posts
    
    var posts: [BHPost] = []
    
    var hasMorePosts: Bool {
        return postsPage < postsPages
    }
    
    fileprivate var postsPage: Int = 0
    fileprivate var postsPages: Int = 0
    
    fileprivate var nextPostsPage: Int {
        return min(postsPage + 1, postsPages)
    }
    
    // MARK: - Users
    
    var users: [BHUser] = []
    
    var hasMoreUsers: Bool {
        return usersPage < usersPages
    }
    
    fileprivate var usersPage: Int = 0
    fileprivate var usersPages: Int = 0
    
    fileprivate var nextUsersPage: Int {
        return min(usersPage + 1, usersPages)
    }

    // MARK: - Initialization
    
    init() {
        observersContainer = .init(notifyQueue: workingQueue)
    }
        
    // MARK: - Public listener

    func addListener(_ listener: BHNetworkManagerListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHNetworkManagerListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public
    
    func getNetwork(_ networkId: String, completion: @escaping (BHServerApiNetwork.NetworkResult) -> Void) {
        
        apiNetwork.getNetwork(authToken: authToken, networkId: networkId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(network: let network):
                    self.network = network
                case .failure(error: let error):
                    BHLog.w("Network load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getNetworkRadios(_ networkId: String, completion: @escaping (BHServerApiNetwork.RadiosResult) -> Void) {
        
        apiNetwork.getRadios(authToken: authToken, networkId: networkId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(radios: _):
                    break
                case .failure(error: let error):
                    BHLog.w("Radios load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getNetworkPosts(_ networkId: String, completion: @escaping (BHServerApiBase.PaginatedPostsResult) -> Void) {
                
        apiNetwork.getNetworkPosts(authToken: authToken, networkId: networkId, text: nil, page: nextPostsPage, perPage: apiNetwork.defaultPageCount) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: _, page: let page, pages: let pages):
                    self.postsPage = page
                    self.postsPages = pages
                    self.fetchStorageEpisodes(networkId) { _ in }
                case .failure(error: let error):
                    BHLog.w("Network episodes load failed \(error.localizedDescription)")
                }

                self.observersContainer.notifyObserversAsync {
                    $0.networkManagerDidFetchPosts(self)
                }

                completion(response)
            }
        }
    }
    
    func getNetworkUsers(_ networkId: String, completion: @escaping (BHServerApiFeed.PaginatedUsersResult) -> Void) {
                
        apiNetwork.getNetworkUsers(authToken: authToken, networkId: networkId, text: nil, page: nextUsersPage, perPage: 50) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: _, page: let page, pages: let pages):
                    self.usersPage = page
                    self.usersPages = pages
                    self.fetchStoragePodcasts(networkId) { _ in }
                case .failure(error: let error):
                    BHLog.w("Network podcasts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func getLiveNowPosts(_ networkId: String, text: String?, completion: @escaping (BHServerApiBase.PostsResult) -> Void) {
        
        apiExplore.getLiveNowPosts(authToken: authToken, networkId: networkId, text: text, page: 1) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts):
                    self.liveNowPosts = posts
                case .failure(error: let error):
                    BHLog.w("Network live now posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getScheduledPosts(_ networkId: String, text: String?, completion: @escaping (BHServerApiBase.PostsResult) -> Void) {
        
        apiExplore.getScheduledPosts(authToken: authToken, networkId: networkId, text: text, page: 1) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts):
                    self.scheduledPosts = posts
                case .failure(error: let error):
                    BHLog.w("Network scheduled posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getFeaturedPosts(_ networkId: String, completion: @escaping (BHServerApiBase.PostsResult) -> Void) {
        
        apiExplore.getFeaturedPosts(authToken: authToken, networkId: networkId, page: 1) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts):
                    self.featuredPosts = posts
                case .failure(error: let error):
                    BHLog.w("Network featured posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getFeaturedUsers(_ networkId: String, completion: @escaping (BHServerApiBase.UsersResult) -> Void) {
        
        apiExplore.getFeaturedUsers(authToken: authToken, networkId: networkId, page: 1) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users):
                    self.featuredUsers = users
                case .failure(error: let error):
                    BHLog.w("Network live now posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func updatePlaybackCompleted(_ postId: String, completed: Bool) {
        var post = posts.first(where: { $0.id == postId })
        post?.isPlaybackCompleted = completed
        
        if let validPost = post, let row = posts.firstIndex(where: {$0.id == postId}) {
            posts[row] = validPost
            
            self.observersContainer.notifyObserversAsync {
                $0.networkManagerDidFetchPosts(self)
            }
        }
    }
    
    // MARK: - Initial fetch for screen
    
    func fetch(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        
        postsPage = 0
        postsPages = 0
        usersPage = 0
        usersPages = 0
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()
        
        getNetwork(networkId) { response in
            switch response {
            case .success(network: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
                
        fetchGroup.enter()
        
        BHRadioStreamsManager.shared.fetch(networkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getNetworkUsers(networkId) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
         
        getLiveNowPosts(BHAppConfiguration.shared.foxNetworkId, text: nil) { response in
            switch response {
            case .success(posts: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
         
        fetchGroup.enter()
         
        getScheduledPosts(BHAppConfiguration.shared.foxNetworkId, text: nil) { response in
            switch response {
            case .success(posts: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()
        
        getFeaturedPosts(networkId) { response in
            switch response {
            case .success(posts: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getFeaturedUsers(networkId) { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getNetworkPosts(networkId) { response in
            switch response {
            case .success(posts: _, page: _, pages: _): break
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
    
    fileprivate func fetchStorageNetwork(_ networkId: String) {
        network = DataBaseManager.shared.fetchNetwork(with: networkId)
    }

    fileprivate func fetchStorageScheduledEpisodes(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkScheduledPosts(with: networkId) { response in
            switch response {
            case .success(posts: let posts):
                self.scheduledPosts = posts
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    fileprivate func fetchStorageLiveEpisodes(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkLivePosts(with: networkId) { response in
            switch response {
            case .success(posts: let posts):
                self.liveNowPosts = posts
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }

    fileprivate func fetchStorageFeaturedEpisodes(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkFeaturedPosts(with: networkId) { response in
            switch response {
            case .success(posts: let posts):
                self.featuredPosts = posts
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }

    fileprivate func fetchStorageFeaturedPodcasts(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkFeaturedUsers(with: networkId) { response in
            switch response {
            case .success(users: let users):
                self.featuredUsers = users
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }

    func fetchStorageEpisodes(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkPosts(with: networkId) { response in
            switch response {
            case .success(posts: let posts, page: let page, pages: let pages):
                if page > 1 {
                    self.posts += posts
                } else {
                    self.posts = posts
                }
                self.postsPage = page
                self.postsPages = pages
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    fileprivate func fetchStoragePodcasts(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchNetworkUsers(with: networkId) { response in
            switch response {
            case .success(users: let users, page: let page, pages: let pages):
                if page > 1 {
                    self.users += users
                } else {
                    self.users = users
                }
                self.usersPage = page
                self.usersPages = pages
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

        fetchStorageNetwork(networkId)

        fetchStorageFeaturedPodcasts(networkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        fetchStorageFeaturedEpisodes(networkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        fetchStorageScheduledEpisodes(BHAppConfiguration.shared.foxNetworkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        fetchStorageLiveEpisodes(BHAppConfiguration.shared.foxNetworkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        fetchStoragePodcasts(networkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        fetchStorageEpisodes(networkId) { response in
            switch response {
            case .success: break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()

        BHRadioStreamsManager.shared.fetchStorage(networkId) { response in
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
