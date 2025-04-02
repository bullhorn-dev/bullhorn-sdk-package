
import Foundation

class BHBulletinManager {

    static let shared = BHBulletinManager()

    var dispatchQueue = DispatchQueue.global()
    
    fileprivate var authToken: String {
        return BHAccountManager.shared.authToken
    }
    
    fileprivate lazy var server = BHServerApiBulletin.init(withApiType: .interactive)

    var bulletin: BHBulletin?
    var videoEvents: [BHBulletinVideoEvent]?
    var layout: BHBulletinLayout?

    fileprivate var _messages: [BHBulletinMessage]?
    fileprivate var _questions: [BHBulletinQuestion]?
    
    var messages: [BHBulletinMessage] {
        guard let items = _messages else { return [] }
            
        return items.sorted(by: { lhs, rhs in
            return lhs.createdDate.timeIntervalSince1970 < rhs.createdDate.timeIntervalSince1970
        })
    }
    
    var questions: [BHBulletinQuestion] {
        guard let items = _questions else { return [] }
        
        return items.sorted(by: { lhs, rhs in
            return lhs.likes > rhs.likes
        })
    }

    init() {
        self._messages = nil
        self._questions = nil
    }
    
    func reset() {
        self.bulletin = nil
        self.layout = nil
        self.videoEvents = nil
        self._messages = nil
        self._questions = nil
    }
    
    // MARK: - Public
    
    func getBulletin(_ bulletinId: String, allIncludes: Bool = false, completion: @escaping (BHServerApiBulletin.BulletinResult) -> Void) {
        
        server.getBulletin(authToken: authToken, bulletinId: bulletinId, allIncludes: allIncludes) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(bulletin: let bulletin):
                    self.bulletin = bulletin
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    func getBulletinTile(_ tileId: String, completion: @escaping (BHServerApiBulletin.BulletinTileResult) -> Void) {
        
        server.getBulletinTile(authToken: authToken, tileId: tileId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(tile: let tile):
                    self.bulletin?.updateTile(tile)
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    func choosePollVariant(_ variantId: String, completion: @escaping (BHServerApiBulletin.BulletinPollVariantResult) -> Void) {
        
        server.choosePollVariant(authToken: authToken, variantId: variantId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(variant: let variant):
                    self.bulletin?.updatePollVariant(variant)
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }

    func getVideoEvents(_ bulletinId: String, completion: @escaping (BHServerApiBulletin.BulletinVideoEventsResult) -> Void) {
        
        server.getVideoEvents(authToken: authToken, bulletinId: bulletinId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(events: let events):
                    self.videoEvents = events
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    func getMessages(_ bulletinId: String, completion: @escaping (BHServerApiBulletin.BulletinMessagesResult) -> Void) {
        
        server.getMessages(authToken: authToken, bulletinId: bulletinId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(events: let events):
                    self._messages = events
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    func createMessage(_ bulletinId: String, text: String, completion: @escaping (BHServerApiBulletin.BulletinMessageResult) -> Void) {
        
        server.createMessage(authToken: authToken, bulletinId: bulletinId, text: text) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(message: let message):
                    self._messages?.append(message)
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }

    func getQuestions(_ bulletinId: String, completion: @escaping (BHServerApiBulletin.BulletinQuestionsResult) -> Void) {
        
        server.getQuestions(authToken: authToken, bulletinId: bulletinId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(events: let events):
                    self._questions = events
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }

    func createQuestion(_ bulletinId: String, text: String, completion: @escaping (BHServerApiBulletin.BulletinQuestionResult) -> Void) {
        
        server.createQuestion(authToken: authToken, bulletinId: bulletinId, text: text) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(question: let question):
                    self._questions?.append(question)
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }

    func toggleQuestionLike(_ questionId: String, completion: @escaping (BHServerApiBulletin.BulletinQuestionResult) -> Void) {
        
        server.toggleQuestionLike(authToken: authToken, questionId: questionId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(question: let question):
                    if let index = self._questions?.firstIndex(where: { $0.id == question.id }) {
                        self._questions?[index] = question
                    }
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }

    func getLayoutEvents(_ bulletinId: String, completion: @escaping (BHServerApiBulletin.BulletinLayoutEventsResult) -> Void) {
        
        server.getLayouts(authToken: authToken, bulletinId: bulletinId) { response in
            self.dispatchQueue.async {
                switch response {
                case .success(events: let events):
                    self.layout = BHBulletinLayout(events: events)
                case .failure(error: _):
                    break
                }
                completion(response)
            }
        }
    }
    
    // MARK: - Initial fetch for player
    
    func fetch(_ bulletinId: String, completion: @escaping (CommonResult) -> Void) {
                
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()
        
        getBulletin(bulletinId, allIncludes: true) { response in
            switch response {
            case .success(bulletin: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getVideoEvents(bulletinId) { response in
            switch response {
            case .success(events: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getLayoutEvents(bulletinId) { response in
            switch response {
            case .success(events: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getMessages(bulletinId) { response in
            switch response {
            case .success(events: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }
        
        fetchGroup.enter()
        
        getQuestions(bulletinId) { response in
            switch response {
            case .success(events: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.notify(queue: .main) {
            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
}
