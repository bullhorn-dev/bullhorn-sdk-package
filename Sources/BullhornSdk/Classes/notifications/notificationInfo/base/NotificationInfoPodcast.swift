
import Foundation

protocol NotificationInfoPodcast {

    var user: String { get }
    var userUuid: String { get }
    var userPictureURL: URL? { get }
}


protocol NotificationInfoPodcastDataSource: NotificationInfoCommonDataSource, NotificationInfoPodcast {}


struct NotificationInfoPodcastProperties: NotificationInfoPodcast {

    // MARK: - NotificationInfoPodcast

    let user: String
    let userUuid: String
    let userPictureURL: URL?

    init?(with payload: NotificationInfo.Payload) {

        var payloadKey = NotificationInfo.DataKey.user
        guard let validUser = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        payloadKey = .userUuid
        guard let validUserUuid = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        user = validUser
        userUuid = validUserUuid

        payloadKey = .userPicture
        userPictureURL = (payload[payloadKey.rawValue] as? String).flatMap { URL.init(string: $0) }
    }

    // MARK: - Initialization

    init(user: String, userUuid: String, userPictureURL: URL?) {

        self.user = user
        self.userUuid = userUuid
        self.userPictureURL = userPictureURL
    }

    // MARK: - Public

    static func composePayload(from source: NotificationInfoPodcast) -> NotificationInfo.Payload {

        var payload = NotificationInfo.Payload.init()
        payload[NotificationInfo.DataKey.user.rawValue] = source.user
        payload[NotificationInfo.DataKey.userUuid.rawValue] = source.userUuid

        if let validUserPictureValue = source.userPictureURL?.absoluteString {
            payload[NotificationInfo.DataKey.userPicture.rawValue] = validUserPictureValue
        }

        return payload
    }
}
