
import Foundation
internal import Alamofire

class BHServerApiSettings: BHServerApiBase {
    
    func getNotificationsUsers(authToken token: String, completion: @escaping (UsersResult) -> Void) {
        
        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "settings/notifications/users"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(token)
            
            AF.request(fullPath, method: .get, headers: headers)
                .validate()
                .responseDecodable( completionHandler: { (response: DataResponse<Users, AFError>) in
                    debugPrint(response)
                    switch response.result {
                    case .success(let u):
                        completion(.success(users: u.users))
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                })
        }
    }
    
    func enableUserNotifications(authToken: String?, userId: String, enable: Bool, _ completion: @escaping (UserResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let paramEnable = enable ? "on" : "off"
            let path = "settings/notifications/users/\(userId)/\(paramEnable)"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .post, headers: headers)
                .validate()
                .responseDecodable( completionHandler: { (response: DataResponse<User, AFError>) in
                    debugPrint(response)
                    switch response.result {
                    case .success(let u):
                        completion(.success(user: u.user))
                    case .failure(let error):
                        completion(.failure(error: error))
                    }
                })
        }
    }
}

