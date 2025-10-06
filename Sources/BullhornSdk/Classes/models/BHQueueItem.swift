
import Foundation

enum BHQueueReason: Int, Codable {
    case manually = 0
    case auto
}

class BHQueueItem: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case post
        case reason
    }
    
    let id: String
    var post: BHPost
    let reason: BHQueueReason
    
    init(id: String, post: BHPost, reason: BHQueueReason) {
        
        self.id = id
        self.post = post
        self.reason = reason
    }
}

