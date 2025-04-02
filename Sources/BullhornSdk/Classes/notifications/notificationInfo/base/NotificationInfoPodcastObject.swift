
import Foundation

class NotificationInfoPodcastObject: NotificationInfoCommonObject, NotificationInfoPodcast {

    // MARK: - NotificationInfoBase
    
    override var groupIdentifier: String { return userProperties.userUuid }

    // MARK: - NotificationInfoPodcast

    var user: String { return userProperties.user }
    var userUuid: String { return userProperties.userUuid }
    var userPictureURL: URL? { return userProperties.userPictureURL }

    // MARK: - Properties

    let userProperties: NotificationInfoPodcastProperties

    // MARK: - NotificationInfoObject

    required init?(from payload: NotificationInfo.Payload) {

        guard let userProperties = NotificationInfoPodcastProperties.init(with: payload) else { return nil }
        self.userProperties = userProperties

        super.init(from: payload)
    }

    override class func composePayload(with dataSource: NotificationInfoDataSource) -> NotificationInfo.Payload {

        guard let userDataSource = dataSource as? NotificationInfoPodcastDataSource else { return [:] }

        var payload = super.composePayload(with: dataSource)
        payload.merge(NotificationInfoPodcastProperties.composePayload(from: userDataSource)) { _, merged in merged }

        return payload
    }

    // MARK: - Initialization

    init(commonProperties: NotificationInfoCommonProperties, userProperties: NotificationInfoPodcastProperties) {

        self.userProperties = userProperties

        super.init(commonProperties: commonProperties)
    }
}

extension NotificationInfoPodcastObject: NotificationInfoPodcastDataSource {}
