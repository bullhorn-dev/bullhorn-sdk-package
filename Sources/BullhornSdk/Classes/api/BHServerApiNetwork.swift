
import Foundation
internal import Alamofire

class BHServerApiNetwork: BHServerApiBase {

    // MARK: - Network Result

    struct Network: Codable {
        
        enum CodingKeys: String, CodingKey {
            case network
        }
        
        var network: BHNetwork
    }

    enum NetworkResult {
        case success(network: BHNetwork)
        case failure(error: Error)
    }
    
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

    // MARK: - Public

    func getNetwork(authToken: String?, networkId: String, _ completion: @escaping (NetworkResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "networks/" + networkId
            let fullPath = self.composeFullApiURL(with: path)

            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  switch response.result {
                  case .success(let data):
                      do {
                          let network = try JSONDecoder().decode(Network.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          guard let networkJSON = data["network"] as? [String: Any] else {
                              throw ServerApiError.parseError(m: "\(#function): Failed to parse network data", data: data)
                          }

                          DataBaseManager.shared.dataStack.sync([networkJSON], inEntityNamed: NetworkMO.entityName) { error in
                              if error != nil {
                                  BHLog.w("Save network to codeData failed: \(String(describing: error))")
                              }
                          }
                          
                          completion(.success(network: network.network))
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
    
    func getNetworkUsers(authToken: String?, networkId: String, text: String?, page: Int?, perPage: Int?, shouldCache: Bool = true, _ completion: @escaping (PaginatedUsersResult) -> Void) {

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
                          
                          if shouldCache {
                              let users = try? pu.users.toDictionaryArray()
                              
                              let params: [String : Any] = [
                                "id": networkId,
                                "page": pu.meta.page,
                                "pages": pu.meta.pages,
                                "users": users ?? []
                              ]
                              
                              if !DataBaseManager.shared.insertOrUpdateNetworkUsers(with: params) {
                                  BHLog.w("Failed to save network users")
                              }
                          }
                          
                          completion(.success(users: pu.users, page: pu.meta.page, pages: pu.meta.pages))
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
}
