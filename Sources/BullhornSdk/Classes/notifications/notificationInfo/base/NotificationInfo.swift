
import Foundation

protocol NotificationInfoBase {

    var title: String { get }
    var message: String { get }
    var categoryIdentifier: String { get }
    var groupIdentifier: String { get }
}

protocol NotificationInfoDataSource {}


protocol NotificationInfoObject: AnyObject, NotificationInfoBase, NotificationInfoDataSource {

    var payload: NotificationInfo.Payload? { get }

    init?(from payload: NotificationInfo.Payload)

    func composePayload() -> NotificationInfo.Payload
    static func composePayload(with dataSource: NotificationInfoDataSource) -> NotificationInfo.Payload
}

extension NotificationInfoObject {

    func composePayload() -> NotificationInfo.Payload {
        return createPayload(for: type(of: self), with: self)
    }

    fileprivate func createPayload(for objectType: NotificationInfoObject.Type, with dataSource: NotificationInfoDataSource) -> NotificationInfo.Payload {
        return objectType.composePayload(with: dataSource)
    }
}

struct NotificationInfo {

    typealias Payload = [AnyHashable: Any]

    enum DataKey: String {
        case aps = "aps"
        case category = "category"
        case badge = "badge"
        case mutableContent = "mutable-content"
        case user = "user"
        case userUuid = "user_uuid"
        case userPicture = "user_picture"
        case event = "event"
        case eventUuid = "event_uuid"
        case title = "title"
        case message = "message"
        case batchSize = "batch_size"
        case autoDownload = "auto_download"
        case startTime = "start_time"
        case scheduledAt = "scheduled_at"
    }

    enum PayloadType: String {
        case newEpisodeInvitation   = "NEW_EPISODE_INVITATION"
        case newEpisodesReminder    = "NEW_EPISODES_REMINDER"
        case liveEpisodeStarted     = "LIVE_EPISODE_STARTED"
        case liveEpisodeScheduled   = "LIVE_EPISODE_SCHEDULED"
        case liveEpisodeMeetingRoom = "LIVE_EPISODE_WAITING_ROOM"
        case massNotification       = "MASS_NOTIFICATION"
        case downloadEpisode        = "DOWNLOAD_EPISODE"
    }
}

