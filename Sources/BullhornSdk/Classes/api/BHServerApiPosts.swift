
import Foundation
internal import Alamofire
import CoreTelephony

class BHServerApiPosts: BHServerApiBase {
    
    // MARK: - Post Result

    struct Post: Codable {
        
        enum CodingKeys: String, CodingKey {
            case post
        }
        
        let post: BHPost
    }
    
    enum PostResult {
        case success(post: BHPost)
        case failure(error: Error)
    }

    // MARK: - Phone Number Result

    struct PhoneNumber: Codable {
        
        enum CodingKeys: String, CodingKey {
            case data
        }
        
        let data: BHPhoneNumber
    }

    enum PhoneNumberResult {
        case success(phoneNumber: BHPhoneNumber)
        case failure(error: Error)
    }

    // MARK: - Playback Offset Result

    struct PlaybackOffset: Codable {
        
        enum CodingKeys: String, CodingKey {
            case playbackOffset = "playback_offset"
        }
        
        let playbackOffset: BHPlaybackOffset
    }

    enum PlaybackOffsetResult {
        case success(offset: BHPlaybackOffset)
        case failure(error: Error)
    }
    
    // MARK: - Public

    func getPost(authToken: String?, postId: String, context: String?, _ completion: @escaping (PostResult) -> Void) {

        let path = "posts/\(postId)" + composeContext(text: context)
        let fullPath = composeFullApiURL(with: path)
        let headers = self.composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, headers: headers)
          .validate()
          .responseJSONAPI(completionHandler: { (response) in
              switch response.result {
              case .success(let data):
                  do {
                      let p = try JSONDecoder().decode(Post.self, from: JSONSerialization.data(withJSONObject: data))
                      
                      guard let postJSON = data["post"] as? [String: Any] else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse post data", data: data)
                      }

                      if !DataBaseManager.shared.insertOrUpdatePost(with: postJSON) {
                          BHLog.w("Save post to storage failed")
                      }
                      
                      completion(.success(post: p.post))
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
    
    func getPostByAlias(authToken: String?, username: String, postAlias: String, _ completion: @escaping (PostResult) -> Void) {

        let path = "users/\(username)/posts/\(postAlias)"
        let fullPath = composeFullApiURL(with: path)
        let headers = self.composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, headers: headers)
          .validate()
          .responseJSONAPI(completionHandler: { (response) in
              switch response.result {
              case .success(let data):
                  do {
                      let p = try JSONDecoder().decode(Post.self, from: JSONSerialization.data(withJSONObject: data))
                      
                      guard let postJSON = data["post"] as? [String: Any] else {
                          throw ServerApiError.parseError(m: "\(#function): Failed to parse post data", data: data)
                      }

                      if !DataBaseManager.shared.insertOrUpdatePost(with: postJSON) {
                          BHLog.w("Save post to storage failed")
                      }
                      
                      completion(.success(post: p.post))
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

    func postLikeOn(authToken: String?, postId: String, _ completion: @escaping (PostResult) -> Void) {

        let path = "posts/\(postId)/like/on"
        let fullPath = composeFullApiURL(with: path)
        let headers = self.composeHeaders(authToken)
        
        AF.request(fullPath, method: .post, headers: headers)
          .validate()
          .responseDecodable(of: Post.self, completionHandler: { response in
              switch response.result {
              case .success(let p):
                  completion(.success(post: p.post))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func postLikeOff(authToken: String?, postId: String, _ completion: @escaping (PostResult) -> Void) {

        let path = "posts/\(postId)/like/off"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .post, headers: headers)
          .validate()
          .responseDecodable(of: Post.self, completionHandler: { response in
              switch response.result {
              case .success(let p):
                  completion(.success(post: p.post))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func postPlaybackOffset(authToken: String?, postId: String, parameters: Parameters, _ completion: @escaping (PlaybackOffsetResult) -> Void) {
        
        let path = "posts/\(postId)/playback_offset"
        let fullPath = composeFullApiURL(with: path)
        let headers = composePostHeaders(authToken)

        AF.request(fullPath, method: .put, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
          .validate()
          .responseDecodable(of: PlaybackOffset.self, completionHandler: { response in
              switch response.result {
              case .success(let offset):
                  completion(.success(offset: offset.playbackOffset))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }

    func getPlaybackOffset(authToken: String?, postId: String, timestamp: Double, offset: Double, _ completion: @escaping (PlaybackOffsetResult) -> Void) {
        
        let path = "posts/\(postId)/playback_offset" + "?timestamp=\(timestamp)" + "&offset=\(offset)"
        let fullPath = composeFullApiURL(with: path)
        let headers = composePostHeaders(authToken)

        AF.request(fullPath, method: .get, headers: headers)
          .validate()
          .responseDecodable(of: PlaybackOffset.self, completionHandler: { response in
              switch response.result {
              case .success(let offset):
                  completion(.success(offset: offset.playbackOffset))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func getPhoneNumber (authToken: String?, postId: String, position: Double, _ completion: @escaping (PhoneNumberResult) -> Void) {
        let mobileInfo = getMobileInfo()
        var body: [String : String] = [
            "mcc": mobileInfo.mcc,
            "mnc": mobileInfo.mnc
        ]

        if (position > 0) {
            body["playback_offset"] = "\(position)"
        }

        let path = "posts/\(postId)/phone_number"
        let fullPath = composeFullApiURL(with: path)
        let headers = composePostHeaders(authToken)
        
        AF.request(fullPath, method: .post, parameters: body, headers: headers)
          .validate()
          .responseDecodable(of: PhoneNumber.self, completionHandler: { response in
              switch response.result {
              case .success(let phoneNumber):
                  completion(.success(phoneNumber: phoneNumber.data))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
    
    // MARK: - Private
    
    private func getMobileInfo() -> (mcc: String, mnc: String, callingCode: Int) {
        
        let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        let mcc = carrier?.mobileCountryCode ?? ""
        let mnc = carrier?.mobileNetworkCode ?? ""

        let countryCodeIso2 = carrier?.isoCountryCode ?? ""
        let countryCallingCode = CountryCallingCode.init(withAlpha2: countryCodeIso2)
        let callingCode = Int(countryCallingCode?.callingCode ?? "1") ?? 1

        BHLog.p("\(#function) - mcc = \(mcc), mnc = \(mnc), callingCode = \(callingCode)")

        return (mcc: mcc, mnc: mnc, callingCode: callingCode)
    }
}
