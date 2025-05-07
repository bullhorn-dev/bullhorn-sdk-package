
import Foundation
internal import Alamofire

class BHServerApiNetwork: BHServerApiBase {
    
    // MARK: - Radios Result

    struct Radios: Codable {
        
        enum CodingKeys: String, CodingKey {
            case radios
        }
        
        var radios: [BHRadio]
    }

    enum RadiosResult {
        case success(radios: [BHRadio])
        case failure(error: Error)
    }
    
    // MARK: - Channels Result

    struct Channels: Codable {
        
        enum CodingKeys: String, CodingKey {
            case channels = "network_channels"
        }
        
        var channels: [BHChannel]
    }

    enum ChannelsResult {
        case success(channels: [BHChannel])
        case failure(error: Error)
    }

    // MARK: - Public
    
    func getNetworkChannels(authToken: String?, networkId: String, _ completion: @escaping (ChannelsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "networks/\(networkId)/network_channels"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            debugPrint(fullPath)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let data):
                      do {
                          let c = try JSONDecoder().decode(Channels.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          let channels = try? c.channels.toDictionaryArray()
                          
                          let params: [String : Any] = [
                            "id": networkId,
                            "network_channels": channels ?? []
                          ]
                          
                          if !DataBaseManager.shared.insertOrUpdateNetworkChannels(with: params) {
                              BHLog.w("Failed to save network channels")
                          }

                          completion(.success(channels: c.channels))
                      } catch let error {
                          self.trackError(url: fullPath, error: error)
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }

    func getNetworkPosts(authToken: String?, networkId: String, text: String?, page: Int?, perPage: Int?, shouldCache: Bool = true, _ completion: @escaping (PaginatedPostsResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            if let validText = text, !validText.isEmpty {
                self.cancelAllTasks()
            }
            
            let path = "networks/\(networkId)/posts" + self.composePageFilter(page: page) + self.composePerPageFilter(perPage: perPage) + self.composeTextFilter(text: text) + self.composeStatusFilter(status: "finished") + self.composeInclude("bulletin")
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let data):
                      do {
                          let pp = try JSONDecoder().decode(PaginatedPosts.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          if shouldCache {
                              let posts = try? pp.posts.toDictionaryArray()
                              let params: [String : Any] = [
                                "id": networkId,
                                "page": pp.meta.page,
                                "pages": pp.meta.pages,
                                "posts": posts ?? []
                              ]
                              
                              if !DataBaseManager.shared.insertOrUpdateNetworkPosts(with: params) {
                                  BHLog.w("Failed to save network posts")
                              }
                          }

                          completion(.success(posts: pp.posts, page: pp.meta.page, pages: pp.meta.pages))
                      } catch let error {
                          self.trackError(url: fullPath, error: error)
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getNetworkUsers(authToken: String?, networkId: String, _ completion: @escaping (UsersResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "networks/\(networkId)/podcasts/all?include=categories"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            debugPrint(fullPath)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let data):
                      do {
                          let pu = try JSONDecoder().decode(Users.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          let users = try? pu.users.toDictionaryArray()
                          
                          let params: [String : Any] = [
                            "id": networkId,
                            "users": users ?? []
                          ]
                          
                          if !DataBaseManager.shared.insertOrUpdateNetworkUsers(with: params) {
                              BHLog.w("Failed to save network users")
                          }

                          completion(.success(users: pu.users))
                      } catch let error {
                          self.trackError(url: fullPath, error: error)
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func searchNetworkUsers(authToken: String?, networkId: String, text: String?, page: Int?, perPage: Int?, shouldCache: Bool = true, _ completion: @escaping (PaginatedUsersResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            if let validText = text, !validText.isEmpty {
                self.cancelAllTasks()
            }
            
            let path = "networks/\(networkId)/podcasts" + self.composePageFilter(page: page) + self.composePerPageFilter(perPage: perPage) + self.composeTextFilter(text: text)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            debugPrint(fullPath)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  debugPrint(response)
                  switch response.result {
                  case .success(let data):
                      do {
                          let pu = try JSONDecoder().decode(PaginatedUsers.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          completion(.success(users: pu.users, page: pu.meta.page, pages: pu.meta.pages))
                      } catch let error {
                          self.trackError(url: fullPath, error: error)
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      self.trackError(url: fullPath, error: error)
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getRadios(authToken: String?, networkId: String, _ completion: @escaping (RadiosResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "networks/" + networkId + "/radios"
            let fullPath = self.composeFullApiURL(with: path)

            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  switch response.result {
                  case .success(let data):
                      do {
                          let r = try JSONDecoder().decode(Radios.self, from: JSONSerialization.data(withJSONObject: data))
                          let radios = try? r.radios.toDictionaryArray()

                          let params: [String : Any] = [
                            "id": networkId,
                            "radios": radios ?? []
                          ]

                          if !DataBaseManager.shared.insertOrUpdateNetworkRadios(with: params) {
                              BHLog.w("Failed to save network radios")
                          }
                          
                          completion(.success(radios: r.radios))
                      } catch let error {
                          self.trackError(url: fullPath, error: error)
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
