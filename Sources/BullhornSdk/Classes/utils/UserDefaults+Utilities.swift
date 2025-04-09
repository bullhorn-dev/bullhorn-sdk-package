
import UIKit
import Foundation

extension UserDefaults {
    
    fileprivate static let numberOfTimesLaunchedKey = "numberOfTimesLaunchedKey"
    fileprivate static let lastVersionPromtedForReviewKey = "lastVersionPromtedForReviewKey"
    fileprivate static let isDevModeEnabledUserDefaultsKey = "isDevModeEnabledUserDefaultsKey"
    fileprivate static let isPushNotificationsEnabledUserDefaultsKey = "isPushNotificationsEnabledUserDefaultsKey"
    fileprivate static let startSessionTimeUserDefaultsKey = "startSessionTimeUserDefaultsKey"
    fileprivate static let endSessionTimeUserDefaultsKey = "endSessionTimeUserDefaultsKey"
    fileprivate static let isAppInitialAttributesSent = "isAppInitialAttributesSent"
    fileprivate static let themeIdUserDefaultsKey = "themeIdUserDefaultsKey"
    fileprivate static let playerPostIdUserDefaultsKey = "playerPostIdUserDefaultsKey"
    fileprivate static let playerPositionUserDefaultsKey = "playerPositionUserDefaultsKey"
    fileprivate static let playerTimestampUserDefaultsKey = "playerTimestampUserDefaultsKey"
    fileprivate static let pushTokenUserDefaultsKey = "pushTokenUserDefaultsKey"
    fileprivate static let anonymousAuthTokenDefaultsKey = "anonymousAuthTokenDefaultsKey"
    fileprivate static let anonymousUserIdDefaultsKey = "anonymousUserIdDefaultsKey"
    fileprivate static let sdkUserIdDefaultsKey = "sdkUserIdDefaultsKey"
    fileprivate static let sdkUserNameDefaultsKey = "sdkUserNameDefaultsKey"
    fileprivate static let sdkUserIconDefaultsKey = "sdkUserIconDefaultsKey"
    fileprivate static let userInterfaceStyleDefaultsKey = "userInterfaceStyleDefaultsKey"
    fileprivate static let userSessionIdDefaultsKey = "userSessionIdDefaultsKey"
    fileprivate static let userSessionTimeDefaultsKey = "userSessionTimeDefaultsKey"
    fileprivate static let selectedChannelIdDefaultsKey = "selectedChannelIdDefaultsKey"

    static let playNextEnabledDefaultsKey = "playNextEnabledDefaultsKey"

    var numberOfTimesLaunched: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
    }
    
    var lastVersionPromtedForReview: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.lastVersionPromtedForReviewKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.lastVersionPromtedForReviewKey)
        }
    }
    
    var isDevModeEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.isDevModeEnabledUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.isDevModeEnabledUserDefaultsKey)
        }
    }
    
    var isPushNotificationsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.isPushNotificationsEnabledUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.isPushNotificationsEnabledUserDefaultsKey)
        }
    }
    
    var startSessionTime: Date? {
        get {
            return UserDefaults.standard.object(forKey: UserDefaults.startSessionTimeUserDefaultsKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.startSessionTimeUserDefaultsKey)
        }
    }

    var endSessionTime: Date? {
        get {
            return UserDefaults.standard.object(forKey: UserDefaults.endSessionTimeUserDefaultsKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.endSessionTimeUserDefaultsKey)
        }
    }
    
    var isAppInitialAttributesSent: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.isAppInitialAttributesSent)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.isAppInitialAttributesSent)
        }
    }
    
    var themeId: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaults.themeIdUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.themeIdUserDefaultsKey)
        }
    }
    
    var playerPostId: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.playerPostIdUserDefaultsKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.playerPostIdUserDefaultsKey)
        }
    }

    var playerPosition: Double {
        get {
            let position = UserDefaults.standard.double(forKey: UserDefaults.playerPositionUserDefaultsKey)
            return position == 0 ? -1 : position
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.playerPositionUserDefaultsKey)
        }
    }

    var playerTimestamp: Double {
        get {
            return UserDefaults.standard.double(forKey: UserDefaults.playerTimestampUserDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.playerTimestampUserDefaultsKey)
        }
    }
    
    var pushToken: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.pushTokenUserDefaultsKey) ?? ""
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.pushTokenUserDefaultsKey)
        }
    }
    
    var authToken: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.anonymousAuthTokenDefaultsKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.anonymousAuthTokenDefaultsKey)
        }
    }

    var userId: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.anonymousUserIdDefaultsKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.anonymousUserIdDefaultsKey)
        }
    }

    var sdkUserId: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.sdkUserIdDefaultsKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.sdkUserIdDefaultsKey)
        }
    }

    var sdkUserName: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.sdkUserNameDefaultsKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.sdkUserNameDefaultsKey)
        }
    }

    var sdkUserIcon: String? {
        get {
            return UserDefaults.standard.value(forKey: UserDefaults.sdkUserIconDefaultsKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.sdkUserIconDefaultsKey)
        }
    }

    var playNextEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.playNextEnabledDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.playNextEnabledDefaultsKey)
        }
    }
        
    var userInterfaceStyle: UIUserInterfaceStyle {
        get {
            let value = UserDefaults.standard.integer(forKey: UserDefaults.userInterfaceStyleDefaultsKey)
            return UIUserInterfaceStyle(rawValue: value) ?? .light
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: UserDefaults.userInterfaceStyleDefaultsKey)
        }
    }
    
    var userSessionId: String? {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.userSessionIdDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.userSessionIdDefaultsKey)
        }
    }
    
    var userSessionTime: Double {
        get {
            return UserDefaults.standard.double(forKey: UserDefaults.userSessionTimeDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.userSessionTimeDefaultsKey)
        }
    }

    var selectedChannelId: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.selectedChannelIdDefaultsKey) ?? BHChannel.mainChannelId
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.selectedChannelIdDefaultsKey)
        }
    }
}
