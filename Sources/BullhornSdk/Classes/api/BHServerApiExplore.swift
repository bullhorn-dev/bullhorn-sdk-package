
import Foundation
internal import Alamofire

class BHServerApiExplore: BHServerApiBase {

    // MARK: - Public

    func getLiveNowPosts(authToken: String?, networkId: String, text: String?, page: Int?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "explore/on_air_episodes" + self.composePageFilter(page: page) + self.composeNetworkIdFilter(networkId: networkId) + self.composeTextFilter(text: text)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let p):
                      completion(.success(posts: p.posts))
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getScheduledPosts(authToken: String?, networkId: String, text: String?, page: Int?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "explore/scheduled_episodes" + self.composePageFilter(page: page) + self.composeNetworkIdFilter(networkId: networkId) + self.composeTextFilter(text: text)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let p):
                      completion(.success(posts: p.posts))
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getFeaturedPosts(authToken: String?, networkId: String, page: Int?, _ completion: @escaping (PostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "highlights/posts" + self.composePageFilter(page: page) + self.composeNetworkIdFilter(networkId: networkId)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Posts, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let p):
                      let posts = try? p.posts.toDictionaryArray()

                      let params: [String : Any] = [
                        "id": networkId,
                        "featured_posts": posts ?? []
                      ]

                      if !DataBaseManager.shared.insertOrUpdateNetworkFeaturedPosts(with: params) {
                          BHLog.w("Failed to save network featured posts")
                      }
                      completion(.success(posts: p.posts))
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getFeaturedUsers(authToken: String?, networkId: String, page: Int?, _ completion: @escaping (UsersResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "highlights/users" + self.composePageFilter(page: page) + self.composeNetworkIdFilter(networkId: networkId)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseDecodable( completionHandler: { (response: DataResponse<Users, AFError>) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let u):
                      let users = try? u.users.toDictionaryArray()

                      let params: [String : Any] = [
                        "id": networkId,
                        "featured_users": users ?? []
                      ]

                      if !DataBaseManager.shared.insertOrUpdateNetworkFeaturedUsers(with: params) {
                          BHLog.w("Failed to save network featured users")
                      }
                      completion(.success(users: u.users))
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getRecentUsers(authToken: String?, networkId: String, page: Int?, _ completion: @escaping (PaginatedUsersResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            let path = "search/users/recent" + self.composePageFilter(page: page) + self.composeNetworkId(text: networkId)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseJSONAPI(completionHandler: { (response) in
                    debugPrint(response)
                    switch response.result {
                    case .success(let data):
                        do {
                            let pu = try JSONDecoder().decode(PaginatedUsers.self, from: JSONSerialization.data(withJSONObject: data))
                            let users = try? pu.users.toDictionaryArray()
                            
                            let params: [String : Any] = [
                                "id": networkId,
                                "page": pu.meta.page,
                                "pages": pu.meta.pages,
                                "recent_users": users ?? []
                            ]
                            
                            if !DataBaseManager.shared.insertOrUpdateRecentUsers(with: params) {
                                BHLog.w("Failed to save recent users")
                            }
                            
                            completion(.success(users: pu.users, page: pu.meta.page, pages: pu.meta.pages))
                        } catch let error {
                            completion(.failure(error: error))
                        }
                    case .failure(let error):
                        self.trackError(url: fullPath, error: error)
                        completion(.failure(error: error))
                    }
                })
        }
    }
}
