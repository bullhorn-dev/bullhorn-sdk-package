
import Foundation
internal import Alamofire

class BHServerApiUsers: BHServerApiBase {
    
    // MARK: - User Result

    struct User: Codable {
        
        enum CodingKeys: String, CodingKey {
            case user
        }
        
        let user: BHUser
    }

    enum UserResult {
        case success(user: BHUser)
        case failure(error: Error)
    }

    // MARK: - Self User Result

    struct SelfUser: Codable {
        
        enum CodingKeys: String, CodingKey {
            case user
        }
        
        let user: BHSelfUser
    }

    enum SelfUserResult {
        case success(user: BHSelfUser)
        case failure(error: Error)
    }
    
    // MARK: - Public
    
    func getAuthTokenAnonymously(completion: @escaping (SelfUserResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "users/token"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(nil)
            
            AF.request(fullPath, method: .post, headers: headers)
              .validate()
              .responseDecodable(of: SelfUser.self, completionHandler: { response in
                  switch response.result {
                  case .success(let user):
                      completion(.success(user: user.user))
                  case .failure(let error):
                      self.trackError(error)
                      completion(.failure(error: error))
                  }
            })
        }
    }
    
    func loginSdkUser(clientId: String, authToken token: String?, sdkUserId: String, fullName: String?, profilePictureUri: String?, completion: @escaping (SelfUserResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let encodedName = fullName?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            let encodedUri = profilePictureUri?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            
            let path = "clients/\(clientId)/users" + self.composeSdkUserId(sdkUserId) + self.composeFullName(encodedName) + self.composeProfilePictureUri(encodedUri)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .post, headers: headers)
              .validate()
              .responseDecodable(of: SelfUser.self, completionHandler: { response in
                  debugPrint(response)
                  switch response.result {
                  case .success(let user):
                      completion(.success(user: user.user))
                  case .failure(let error):
                      self.trackError(error)
                      completion(.failure(error: error))
                  }
            })
        }
    }
    
    func getSelfInfo(authToken token: String, completion: @escaping (UserResult) -> Void) {
        let path = "users/self"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(token)
        
        AF.request(fullPath, method: .get, headers: headers)
          .validate()
          .responseDecodable(of: User.self, completionHandler: { response in
              switch response.result {
              case .success(let user):
                  completion(.success(user: user.user))
              case .failure(let error):
                  self.trackError(error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func getUser(authToken token: String, userId: String, context: String?, completion: @escaping (UserResult) -> Void) {
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            let path = "users/\(userId)" + self.composeContext(text: context)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseJSONAPI(completionHandler: { (response) in
                    switch response.result {
                    case .success(let data):
                        do {
                            let user = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: data))
                            
                            guard let userJSON = data["user"] as? [String: Any] else {
                                throw ServerApiError.parseError(m: "\(#function): Failed to parse user data", data: data)
                            }
                            
                            if !DataBaseManager.shared.updateUser(with: userId, params: userJSON) {
                                BHLog.w("Save user to storage failed")
                            }
                            
                            completion(.success(user: user.user))
                        } catch let error {
                            self.trackError(error)
                            completion(.failure(error: error))
                        }
                    case .failure(let error):
                        self.trackError(error)
                        completion(.failure(error: error))
                    }
                })
        }
    }

    
    func getUser(authToken token: String, username: String, completion: @escaping (UserResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "users/by_username/\(username)"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseJSONAPI(completionHandler: { (response) in
                    switch response.result {
                    case .success(let data):
                        do {
                            let user = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: data))
                            
                            guard let userJSON = data["user"] as? [String: Any] else {
                                throw ServerApiError.parseError(m: "\(#function): Failed to parse user data", data: data)
                            }
                            guard let userId = userJSON["id"] as? String else {
                                throw ServerApiError.parseError(m: "\(#function): Failed to parse user ID", data: data)
                            }
                            
                            if !DataBaseManager.shared.updateUser(with: userId, params: userJSON) {
                                BHLog.w("Save user to storage failed")
                            }
                            
                            completion(.success(user: user.user))
                        } catch let error {
                            completion(.failure(error: error))
                        }
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                })
        }
    }

    func getUserPosts(authToken token: String, userId: String, text: String?, page: Int?, completion: @escaping (PaginatedPostsResult) -> Void) {
        let path = "users/\(userId)/posts" + composePageFilter(page: page) + composeTextFilter(text: text) + composeWithLivesFilter(value: true) + composeOrderFilter(order: "new")
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(token)
        
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
                        "user_posts": posts ?? []
                      ]

                      if !DataBaseManager.shared.insertOrUpdateUserPosts(with: params) {
                          BHLog.w("Failed to save user posts")
                      }

                      completion(.success(posts: pp.posts, page: pp.meta.page, pages: pp.meta.pages))
                  } catch let error {
                      self.trackError(error)
                      completion(.failure(error: error))
                                      }
              case .failure(let error):
                  self.trackError(error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func getUserRecommendations(authToken token: String, userId: String, completion: @escaping (UsersResult) -> Void) {
        let path = "users/\(userId)/recommendations"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(token)
        
        AF.request(fullPath, method: .get, headers: headers)
          .validate()
          .responseJSONAPI(completionHandler: { (response) in
              switch response.result {
              case .success(let data):
                  do {
                      let u = try JSONDecoder().decode(Users.self, from: JSONSerialization.data(withJSONObject: data))
                      let users = try? u.users.toDictionaryArray()

                      let params: [String : Any] = [
                        "id": userId,
                        "related_users": users ?? []
                      ]

                      if !DataBaseManager.shared.insertOrUpdateRelatedUsers(with: params) {
                          BHLog.w("Failed to save post related users")
                      }

                      completion(.success(users: u.users))
                  } catch let error {
                      self.trackError(error)
                      completion(.failure(error: error))
                                      }
              case .failure(let error):
                  self.trackError(error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func followUser(authToken: String?, userId: String, _ completion: @escaping (UserResult) -> Void) {

        let path = "users/\(userId)/follow"
        let fullPath = composeFullApiURL(with: path)
        let headers = self.composeHeaders(authToken)
        
        AF.request(fullPath, method: .post, headers: headers)
          .validate()
          .responseJSONAPI(completionHandler: { (response) in
              switch response.result {
              case .success(let data):
                  do {
                      let user = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: data))
                      
                      guard let userJSON = data["user"] as? [String: Any] else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse user data", data: data)
                      }
                      guard let userId = userJSON["id"] as? String else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse user ID", data: data)
                      }
                      
                      if !DataBaseManager.shared.updateUser(with: userId, params: userJSON) {
                          BHLog.w("Save user to storage failed")
                      }
                      
                      completion(.success(user: user.user))
                  } catch let error {
                      completion(.failure(error: error))
                  }
              case .failure(let error):
                  completion(.failure(error: error))
              }
          })
    }

    func unfollowUser(authToken: String?, userId: String, _ completion: @escaping (UserResult) -> Void) {

        let path = "users/\(userId)/unfollow"
        let fullPath = composeFullApiURL(with: path)
        let headers = self.composeHeaders(authToken)
        
        AF.request(fullPath, method: .post, headers: headers)
          .validate()
          .responseJSONAPI(completionHandler: { (response) in
              switch response.result {
              case .success(let data):
                  do {
                      let user = try JSONDecoder().decode(User.self, from: JSONSerialization.data(withJSONObject: data))
                      
                      guard let userJSON = data["user"] as? [String: Any] else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse user data", data: data)
                      }
                      guard let userId = userJSON["id"] as? String else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse user ID", data: data)
                      }
                      
                      if !DataBaseManager.shared.updateUser(with: userId, params: userJSON) {
                          BHLog.w("Save user to storage failed")
                      }
                      
                      completion(.success(user: user.user))
                  } catch let error {
                      completion(.failure(error: error))
                  }
              case .failure(let error):
                  completion(.failure(error: error))
              }
          })
    }

    func updatePushToken(authToken token: String?, pushToken: BHPushToken, completion: @escaping (CommonResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
                        
            let path = "users/self/notifications_setting/push_token"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .post, parameters: pushToken.params(), encoding: JSONEncoding.default, headers: headers)
              .validate()
              .responseData(completionHandler: { response in
                debugPrint(response)
                  
                switch response.result {
                case .success(_):
                    completion(.success)
                case .failure(let error):
                    self.trackError(error)
                    completion(.failure(error: error))
                }
            })
        }
    }
    
    func forgetPushToken(authToken token: String?, completion: @escaping (CommonResult) -> Void) {
                
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
                        
            let path = "users/self/notifications_setting/push_token"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            let params = ["notifications_setting": [:]]

            AF.request(fullPath, method: .delete, parameters: params, encoding: JSONEncoding.default, headers: headers)
              .validate()
              .responseData(completionHandler: { response in
                  debugPrint(response)
                  
                  switch response.result {
                  case .success(_):
                      completion(.success)
                  case .failure(let error):
                      self.trackError(error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
}
