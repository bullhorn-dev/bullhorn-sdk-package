
import Foundation
internal import Alamofire

class BHServerApiEvents: BHServerApiBase {

    // MARK: - Public
    
    func sendEvents(authToken: String?, clientId: String, events: [String: Any], _ completion: @escaping (CommonResult) -> Void) {

        updateConfig { (configError: ServerApiError?) in
            if let error = configError {
                completion(.failure(error: error))
                return
            }

            let path = "clients/\(clientId)/app_events"
            let fullPath = self.composeFullApiURL(with: path)
            let headers = self.composeHeaders(authToken)
            
            AF.request(fullPath, method: .post, parameters: events, encoding: JSONEncoding.default, headers: headers)
              .validate()
              .responseData(completionHandler: { response in
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

