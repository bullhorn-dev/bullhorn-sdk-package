
import Foundation
internal import Alamofire

class BHServerApiCategories: BHServerApiBase {
        
    // MARK: - Categories Result

    struct Categories: Codable {
        
        enum CodingKeys: String, CodingKey {
            case categories = "categories"
        }
        
        var categories: [BHCategory]
    }

    enum CategoriesResult {
        case success(categories: [BHCategory])
        case failure(error: Error)
    }

    // MARK: - Public
    
    func getCategories(authToken: String?, networkId: String, _ completion: @escaping (CategoriesResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "categories?" + self.composeNetworkId(text: networkId)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  switch response.result {
                  case .success(let data):
                      do {
                          let c = try JSONDecoder().decode(Categories.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          let categories = try? c.categories.toDictionaryArray()
                          
                          let params: [String : Any] = [
                            "id": networkId,
                            "categories": categories ?? []
                          ]
                          
                          if !DataBaseManager.shared.insertOrUpdateCategories(with: params) {
                              BHLog.w("Failed to save categories")
                          }

                          completion(.success(categories: c.categories))
                      } catch let error {
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }
    
    func getCategoryUsers(authToken: String?, networkId: String, categoryId: Int, _ completion: @escaping (UsersResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }
            
            let path = "categories/\(categoryId)/users?network_id=\(networkId)"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
              .validate()
              .responseJSONAPI(completionHandler: { (response) in
                  switch response.result {
                  case .success(let data):
                      do {
                          let pu = try JSONDecoder().decode(Users.self, from: JSONSerialization.data(withJSONObject: data))
                          
                          let users = try? pu.users.toDictionaryArray()
                          
                          let params: [String : Any] = [
                            "id": categoryId,
                            "users": users ?? []
                          ]
                          
//                          if !DataBaseManager.shared.insertOrUpdateCategoryUsers(with: params) {
//                              BHLog.w("Failed to save network users")
//                          }

                          completion(.success(users: pu.users))
                      } catch let error {
                          completion(.failure(error: error))
                                          }
                  case .failure(let error):
                      completion(.failure(error: error))
                  }
              })
        }
    }

    func getCategoryPosts(authToken: String?, networkId: String, categoryId: Int, text: String?, pageSize: Int = 10, page: Int?, _ completion: @escaping (PaginatedPostsResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "categories/\(categoryId)/recent_episodes" + self.composePageFilter(page: page) +  self.composeTextFilter(text: text) + self.composePerPageFilter(perPage: pageSize) + self.composeNetworkId(text: networkId)
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseJSONAPI(completionHandler: { (response) in
                    switch response.result {
                    case .success(let data):
                        do {
                            let pp = try JSONDecoder().decode(PaginatedPosts.self, from: JSONSerialization.data(withJSONObject: data))
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
}

