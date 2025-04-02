
import Foundation

// MARK: Common notifications

class NewEpisodesReminderNotificationInfo: NotificationInfoCommonObject {
    
    override var groupIdentifier: String { return "BullhornSdk.NewEpisodesReminder" }
}

class MassNotificationInfo: NotificationInfoCommonObject {
    
    override var groupIdentifier: String { return "BullhornSdk.MassNotification" }
}

// MARK: - Episode notifications

class NewEpisodeNotificationInfo: NotificationInfoEpisodeObject {

    override var groupIdentifier: String { return userUuid }
}

class LiveEpisodeMeetingRoomNotificationInfo: NotificationInfoEpisodeObject {

    override var groupIdentifier: String { return userUuid }
}

class LiveEpisodeScheduledNotificationInfo: NotificationInfoEpisodeObject {

    override var groupIdentifier: String { return userUuid }
    
    fileprivate let scheduledAt: TimeInterval

    required init?(from payload: NotificationInfo.Payload) {

        let payloadKey = NotificationInfo.DataKey.scheduledAt

        scheduledAt = payload[payloadKey.rawValue] as? Double ?? Date().timeIntervalSince1970

        super.init(from: payload)
    }
    
    override func composeBody() -> String {

        var body = commonProperties.message

        let date = Date(timeIntervalSince1970: scheduledAt)
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MMM dd"
        body = body.replacingOccurrences(of: "<date>", with: dateFormatter.string(from: date))

        dateFormatter.dateFormat = "hh:mm a"
        body = body.replacingOccurrences(of: "<time>", with: dateFormatter.string(from: date))

        return body
    }
}

class LiveEpisodeStartedNotificationInfo: NotificationInfoEpisodeObject {

    override var groupIdentifier: String { return userUuid }
}
