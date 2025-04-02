
import UIKit
import Foundation

struct BHPushToken: Codable {

    enum CodingKeys: String, CodingKey {
        case pushToken = "push_token"
        case platform
        case osVersion = "os_version"
        case applicationVersion = "application_version"
        case environment
        case networkId = "network_id"
        case sdkId = "sdk_id"
    }

    enum Environment: String, Codable {
        case development = "development"
        case production = "production"
    }

    let pushToken: String
    let platform: String
    let osVersion: String
    let applicationVersion: String
    let environment: Environment
    let networkId: String
    let sdkId: String

    init(with token: String, networkId: String, sdkId: String, appVersion: String) {

        self.pushToken = token
        self.platform = "ios"
        self.osVersion = UIDevice.current.systemVersion
        self.applicationVersion = appVersion
        self.networkId = networkId
        self.sdkId = sdkId

#if DEBUG
        self.environment = .development
#else
        self.environment = .production
#endif
    }
    
    func params() -> [String : String] {
        return [
            CodingKeys.pushToken.rawValue: pushToken,
            CodingKeys.platform.rawValue: platform,
            CodingKeys.osVersion.rawValue: osVersion,
            CodingKeys.applicationVersion.rawValue: applicationVersion,
            CodingKeys.environment.rawValue: environment.rawValue,
            CodingKeys.networkId.rawValue: networkId,
            CodingKeys.sdkId.rawValue: sdkId
        ]
    }
}
