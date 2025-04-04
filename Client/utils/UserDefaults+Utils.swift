
import UIKit

extension UserDefaults {
    
    fileprivate static let numberOfTimesLaunchedKey = "numberOfTimesLaunchedKey"
    fileprivate static let networkIdDefaultsKey = "networkIdDefaultsKey"
    fileprivate static let pushNotificationsEnabledDefaultsKey = "pushNotificationsEnabledDefaultsKey"

    var numberOfTimesLaunched: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
    }
            
    var networkId: String {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.networkIdDefaultsKey) ?? AuthConfig.shared.networkId
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.networkIdDefaultsKey)
        }
    }
    
    var pushNotificationsEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: UserDefaults.pushNotificationsEnabledDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.pushNotificationsEnabledDefaultsKey)
        }
    }
}
