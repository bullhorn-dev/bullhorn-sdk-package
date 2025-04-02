
import Foundation

public enum BHAppConfigType: String {
    case prod = "AppConfigurationTypePROD"
    case qa =   "AppConfigurationTypeQA"
}

public class BHAppConfiguration {

    private static let KeyWebConfigURL = "web_config_url"
    private static let KeyWebSiteURL1 = "web_site_url_1"
    private static let KeyWebSiteURL2 = "web_site_url_2"
    private static let KeyCustomScheme = "custom_scheme"

    private static let prodDefaults = [
        BHAppConfiguration.KeyWebConfigURL:     "https://bullhorn.fm/bullhorn_app_config.json",
        BHAppConfiguration.KeyWebSiteURL1:      "https://l.bullhorn.fm",
        BHAppConfiguration.KeyWebSiteURL2:      "https://www.l.bullhorn.fm",
        BHAppConfiguration.KeyCustomScheme:     "bullhorn"]

    private static let qaDefaults = [
        BHAppConfiguration.KeyWebConfigURL:     "https://qa-www.bullhorn.fm/bullhorn_app_config.json",
        BHAppConfiguration.KeyWebSiteURL1:      "https://qa-www.bullhorn.fm",
        BHAppConfiguration.KeyWebSiteURL2:      "https://qa-www.bullhorn.fm",
        BHAppConfiguration.KeyCustomScheme:     "bullhorn-qa"]

    static let shared: BHAppConfiguration = BHAppConfiguration()
    
    static var type: BHAppConfigType = .prod

    var appBundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? ""
    }

    var appStoreAppleAppID: String {
        return "1322513763"
    }

    var appStoreURLString: String {
        return "https://itunes.apple.com/us/app/bullhorn/id\(appStoreAppleAppID)?ls=1&mt=8"
    }

    var webConfigURLString: String {
        return configDictionary[BHAppConfiguration.KeyWebConfigURL] as? String ?? ""
    }

    var webSiteURL1String: String {
        return configDictionary[BHAppConfiguration.KeyWebSiteURL1] as? String ?? ""
    }

    var webSiteURL2String: String {
        return configDictionary[BHAppConfiguration.KeyWebSiteURL2] as? String ?? ""
    }
    
    var customSchemeString: String {
        return configDictionary[BHAppConfiguration.KeyCustomScheme] as? String ?? ""
    }

    var serverApiURLString: String {
        return BHConfigManager.shared.configData?.serverApiV1String ?? ""
    }

    var serverApiInteractiveURLString: String {
        return BHConfigManager.shared.configData?.serverApiInteractiveV1String ?? ""
    }
    
    var serverApiSdkV1String: String {
        return BHConfigManager.shared.configData?.serverApiSdkV1String ?? ""
    }

    var foxNetworkId: String {
        switch BHAppConfiguration.type {
        case .qa:
            return "be2901fe-8b37-4597-89ff-63a2931a631f"
        case .prod:
            return BullhornSdk.shared.networkId
        }
    }

    var typeString: String {
        switch BHAppConfiguration.type {
        case .qa:
            return "qa"
        case .prod:
            return "prod"
        }
    }

    private let configDictionary: [String: Any]
    
    init() {

        switch BHAppConfiguration.type {
        case .prod: configDictionary = BHAppConfiguration.prodDefaults
        case .qa: configDictionary = BHAppConfiguration.qaDefaults
        }
    }

    public func appVersion(useBuildNumber: Bool = false) -> String {

        var fullVersion = ""

        if let bundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            fullVersion = bundleVersion
        }

        let useBuildNumberResult: Bool

        switch BHAppConfiguration.type {
        case _ where useBuildNumber: useBuildNumberResult = true
        case .qa: useBuildNumberResult = true
        default: useBuildNumberResult = false
        }

        if useBuildNumberResult, let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            fullVersion += " (\(buildNumber))"
        }

        switch BHAppConfiguration.type {
        case .qa: fullVersion += " QA"
        default: break
        }

        return fullVersion
    }
}
