
import Foundation

class NotificationInfoEpisodeObject: NotificationInfoPodcastObject, NotificationInfoEpisode {
    
    // MARK: - NotificationInfoBase
    
    override var groupIdentifier: String { return eventProperties.eventUuid }
    
    // MARK: - NotificationInfoEpisode
    
    var event: String { return eventProperties.event }
    var eventUuid: String { return eventProperties.eventUuid }
    var autoDownload: Bool { return eventProperties.autoDownload }
    
    // MARK: - Properties
    
    let eventProperties: NotificationInfoEpisodeProperties
    
    // MARK: - NotificationInfoObject
    
    required init?(from payload: NotificationInfo.Payload) {
        
        guard let eventProperties = NotificationInfoEpisodeProperties.init(with: payload) else { return nil }
        self.eventProperties = eventProperties
        
        super.init(from: payload)
    }
    
    override class func composePayload(with dataSource: NotificationInfoDataSource) -> NotificationInfo.Payload {
        
        guard let eventDataSource = dataSource as? NotificationInfoEpisodeDataSource else { return [:] }
        
        var payload = super.composePayload(with: dataSource)
        payload.merge(NotificationInfoEpisodeProperties.composePayload(from: eventDataSource)) { _, merged in merged }
        
        return payload
    }
    
    // MARK: - Initialization
    
    init(commonProperties: NotificationInfoCommonProperties, eventProperties: NotificationInfoEpisodeProperties, userProperties: NotificationInfoPodcastProperties) {
        
        self.eventProperties = eventProperties
        
        super.init(commonProperties: commonProperties, userProperties: userProperties)
    }
}

extension NotificationInfoEpisodeObject: NotificationInfoEpisodeDataSource {}

