
import Foundation
internal import Alamofire

class BHServerApiBulletin: BHServerApiBase {

    enum BulletinResult {
        case success(bulletin: BHBulletin)
        case failure(error: Error)
    }

    enum BulletinTileResult {
        case success(tile: BHBulletinTile)
        case failure(error: Error)
    }

    enum BulletinPollVariantResult {
        case success(variant: BHBulletinPollVariant)
        case failure(error: Error)
    }

    enum BulletinVideoEventsResult {
        case success(events: [BHBulletinVideoEvent])
        case failure(error: Error)
    }

    enum BulletinMessagesResult {
        case success(events: [BHBulletinMessage])
        case failure(error: Error)
    }

    enum BulletinMessageResult {
        case success(message: BHBulletinMessage)
        case failure(error: Error)
    }

    enum BulletinQuestionsResult {
        case success(events: [BHBulletinQuestion])
        case failure(error: Error)
    }

    enum BulletinQuestionResult {
        case success(question: BHBulletinQuestion)
        case failure(error: Error)
    }

    enum BulletinLayoutEventsResult {
        case success(events: [BHBulletinLayoutEvent])
        case failure(error: Error)
    }

    enum Includes: String {
        case bulletinEvents = "bulletin_events.bulletin_tile.poll_variants"
        case preShowEvents = "pre_show_events.bulletin_tile.poll_variants"
        case messages = "messages.user"
        case questions = "questions.user,questions.questions_events"

        static func firstOnly() -> String { return Includes.bulletinEvents.rawValue }
        static func all() -> String { return "\(Includes.bulletinEvents.rawValue),\(Includes.preShowEvents.rawValue),\(Includes.messages.rawValue),\(Includes.questions.rawValue)" }
    }

    // MARK: - Public

    func getBulletin(authToken: String?, bulletinId: String, allIncludes: Bool, _ completion: @escaping (BulletinResult) -> Void) {

        let path =  "bulletins/\(bulletinId)"
        let fullPath = composeFullApiURL(with: path)

        let include = allIncludes ? Includes.all() : Includes.firstOnly()
        let parameters = composeIncluded(include)

        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: parameters, headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: include, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletin, AFError>) in
              switch response.result {
              case .success(let bulletin):
                  completion(.success(bulletin: bulletin))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
    
    func getBulletinTile(authToken: String?, tileId: String, _ completion: @escaping (BulletinTileResult) -> Void) {

        let path =  "bulletin_tiles/\(tileId)"
        let fullPath = composeFullApiURL(with: path)

        let include = "poll_variants"
        let parameters = composeIncluded(include)

        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: parameters, headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: include, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletinTile, AFError>) in
              
              debugPrint("\(response)")

              switch response.result {
              case .success(let tile):
                  completion(.success(tile: tile))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }

    func choosePollVariant(authToken: String?, variantId: String, _ completion: @escaping (BulletinPollVariantResult) -> Void) {

        let path =  "poll_variants/\(variantId)/users_answers"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .post, parameters: [:], headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletinPollVariant, AFError>) in
              
              debugPrint("\(response)")
              
              switch response.result {
              case .success(let variant):
                  completion(.success(variant: variant))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }

    func getQuestions(authToken: String?, bulletinId: String, _ completion: @escaping (BulletinQuestionsResult) -> Void) {
        
        let path =  "bulletins/\(bulletinId)/questions?include=user,questions_events&filter[paginate]=false&sort=created_at"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: [:], headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<[BHBulletinQuestion], AFError>) in
              
              debugPrint(response)

              switch response.result {
              case .success(let events):
                  completion(.success(events: events))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }
    
    func createQuestion(authToken: String?, bulletinId: String, text: String, _ completion: @escaping (BulletinQuestionResult) -> Void) {
        
        let path =  "bulletins/\(bulletinId)/questions"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        let attributes = ["text" : text]
        let data: [String : Any] = ["type" : "question", "attributes" : attributes]
        let body: [String : Any] = ["data" : data]
        
        AF.request(fullPath, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletinQuestion, AFError>) in
              
              debugPrint(response)

              switch response.result {
              case .success(let question):
                  completion(.success(question: question))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }
    
    func toggleQuestionLike(authToken: String?, questionId: String, _ completion: @escaping (BulletinQuestionResult) -> Void) {
        
        let path =  "questions/\(questionId)/like"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
                
        AF.request(fullPath, method: .put, parameters: [:], encoding: JSONEncoding.default, headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletinQuestion, AFError>) in
              
              debugPrint(response)

              switch response.result {
              case .success(let question):
                  completion(.success(question: question))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }

    func getMessages(authToken: String?, bulletinId: String, _ completion: @escaping (BulletinMessagesResult) -> Void) {
        
        // TODO: - add pagination
        let page: Int = 1
        let size: Int = 50

        let path =  "bulletins/\(bulletinId)/messages?include=user,reactions&page[number]=\(page)&page[size]=\(size)"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: [:], headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<[BHBulletinMessage], AFError>) in
              
              debugPrint(response)

              switch response.result {
              case .success(let events):
                  completion(.success(events: events))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }
    
    func createMessage(authToken: String?, bulletinId: String, text: String, _ completion: @escaping (BulletinMessageResult) -> Void) {
        
        let path =  "bulletins/\(bulletinId)/messages"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        let attributes = ["text" : text]
        let data: [String : Any] = ["type" : "message", "attributes" : attributes]
        let body: [String : Any] = ["data" : data]
        
        AF.request(fullPath, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<BHBulletinMessage, AFError>) in
              
              debugPrint(response)

              switch response.result {
              case .success(let message):
                  completion(.success(message: message))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }

    func getVideoEvents(authToken: String?, bulletinId: String, _ completion: @escaping (BulletinVideoEventsResult) -> Void) {
        
        let path =  "bulletins/\(bulletinId)/video_events"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: [:], headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<[BHBulletinVideoEvent], AFError>) in
              switch response.result {
              case .success(let events):
                  completion(.success(events: events))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          }
        )
    }

    func getLayouts(authToken: String?, bulletinId: String, _ completion: @escaping (BulletinLayoutEventsResult) -> Void) {

        let path =  "bulletins/\(bulletinId)/layouts"
        let fullPath = composeFullApiURL(with: path)
        let headers = composeHeaders(authToken)
        
        AF.request(fullPath, method: .get, parameters: [:], headers: headers)
          .validate()
          .responseCodableJSONAPI(includeList: nil, keyPath: "data", completionHandler: { (response: DataResponse<[BHBulletinLayoutEvent], AFError>) in
              switch response.result {
              case .success(let events):
                  completion(.success(events: events))
              case .failure(let error):
                  self.trackError(url: fullPath, error: error)
                  completion(.failure(error: error))
              }
          })
    }
}
