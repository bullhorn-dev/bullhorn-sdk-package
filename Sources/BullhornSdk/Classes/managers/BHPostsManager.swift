
import Foundation
internal import Alamofire

class BHPostsManager {
        
    var dispatchQueue = DispatchQueue.global()

    static let shared = BHPostsManager()

    fileprivate var authToken: String {
        return BHAccountManager.shared.authToken
    }

    fileprivate lazy var apiPosts = BHServerApiPosts.init(withApiType: .regular)
    fileprivate lazy var apiUsers = BHServerApiUsers.init(withApiType: .regular)

    fileprivate var recommendations: [BHUser]?

    var post: BHPost?
    
    var recommendedUsers: [BHUser] {
        return recommendations ?? []
    }
        
    // MARK: - Public
    
    func getPost(_ postId: String, context: String?, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {

        apiPosts.getPost(authToken: authToken, postId: postId, context: context) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(post: _):
                    self.fetchStoragePost(postId)
                case .failure(error: let error):
                    BHLog.w("Post load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func getPostByAlias(_ username: String, postAlias: String, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {

        apiPosts.getPostByAlias(authToken: authToken, username: username, postAlias: postAlias) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(post: let post):
                    self.fetchStoragePost(post.id)
                case .failure(error: let error):
                    BHLog.w("Post load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }
    
    func postLikeOn(_ postId: String, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {
        apiPosts.postLikeOn(authToken: authToken, postId: postId) { response in
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
    
    func postLikeOff(_ postId: String, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {
        apiPosts.postLikeOff(authToken: authToken, postId: postId) { response in
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
    
    func postPlaybackOffset(_ postId: String, position: Double, playbackCompleted: Bool, completion: @escaping (BHServerApiPosts.PlaybackOffsetResult) -> Void) {
        
        let offset: Parameters = [
            "timestamp": Date().timeIntervalSince1970.rounded(),
            "offset": position.rounded(),
            "playback_completed": playbackCompleted
        ]
        let params: Parameters = ["playback_offset": offset]
        
        apiPosts.postPlaybackOffset(authToken: authToken, postId: postId, parameters: params) { response in
            self.dispatchQueue.async {
                completion(response)
            }
        }
    }
    
    func getPlaybackOffset(_ postId: String, offset: Double, completion: @escaping (BHServerApiPosts.PlaybackOffsetResult) -> Void) {
        
        let timestamp = Date().timeIntervalSince1970
        
        apiPosts.getPlaybackOffset(authToken: authToken, postId: postId, timestamp: timestamp, offset: offset) { response in
            self.dispatchQueue.async {
                completion(response)
            }
        }
    }
    
    func getPhoneNumber(_ postId: String, position: Double, completion: @escaping (BHServerApiPosts.PhoneNumberResult) -> Void) {
        apiPosts.getPhoneNumber(authToken: authToken, postId: postId, position: position) { response in
            DispatchQueue.main.async {
                completion(response)
            }
        }
    }
    
    // MARK: - Initial fetch for screen

    func fetch(userId: String, postId: String, context: String?, completion: @escaping (CommonResult) -> Void) {

        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        getPost(postId, context: context) { response in
            switch response {
            case .success(post: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.enter()

        apiUsers.getUserRecommendations(authToken: authToken, userId: userId) { response in
            switch response {
            case .success(users: _):
                self.fetchStorageRelatedUsers(userId) { _ in }
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
    
    fileprivate func fetchStoragePost(_ postId: String) {
        post = DataBaseManager.shared.fetchPost(with: postId)
    }

    fileprivate func fetchStorageRelatedUsers(_ userId: String, completion: @escaping (CommonResult) -> Void) {
        DataBaseManager.shared.fetchRelatedUsers(with: userId) { response in
            switch response {
            case .success(users: let users):
                self.recommendations = users
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    func fetchStorage(userId: String, postId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        fetchStoragePost(postId)

        fetchStorageRelatedUsers(postId) { response in
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
