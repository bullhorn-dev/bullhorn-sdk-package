
import Foundation

class NotificationInfoCommonObject: NotificationInfoObject, NotificationInfoCommon {

    // MARK: - NotificationInfoBase

    var categoryIdentifier: String { return payloadType.rawValue }
    var groupIdentifier: String { return UUID.init().uuidString }

    // MARK: - NotificationInfoObject

    lazy var payload: NotificationInfo.Payload? = self.composePayload()

    // MARK: - NotificationInfoCommon

    var payloadType: NotificationInfo.PayloadType { return commonProperties.payloadType }
    var badge: UInt? { return commonProperties.badge }
    var title: String { return commonProperties.title }
    var message: String { return composeBody() }

    // MARK: - Properties

    let commonProperties: NotificationInfoCommonProperties

    // MARK: - NotificationInfoObject

    required init?(from payload: NotificationInfo.Payload) {

        guard let commonProperties = NotificationInfoCommonProperties.init(with: payload) else { return nil }
        self.commonProperties = commonProperties

        self.payload = payload
    }

    class func composePayload(with dataSource: NotificationInfoDataSource) -> NotificationInfo.Payload {

        guard let commonDataSource = dataSource as? NotificationInfoCommonDataSource else { return [:] }

        return NotificationInfoCommonProperties.composePayload(from: commonDataSource)
    }

    // MARK: - Initialization

    init(commonProperties: NotificationInfoCommonProperties) {
        self.commonProperties = commonProperties
    }
    
    
    // MARK: - Public

    func composeBody() -> String { return commonProperties.message }
}

extension NotificationInfoCommonObject: NotificationInfoDataSource {}
