
import Foundation
internal import Alamofire

class BHServerApiFeed: BHServerApiBase {

    // MARK: - Public

    func getFeedPosts(authToken: String?, page: Int?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "feed/posts" + self.composePageFilter(page: page)
            let fullPath = self.composeFullApiURL(with: path)

            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let posts):
                      completion(.success(posts: posts.posts))
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getFeedActualPosts(authToken: String?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "feed/actual"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  switch response.result {
                  case .success(let posts):
                      completion(.success(posts: posts.posts))
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getContinueListening(authToken: String?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "feed/continue_listening"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  switch response.result {
                  case .success(let posts):
                      completion(.success(posts: posts.posts))
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getLikedPosts(authToken token: String, userId: String, text: String?, page: Int?, completion: @escaping (PaginatedPostsResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            let path = "feed/liked" + self.composePageFilter(page: page) + self.composeTextFilter(text: text)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseJSONAPI(completionHandler: { (response) in
                    switch response.result {
                    case .success(let data):
                        do {
                            let pp = try JSONDecoder().decode(PaginatedPosts.self, from: JSONSerialization.data(withJSONObject: data))
                            let posts = try? pp.posts.toDictionaryArray()
                            
                            let params: [String : Any] = [
                                "id": userId,
                                "page": pp.meta.page,
                                "pages": pp.meta.pages,
                                "liked_posts": posts ?? []
                            ]
                            
                            if !DataBaseManager.shared.insertOrUpdateLikedPosts(with: params) {
                                BHLog.w("Failed to save liked posts")
                            }
                            
                            completion(.success(posts: pp.posts, page: pp.meta.page, pages: pp.meta.pages))
                        } catch let error {
                            completion(.failure(error: error))
                        }
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                })
        }
    }
    
    func getCategoryPosts(authToken: String?, categoryId: Int, text: String?, pageSize: Int = 20, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "categories/\(categoryId)/recent_episodes?filter[per_page]=\(pageSize)" + self.composeTextFilter(text: text)
            let fullPath = self.composeFullApiURL(with: path)

            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let posts):
                      completion(.success(posts: posts.posts))
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }
}
