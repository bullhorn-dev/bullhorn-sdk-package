
import UIKit
import Foundation

extension NSError {
    static let LocalErrorDomain = "BullhornErrorDomain"
    
    enum LocalCodes: Int {
        case common = 1
        case accountAutorizationRequired
        case invalidURL
        case notImplemented
        case invalidArgument
        case invalidConfiguration
        case webContentProcessDidTerminate
        case viewControllerInitializationFailure
        case jsError
        case imageUploadError
        case attachmentError
        case playableContentError
    }

    static func error(with code: LocalCodes, description: String, reason: String) -> NSError {
        return error(rawCode: code.rawValue, description: description, reason: reason)
    }

    static func error(rawCode: Int, description: String, reason: String) -> NSError {

        let userInfo = reason.isEmpty ? nil : [NSLocalizedDescriptionKey: reason]
        return NSError(domain: NSError.LocalErrorDomain, code: rawCode, userInfo: userInfo)
    }

    static func error(with code: LocalCodes, description: String, userInfo: [String: Any]? = nil) -> NSError {
        return error(rawCode: code.rawValue, description: description, userInfo: userInfo)
    }
    
    static func error(rawCode: Int, description: String, userInfo: [String: Any]? = nil) -> NSError {

        let resultUserInfo: [String: Any]

        if var validUserInfo = userInfo {
            validUserInfo.updateValue(description, forKey: NSLocalizedDescriptionKey)
            resultUserInfo = validUserInfo
        }
        else {
            resultUserInfo = [NSLocalizedDescriptionKey: description]
        }

        return NSError(domain: NSError.LocalErrorDomain, code: rawCode, userInfo: resultUserInfo)
    }
}
