
import UserNotifications
import UIKit
import Foundation

protocol BHNotificationsManagerDelegate: AnyObject {
    func notificationsManager(_ manager: BHNotificationsManager, shouldShowAllowNotifications: Bool)
}

class BHNotificationsManager: NSObject {

    static let shared = BHNotificationsManager()
    
    weak var delegate: BHNotificationsManagerDelegate?
    
    var shouldShowAllowNotifications: Bool = true

    fileprivate let retryRequestTimeout: Double = 30.0

    fileprivate var pushTokenString: String?

    fileprivate var localNotificationsManager = BHLocalNotificationsManager()

    fileprivate lazy var apiUsers = BHServerApiUsers.init(withApiType: .regular)

    override init() {
        super.init()
        
        localNotificationsManager.delegate = self

        NotificationCenter.default.addObserver(self, selector: #selector(onAccountChangedNotification(_:)), name: BHAccountManager.AccountChangedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationWillEnterForeground(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onApplicationDidEnterBackground(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
    }

    // MARK: - Public

    func checkUserNotificationsEnabled(withNotDeterminedStatusEnabled notDeterminedStatusEnabled: Bool) {
        
        BHLog.p("\(#function) - status: \(notDeterminedStatusEnabled)")

        UNUserNotificationCenter.current().getNotificationSettings() { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied:
                    self.shouldShowAllowNotifications = false

                case .authorized, .provisional, .ephemeral:
                    self.shouldShowAllowNotifications = false
                    self.registerForRemoteNotifications()

                case .notDetermined:
                    self.shouldShowAllowNotifications = true
                    guard !notDeterminedStatusEnabled else { break }

                    let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                    UNUserNotificationCenter.current().requestAuthorization(options: options) { _, _ in
                        DispatchQueue.main.async { self.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: notDeterminedStatusEnabled) }
                    }
                    
                @unknown default:
                    fatalError("NotificationSettings undefined authorization status")
                }
                
                self.delegate?.notificationsManager(self, shouldShowAllowNotifications: self.shouldShowAllowNotifications)
            }
        }
    }

    func registerForRemoteNotifications() {
#if !targetEnvironment(simulator)
        let pushToken = UserDefaults.standard.pushToken
        
        if !pushToken.isEmpty {
            pushTokenString = pushToken
            updatePushToken() { _ in }
        }

        UIApplication.shared.registerForRemoteNotifications()
#endif
    }

    func didRegisterForRemoteNotifications(with token: Data) {

        pushTokenString = token.reduce("") { $0 + String(format: "%02X", $1) }
        UserDefaults.standard.pushToken = pushTokenString ?? ""

        updatePushToken() { _ in }
    }

    // MARK: - Server requests

    func updatePushToken(_ completion: @escaping (CommonResult) -> Void) {

        if !BHAccountManager.shared.isLoggedIn {
            BHLog.w("\(#function) - failed to update push token. You are logged out.")
            return
        }

        if BHAccountManager.shared.authToken.isEmpty {
            BHLog.w("\(#function) - failed to update push token. Auth token is empty.")
            return
        }

        guard let validPushTokenString = pushTokenString else {
            BHLog.w("\(#function) - failed to update push token. Push token is empty.")
            return
        }

        BHLog.p("\(#function) - authToken: \(BHAccountManager.shared.authToken), pushToken: \(validPushTokenString)")
        
        let pushTokenData = BHPushToken(with: validPushTokenString, networkId: BullhornSdk.shared.networkId, sdkId: BullhornSdk.shared.clientId, appVersion: BHAppConfiguration.shared.appVersion())
        
        tryUpdatePushToken(authToken: BHAccountManager.shared.authToken, pushToken: pushTokenData) { _ in }
    }

    func forgetPushToken(_ completion: @escaping (CommonResult) -> Void) {

        if BHAccountManager.shared.authToken.isEmpty {
            BHLog.w("\(#function) - failed to forget push token. Auth token is empty.")
            return
        }

        BHLog.p("\(#function)")

        tryForgetPushToken(authToken: BHAccountManager.shared.authToken) { result in
            switch result {
            case .success:
                BHLog.p("\(#function) - success")
                UserDefaults.standard.pushToken = ""
            case .failure(let error):
                BHLog.w("\(#function) - failed to forget push token: \(error)")
                return
            }
        }
    }
    
    func removeAllDeliveredNotifications() {
        BHLog.p("\(#function)")
        localNotificationsManager.removeAllDeliveredNotifications()
    }
    
    func removeDeliveredNotifications(with identifier: String) {
        BHLog.p("\(#function) - userID: \(identifier)")
        localNotificationsManager.removeDeliveredNotifications(with: identifier)
    }
    
    func triggerDownloadEpisodeNotification(with post: BHPost) {
        BHLog.p("\(#function) - postID: \(post.id)")
        
        let content = UNMutableNotificationContent()
        content.title = post.title
        content.body = "Downloading episode..."
        content.sound = UNNotificationSound.default
        let payload = [
            NotificationInfo.DataKey.category.rawValue: NotificationInfo.PayloadType.downloadEpisode.rawValue,
        ] as [String : Any]
        content.userInfo = [
            NotificationInfo.DataKey.aps.rawValue: payload,
            NotificationInfo.DataKey.title.rawValue: post.title,
            NotificationInfo.DataKey.message.rawValue: "Downloading episode...",
            NotificationInfo.DataKey.eventUuid.rawValue: post.id,
            NotificationInfo.DataKey.event.rawValue: post.title,
            NotificationInfo.DataKey.userUuid.rawValue: post.user.id,
            NotificationInfo.DataKey.user.rawValue: post.user.fullName ?? "",
            NotificationInfo.DataKey.userPicture.rawValue: post.user.profilePicture?.absoluteString ?? "",
        ] as [String : Any]
        
        localNotificationsManager.triggerLocalNotification(with: content)
    }

    // MARK: - Private

    fileprivate func tryUpdatePushToken(authToken token: String?, pushToken: BHPushToken, _ completion: @escaping (CommonResult) -> Void) {

        apiUsers.updatePushToken(authToken: token, pushToken: pushToken) { result in
            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                BHLog.w(error)
//                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryRequestTimeout, execute: {
//                    self.tryUpdatePushToken(authToken: token, pushToken: pushToken, completion)
//                })
            }
        }
    }

    fileprivate func tryForgetPushToken(authToken token: String?, _ completion: @escaping (CommonResult) -> Void) {

        apiUsers.forgetPushToken(authToken: token) { result in

            switch result {
            case .success:
                completion(.success)
            case .failure(let error):
                BHLog.w(error)
//                DispatchQueue.main.asyncAfter(deadline: .now() + self.retryRequestTimeout, execute: {
//                    self.tryForgetPushToken(authToken: token, completion)
//                })
            }
        }
    }
    
    fileprivate func performDefaultAction(for info: NotificationInfoCommonObject, completionHandler: @escaping (Bool) -> Void) {

        var handled = false

        switch info.payloadType {
        case .newEpisodeInvitation:
            if let infoEvent = info as? NewEpisodeNotificationInfo {
                handled = true
                BHPostsManager.shared.getPost(infoEvent.eventUuid, context: nil) { response in
                    switch response {
                    case .success(post: let post):
                        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: Bundle.module)
                        let vc = storyboard.instantiateViewController(withIdentifier: BHPostDetailsViewController.storyboardIndentifer) as! BHPostDetailsViewController
                        vc.post = post
                        UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                        
                        if infoEvent.autoDownload {
                            BHDownloadsManager.shared.autoDownloadNewEpisodeIfNeeded(post)
                        }
                    case .failure(error: _):
                        break
                    }
                }
            }
            
        case .downloadEpisode:
            if let infoEvent = info as? DownloadEpisodeNotificationInfo {
                handled = true
                let storyboard = UIStoryboard(name: StoryboardName.main, bundle: Bundle.module)
                let vc = storyboard.instantiateViewController(withIdentifier: BHDownloadsViewController.storyboardIndentifer) as! BHDownloadsViewController
                
                UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
            }
            
        case .newEpisodesReminder:
            handled = true

        case .liveEpisodeStarted,
             .liveEpisodeMeetingRoom,
             .liveEpisodeScheduled:
            if let infoEvent = info as? LiveEpisodeStartedNotificationInfo {
                handled = true
                BHNetworkManager.shared.getLiveNowPosts(BHAppConfiguration.shared.networkId, text: nil) { _ in }
                BHPostsManager.shared.getPost(infoEvent.eventUuid, context: nil) { response in
                    switch response {
                    case .success(post: let post):
                        let storyboard = UIStoryboard(name: StoryboardName.main, bundle: Bundle.module)
                        let vc = storyboard.instantiateViewController(withIdentifier: BHPostDetailsViewController.storyboardIndentifer) as! BHPostDetailsViewController
                        vc.post = post
                        UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                    case .failure(error: _):
                        break
                    }
                }
            }
            break
            
        case .massNotification:
            handled = true
        }

        completionHandler(handled)
    }
}

// MARK: - Notifications

extension BHNotificationsManager {

    @objc fileprivate func onAccountChangedNotification(_ notification: Notification) {

        guard let notificationInfo = notification.userInfo as? [String: BHAccountManager.AccountChangedNotificationInfo] else { return }
        guard let info = notificationInfo[BHAccountManager.NotificationInfoKey] else { return }

        switch info.reason {
        case .signup, .login, .restore, .update:
            checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: true)

        case .logout:
            localNotificationsManager.removeAllDeliveredNotifications()
            forgetPushToken() { _ in }

        default:
            break
        }
    }

    @objc fileprivate func onApplicationWillEnterForeground(_ notification: Notification) {

        guard BHAccountManager.shared.account?.user != nil else { return }

        checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: true)
    }

    @objc fileprivate func onApplicationDidEnterBackground(_ notification: Notification) {
        localNotificationsManager.updateApplicationIconBadgeNumber()
    }
}

// MARK: - LocalNotificationsManagerDelegate

extension BHNotificationsManager: BHLocalNotificationsManagerDelegate {

    func localNotificationsManager(_ manager: BHLocalNotificationsManager, presentationOptionsForNotification info: NotificationInfoCommonObject) -> UNNotificationPresentationOptions {
        
        guard BHAccountManager.shared.isLoggedIn else {
            BHLog.p("\(#function) - Skip push notification for not authorized user")
            return []
        }

        let allOptions: UNNotificationPresentationOptions = [.list, .sound, .badge]
        let options: UNNotificationPresentationOptions = allOptions

        return options
    }
    
    func localNotificationsManager(_ manager: BHLocalNotificationsManager, performActionForNotification info: NotificationInfoCommonObject, actionIdentifier: String, completionHandler: @escaping (Bool) -> Void) {
        
        guard BHAccountManager.shared.isLoggedIn else {
            BHLog.p("\(#function) - Skip push notification for not authorized user")
            completionHandler(false)
            return
        }

        performDefaultAction(for: info, completionHandler: completionHandler)
    }
}
