
import UIKit

extension UserDefaults {
    
    fileprivate static let numberOfTimesLaunchedKey = "numberOfTimesLaunchedKey"
    fileprivate static let sdkUserIdDefaultsKey = "sdkUserIdDefaultsKey"
    
    var numberOfTimesLaunched: Int {
        get {
            return UserDefaults.standard.integer(forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.numberOfTimesLaunchedKey)
        }
    }

    var sdkUserId: String? {
        get {
            return UserDefaults.standard.string(forKey: UserDefaults.sdkUserIdDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaults.sdkUserIdDefaultsKey)
        }
    }
}
