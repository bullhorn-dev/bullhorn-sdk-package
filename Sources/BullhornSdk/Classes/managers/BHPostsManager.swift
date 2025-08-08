
import Foundation
internal import Alamofire

class BHPostsManager {
        
    var dispatchQueue = DispatchQueue.global()

    static let shared = BHPostsManager()

    fileprivate var authToken: String {
        return BHAccountManager.shared.authToken
    }

    fileprivate lazy var apiPosts = BHServerApiPosts.init(withApiType: .regular)

    var post: BHPost?
    var transcript: BHTranscript?

    var transcriptSegments: [BHSegment] {
        return transcript?.segments ?? []
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
    
    func postLikeOn(_ item: BHPost, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {
        apiPosts.postLikeOn(authToken: authToken, postId: item.id) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(post: let post):
                    self.post = post
                    BHNetworkManager.shared.updateNetworkPost(post)
                    BHExploreManager.shared.updatePost(post)
                    BHUserManager.shared.updatePost(post)
                    BHDownloadsManager.shared.updatePost(post)
                case .failure(error: let error):
                    BHLog.w("Post like failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .episodeLikeOn, context: item.shareLink.absoluteString, podcastId: item.user.id, podcastTitle: item.user.fullName, episodeId: item.id, episodeTitle: item.title)
        BHTracker.shared.trackEvent(with: request)
    }
    
    func postLikeOff(_ item: BHPost, completion: @escaping (BHServerApiPosts.PostResult) -> Void) {
        apiPosts.postLikeOff(authToken: authToken, postId: item.id) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(post: let post):
                    self.post = post
                    BHNetworkManager.shared.updateNetworkPost(post)
                    BHExploreManager.shared.updatePost(post)
                    BHUserManager.shared.updatePost(post)
                    BHDownloadsManager.shared.updatePost(post)
                    BHFeedManager.shared.remoeLikedPost(post)
                case .failure(error: let error):
                    BHLog.w("Post unlike failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
        
        /// track stats
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: .episodeLikeOff, context: item.shareLink.absoluteString, podcastId: item.user.id, podcastTitle: item.user.fullName, episodeId: item.id, episodeTitle: item.title)
        BHTracker.shared.trackEvent(with: request)
    }
    
    func postPlaybackOffset(_ postId: String, position: Double, playbackCompleted: Bool, completion: @escaping (BHServerApiPosts.PlaybackOffsetResult) -> Void) {
        
        let timestamp = Date().timeIntervalSince1970

        let offset: Parameters = [
            "timestamp": timestamp,
            "offset": position.rounded(),
            "playback_completed": playbackCompleted
        ]
        let params: Parameters = ["playback_offset": offset]
        
        apiPosts.postPlaybackOffset(authToken: authToken, postId: postId, parameters: offset) { response in
            self.dispatchQueue.async {
                completion(response)
            }
        }
    }
    
    func getPlaybackOffset(_ postId: String, offset: Double, timestamp: Double, completion: @escaping (BHServerApiPosts.PlaybackOffsetResult) -> Void) {
        
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
        
    func getTranscript(_ postId: String, completion: @escaping (BHServerApiPosts.TranscriptResult) -> Void) {
        
        apiPosts.getTranscript(authToken: authToken, postId: postId) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(transcript: let transcript):
                    self.transcript = transcript
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    func getPlaybackQueuePosts(_ postId: String, count: Int = 20, completion: @escaping (BHServerApiFeed.PostsResult) -> Void) {

        apiPosts.getPlaybackQueue(authToken: authToken, postId: postId, count: count) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(posts: _):
                    break
                case .failure(error: let error):
                    BHLog.w("Playback queue posts load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }


    // MARK: - Initial fetch for screen

    func fetch(postId: String, context: String?, loadTranscript: Bool = false, completion: @escaping (CommonResult) -> Void) {

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

        if loadTranscript {
            fetchGroup.enter()
            
            getTranscript(postId) { response in
                switch response {
                case .success(transcript: _): break
                case .failure(error: let error):
                    responseError = error
                }
                fetchGroup.leave()
            }
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
    
    func fetchStorage(postId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        fetchStoragePost(postId)

        if post?.hasTranscript == true {
            // TODO: - fetch post transcript
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
