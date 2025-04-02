
import Foundation

struct BHConfigBody: Equatable {

    enum UpdateState {
        case ok
        case updateAvailable
        case updateRequired
    }

    let serverApiV1String: String
    let serverApiInteractiveV1String: String
    let serverApiSdkV1String: String
    let version: Version
    let updateState: UpdateState
    let changelogURLString: String?
    
    static func fromJSON(_ jsonObject: Any) -> BHConfigBody? {

        guard let rootDictionary = jsonObject as? [String: Any] else { return nil }

        var serverApiV1String: String?
        var serverApiInteractiveV1String: String?
        var serverApiSdkV1String: String?
        var versionString: String?
        var forceUpdateVersionString: String?
        var changelogURLString: String?

        if let packagesArray = rootDictionary["packages"] as? [Any] {
            for package in packagesArray {
                if let packageDictionary = package as? [String: Any], packageDictionary["platform"] as? String == "ios" {
                    versionString = packageDictionary["version"] as? String
                    changelogURLString = packageDictionary["changelog_url"] as? String
                    forceUpdateVersionString = packageDictionary["force_update_version"] as? String
                }
            }
        }

        if let apiArray = rootDictionary["api"] as? [Any] {
            for apiEntry in apiArray {
                if let apiEntryDictionary = apiEntry as? [String: Any], apiEntryDictionary["id"] as? String == "V1" {
                    serverApiV1String = apiEntryDictionary["url"] as? String
                }
                if let apiEntryDictionary = apiEntry as? [String: Any], apiEntryDictionary["id"] as? String == "INTERACTIVE-V1" {
                    serverApiInteractiveV1String = apiEntryDictionary["url"] as? String
                }
                if let apiEntryDictionary = apiEntry as? [String: Any], apiEntryDictionary["id"] as? String == "SDK-V1" {
                    serverApiSdkV1String = apiEntryDictionary["url"] as? String
                }
            }
        }
        
        let version = Version.init(from: versionString ?? "")
        let forceUpdateVersion = Version.init(from: forceUpdateVersionString ?? "")
        let currentAppVersion = Version.init(from: BHAppConfiguration.shared.appVersion())
        var updateState = UpdateState.ok

        if let versionDiff = version.firstDiff(from: currentAppVersion), versionDiff.order == .orderedAscending {
            if versionDiff.depth == .prime || versionDiff.depth == .major {
                updateState = .updateRequired
            }
            else if versionDiff.depth == .minor {
                updateState = .updateAvailable
            }
        }

        if let forceUpdadeVersionDiff = forceUpdateVersion.firstDiff(from: currentAppVersion), forceUpdadeVersionDiff.order == .orderedAscending {
            updateState = .updateRequired
        }

        var configBody: BHConfigBody?
        if let validServerApiV1String = serverApiV1String, let validServerApiInteractiveV1String = serverApiInteractiveV1String, let validServerApiSdkV1String = serverApiSdkV1String, version.isValid {

            configBody = BHConfigBody.init(serverApiV1String: validServerApiV1String, serverApiInteractiveV1String: validServerApiInteractiveV1String, serverApiSdkV1String: validServerApiSdkV1String, version: version, updateState: updateState, changelogURLString: changelogURLString)
        }

        return configBody
    }
}
