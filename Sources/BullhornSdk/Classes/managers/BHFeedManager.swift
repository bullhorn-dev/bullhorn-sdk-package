
import Foundation

class BHFeedManager {

    var dispatchQueue = DispatchQueue.global()

    static let shared = BHFeedManager()

    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }

    fileprivate lazy var server = BHServerApiFeed.init(withApiType: .regular)
    
    fileprivate var feed: [BHPost]?
    fileprivate var continueListening: [BHPost]?
    fileprivate var likedPosts: [BHPost]?

    var feedPosts: [BHPost] {
        return feed ?? []
    }

    var continueListeningPosts: [BHPost] {
        return continueListening ?? []
    }
    
    var favorites: [BHPost] {
        return likedPosts ?? []
    }

    var hasMore: Bool {
        return page < pages
    }
    
    fileprivate var page: Int = 0
    fileprivate var pages: Int = 0
    fileprivate var searchText: String = ""
     
    fileprivate var nextPage: Int {
        return min(page + 1, pages)
    }
    
    fileprivate var userId: String {
        return BHAccountManager.shared.user?.sdkUserId ?? "123321"
    }

    // MARK: - Public

    func getFeedPosts(completion: @escaping (BHServerApiFeed.PostsResult) -> Void) {

        server.getFeedPosts(authToken: authToken, page: 1) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let feed):
                    self.feed = feed
                case .failure(error: let error):
                    BHLog.w("Feed posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getContinueListening(completion: @escaping (BHServerApiFeed.PostsResult) -> Void) {

        server.getContinueListening(authToken: authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: let posts):
                    self.continueListening = posts
                case .failure(error: let error):
                    BHLog.w("Continue Listening load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getLikedPosts(_ text: String?, completion: @escaping (BHServerApiFeed.PaginatedPostsResult) -> Void) {

        if let validText = text, validText != searchText {
            page = 0
            pages = 0
        }
        
        searchText = text ?? ""

        server.getLikedPosts(authToken: authToken, userId: userId, text: searchText, page: nextPage) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: _, page: let page, pages: let pages):
                    self.page = page
                    self.pages = pages
                    self.fetchStoragePosts() { _ in }
                case .failure(error: let error):
                    BHLog.w("Liked posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func remoeLikedPost(_ post: BHPost) {
        likedPosts?.removeAll(where: {$0.id == post.id})
    }
    
    func updatePostPlayback(_ postId: String, offset: Double, completed: Bool) {
        var post = likedPosts?.first(where: { $0.id == postId })
        post?.updatePlaybackOffset(offset, completed: completed)
        
        if let validPost = post, let row = likedPosts?.firstIndex(where: {$0.id == postId}) {
            likedPosts?[row] = validPost
        }
    }
    
    // MARK: - Initial fetch for screen

    func fetch(completion: @escaping (CommonResult) -> Void) {

        page = 0
        pages = 0

        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        getFeedPosts() { response in
            switch response {
            case .success(posts: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        getContinueListening() { response in
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
    
    func fetchStoragePosts(_ completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchLikedPosts(with: userId) { response in
            switch response {
            case .success(posts: let posts, page: let page, pages: let pages):
                if page > 1 {
                    self.likedPosts?.append(contentsOf: posts)
                } else {
                    self.likedPosts = posts
                }
                self.page = page
                self.pages = pages
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
}
