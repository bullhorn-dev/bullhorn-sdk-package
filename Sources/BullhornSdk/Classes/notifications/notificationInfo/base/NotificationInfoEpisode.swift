
import Foundation

protocol NotificationInfoEpisode {
    
    var event: String { get }
    var eventUuid: String { get }
    var autoDownload: Bool { get }
}


protocol NotificationInfoEpisodeDataSource: NotificationInfoPodcastDataSource, NotificationInfoEpisode {}


struct NotificationInfoEpisodeProperties: NotificationInfoEpisode {
    
    // MARK: - NotificationInfoEpisode
    
    let event: String
    let eventUuid: String
    let autoDownload: Bool
    
    init?(with payload: NotificationInfo.Payload) {
        
        var payloadKey = NotificationInfo.DataKey.event
        guard let validEvent = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }
        
        payloadKey = .eventUuid
        guard let validEventUuid = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }
        
        payloadKey = .autoDownload
        let validAutoDownload = payload[payloadKey.rawValue] as? Bool ?? false
        
        event = validEvent
        eventUuid = validEventUuid
        autoDownload = validAutoDownload
    }
    
    // MARK: - Initialization
    
    init(event: String, eventUuid: String, autoDownload: Bool) {
        
        self.event = event
        self.eventUuid = eventUuid
        self.autoDownload = autoDownload
    }
    
    // MARK: - Public
    
    static func composePayload(from source: NotificationInfoEpisode) -> NotificationInfo.Payload {
        
        var payload = NotificationInfo.Payload.init()
        payload[NotificationInfo.DataKey.event.rawValue] = source.event
        payload[NotificationInfo.DataKey.eventUuid.rawValue] = source.eventUuid
        payload[NotificationInfo.DataKey.autoDownload.rawValue] = source.autoDownload
        
        return payload
    }
}
