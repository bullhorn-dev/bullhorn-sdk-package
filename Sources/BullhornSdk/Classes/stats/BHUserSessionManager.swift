
import Foundation
import UIKit

class BHUserSessionManager {
        
    static let shared = BHUserSessionManager()
    
    static let defaultSessionId: String = "10000000"
    static let sessionDurationThreshold: TimeInterval = 900 // 15 min
    
    var sessionId: String {
        if let validSessionId = savedSessionId {
            return validSessionId
        } else {
            return BHUserSessionManager.defaultSessionId
        }
    }
    
    var savedSessionId: String? {
        return UserDefaults.standard.userSessionId
    }
    
    var currentTime: Double {
        return Date().timeIntervalSince1970
    }
    
    var userSessionTime: Double {
        return UserDefaults.standard.userSessionTime
    }
    
    init() {
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnteredBackgound), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(_:)), name: BHAccountManager.AccountChangedNotification, object: nil)
        
        generateSessionIfExpired()
    }
    
    func start() {
        BHLog.p("Start session_gen tracker")
    }
    
    // MARK: - Private
    
    fileprivate func generateSessionIfExpired() {
        if savedSessionId == nil || (currentTime - userSessionTime) > BHUserSessionManager.sessionDurationThreshold {
            generateSession()
        }
    }
    
    fileprivate func generateSession() {
        
        UserDefaults.standard.userSessionId = UUID().uuidString
        UserDefaults.standard.userSessionTime = currentTime
        
        BHTracker.shared.trackNewUserSessionEvent()
    }
    
    // MARK: - Handle interruptions
    
    @objc fileprivate func appDidEnteredBackgound() {
        UserDefaults.standard.userSessionTime = currentTime
    }

    @objc fileprivate func appWillEnteredForeground() {
        generateSessionIfExpired()
    }

    @objc fileprivate func onAccountChangedNotification(_ notification: Notification) {

        guard let notificationInfo = notification.userInfo as? [String : BHAccountManager.AccountChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHAccountManager.NotificationInfoKey] else { return }

        switch info.reason {
        case .update:
            generateSession()

        default:
            break
        }
    }
}
