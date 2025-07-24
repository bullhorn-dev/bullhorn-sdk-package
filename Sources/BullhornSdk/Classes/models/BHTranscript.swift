
import Foundation

// MARK: - Transcript segment

struct BHSegment: Codable {
    
    enum CodingKeys: String, CodingKey {
        case start
        case end
        case text
    }
    
    let start: Double
    let end: Double
    let text: String
    
    func contain(_ position: Double) -> Bool {
        if start <= position && end > position {
            return true
        }
        return false
    }
}

// MARK: - Post Transcript

class BHTranscript: Codable {
    
    enum CodingKeys: String, CodingKey {
        case id
        case duration
        case postId = "post_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case segments
    }
    
    let id: String
    var postId: Int
    var duration: Double
    var createdAt: String
    var updatedAt: String
    let segments: [BHSegment]

    init(id: String, postId: Int, duration: Double, createdAt: String, updatedAt: String, segments: [BHSegment]) {
        self.id = id
        self.postId = postId
        self.duration = duration
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.segments = segments
    }
    
    func segmentIndex(for position: Double) -> Int {
        return segments.firstIndex(where: { $0.contain(position) }) ?? -1
    }
}

