
import Foundation

protocol NotificationInfoCommon {

    var payloadType: NotificationInfo.PayloadType { get }
    var badge: UInt? { get }
    var title: String { get }
    var message: String { get }
}


protocol NotificationInfoCommonDataSource: NotificationInfoDataSource, NotificationInfoCommon {}


struct NotificationInfoCommonProperties: NotificationInfoCommon {

    // MARK: - NotificationInfoCommon

    let payloadType: NotificationInfo.PayloadType
    let badge: UInt?
    let title: String
    let message: String

    init?(with payload: NotificationInfo.Payload) {

        var payloadKey = NotificationInfo.DataKey.aps
        guard let aps = payload[payloadKey.rawValue] as? NSDictionary else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        payloadKey = .category
        guard let categoryValue = aps[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        guard let payloadType = NotificationInfo.PayloadType(rawValue: categoryValue) else {
            BHLog.w("\(#function) - Unknown notification category")
            return nil
        }
        
        payloadKey = .title
        guard let titleValue = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        payloadKey = .message
        guard let messageValue = payload[payloadKey.rawValue] as? String else {
            BHLog.w("\(#function) - Failed to read notification \(payloadKey)")
            return nil
        }

        self.payloadType = payloadType
        self.badge = nil
        self.title = titleValue
        self.message = messageValue
    }

    // MARK: - Initialization

    init(payloadType: NotificationInfo.PayloadType, badge: UInt?, title: String, message: String) {

        self.payloadType = payloadType
        self.badge = badge
        self.title = title
        self.message = message
    }

    // MARK: - Public

    static func composePayload(from source: NotificationInfoCommon) -> NotificationInfo.Payload {

        var payload = NotificationInfo.Payload.init()
        let apsValue: NotificationInfo.Payload = [NotificationInfo.DataKey.category.rawValue: source.payloadType.rawValue,
                                                  NotificationInfo.DataKey.mutableContent.rawValue: 1]
        payload[NotificationInfo.DataKey.aps.rawValue] = apsValue
        payload[NotificationInfo.DataKey.title.rawValue] = source.title
        payload[NotificationInfo.DataKey.message.rawValue] = source.message

        return payload
    }
}
