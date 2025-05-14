
import Foundation

class BHPostPlayback: Codable, Hashable {

    enum CodingKeys: String, CodingKey {
        case uuid
        case episodeId = "episode_id"
        case episodeTitle = "episode_title"
        case episodeType = "episode_type"
        case podcastId = "podcast_id"
        case podcastTitle = "podcast_title"
        case startedAt = "started_at"
        case finishedAt = "finished_at"
    }

    let uuid: String
    let episodeId: String
    let episodeTitle: String
    let episodeType: String
    let podcastId: String
    let podcastTitle: String
    let startedAt: TimeInterval
    var finishedAt: TimeInterval
    
    var description: String {
        return "uuid=\(uuid), episodeId=\(episodeId), startedAt=\(startedAt), finishedAt=\(finishedAt)"
    }
    
    // MARK: - Initializers
    
    init(identifier: String, episodeId: String, episodeTitle: String, episodeType: String, podcastId: String, podcastTitle: String, startTime: TimeInterval, endTime: TimeInterval) {
        self.uuid = identifier
        self.episodeId = episodeId
        self.episodeTitle = episodeTitle
        self.episodeType = episodeType
        self.podcastId = podcastId
        self.podcastTitle = podcastTitle
        self.startedAt = startTime
        self.finishedAt = endTime
    }
    
    // MARK: Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(uuid.hashValue)
    }
    
    public static func ==(lhs: BHPostPlayback, rhs: BHPostPlayback) -> Bool {
        return lhs.uuid == rhs.uuid && lhs.episodeId == rhs.episodeId && lhs.startedAt == rhs.startedAt && lhs.finishedAt == rhs.finishedAt
    }
    
    // MARK: - Utils
    
    func toJson() -> [String: Any] {
        
        let params: [String: Any] = [
            CodingKeys.uuid.rawValue: uuid,
            CodingKeys.episodeId.rawValue: episodeId,
            CodingKeys.episodeTitle.rawValue: episodeTitle,
            CodingKeys.episodeType.rawValue: episodeType,
            CodingKeys.podcastId.rawValue: podcastId,
            CodingKeys.podcastTitle.rawValue: podcastTitle,
            CodingKeys.startedAt.rawValue: startedAt,
            CodingKeys.finishedAt.rawValue: finishedAt]
        
        return params
    }

    static func fromJson(_ params: [String: Any]) -> BHPostPlayback? {
        guard let uuid = params[CodingKeys.uuid.rawValue] as? String else { return nil }
        guard let episodeId = params[CodingKeys.episodeId.rawValue] as? String else { return nil }
        guard let episodeTitle = params[CodingKeys.episodeTitle.rawValue] as? String else { return nil }
        guard let episodeType = params[CodingKeys.episodeType.rawValue] as? String else { return nil }
        guard let podcastId = params[CodingKeys.podcastId.rawValue] as? String else { return nil }
        guard let podcastTitle = params[CodingKeys.podcastTitle.rawValue] as? String else { return nil }
        guard let startedAt = params[CodingKeys.startedAt.rawValue] as? Double else { return nil }
        guard let finishedAt = params[CodingKeys.finishedAt.rawValue] as? Double else { return nil }

        return BHPostPlayback(identifier: uuid, episodeId: episodeId, episodeTitle: episodeTitle, episodeType: episodeType, podcastId: podcastId, podcastTitle: podcastTitle, startTime: startedAt, endTime: finishedAt)
    }

}

