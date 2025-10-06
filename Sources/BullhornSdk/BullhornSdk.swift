
import UIKit
import Foundation

public protocol BullhornSdkDelegate: AnyObject {
    func bullhornSdkDidStartPlaying()
}

public struct BHSdkUser {
    
    public enum Level {
        case anonymous
        case external
    }

    let id: String
    var fullName: String?
    var profilePictureUri: String?
    var level: Level
    
    public init(id: String, fullName: String? = nil, profilePictureUri: String? = nil, level: Level) {
        self.id = id
        self.fullName = fullName
        self.profilePictureUri = profilePictureUri
        self.level = level
    }
    
    public var initials: String {
        var finalString = String()
        guard var words = fullName?.components(separatedBy: .whitespacesAndNewlines) else { return "A" }
        
        if let firstCharacter = words.first?.first {
          finalString.append(String(firstCharacter))
          words.removeFirst()
        }
        
        if let lastCharacter = words.last?.first {
          finalString.append(String(lastCharacter))
        }
        
        return finalString.uppercased()
    }
}

public enum SdkUserResult {
    case success(user: BHSelfUser)
    case failure(error: String)
}

public class BullhornSdk: NSObject {

    public static let OpenLoginNotification = Notification.Name(rawValue: "BullhornSdk.OpenLoginNotification")
    public static let OpenSignUpNotification = Notification.Name(rawValue: "BullhornSdk.OpenSignUpNotification")
    public static let OpenAccountNotification = Notification.Name(rawValue: "BullhornSdk.OpenAccountNotification")
    public static let OpenAppearanceNotification = Notification.Name(rawValue: "BullhornSdk.OpenAppearanceNotification")

    public static let UserInterfaceStyleChangedNotification = Notification.Name(rawValue: "BullhornSdk.UserInterfaceStyleChangedNotification")
    public static let NetworkIdChangedNotification = Notification.Name(rawValue: "BullhornSdk.NetworkIdChangedNotification")
    public static let OnExternalAccountChangedNotification = Notification.Name(rawValue: "BullhornSdk.OnExternalAccountChangedNotification")

    public static let shared = BullhornSdk()
    
    public weak var delegate: BullhornSdkDelegate?
    
    public var isLoggingEnabled: Bool = false
    
    public var appConfig: BHAppConfiguration {
        return BHAppConfiguration.shared
    }

    public var clientId: String = ""
    public var infoLinks: [BHInfoLink] = []

    internal var defaultNetworkId: String = ""

    public var networkId: String {
        if UserDefaults.standard.isCustomNetworkSelected {
            return UserDefaults.standard.networkId ?? defaultNetworkId
        } else {
           return defaultNetworkId
        }
    }
    
    public var externalUser: BHSdkUser?
    
    fileprivate static let backgroundTaskLength: Double = 60 * 30 // 30 minutes
    
    fileprivate var backgroundTask: BHBackgroundTask!
    fileprivate var backgroundTaskStartTime: TimeInterval?
    fileprivate var isBackgroundTaskRequested: Bool = false

    public func configure(clientId: String, networkId: String, infoLinks: [BHInfoLink], configType: BHAppConfigType = .prod) {
        BHLog.p("\(#function)")

        if BHReachabilityManager.shared.isConnected() {
            BHLog.p("The internet connected")
        }

        BHAppConfiguration.type = configType
        
        self.clientId = clientId
        self.defaultNetworkId = networkId
        self.infoLinks = infoLinks
        
        BHLog.p("\(#function) - AppConfig: \(BHAppConfiguration.shared.appVersion(useBuildNumber: true))")

        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnteredBackgound), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnteredForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)

        setupAppearance()
        
        BHHybridPlayer.shared.updateQueueItems()
        
        initBackgroundTask()
    }
    
    public func terminate() {
        BHLog.p("\(#function)")
    }
    
    public func restore(sdkUser: BHSdkUser) {
        BHLog.p("\(#function) sdkUserId: \(sdkUser.id)")

        if !BHAccountManager.shared.restoreAccount(with: sdkUser.id) {
            login(sdkUser: sdkUser) { [self] _ in
                BHTracker.shared.start(with: clientId)
            }
        } else {
            externalUser = sdkUser
            BHTracker.shared.start(with: clientId)

            if UserDefaults.standard.isPushNotificationsFeatureEnabled && UserDefaults.standard.isPushNotificationsEnabled {
                BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
            }
        }
        
        BHDownloadsManager.shared.updateItems()
        BHOffsetsManager.shared.updateOffsets()
    }
    
    public func login(sdkUser: BHSdkUser, force: Bool = false, completion: @escaping (SdkUserResult) -> Void) {
        BHLog.p("\(#function)")
        
        BHAccountManager.shared.loginSdkUser(clientId: clientId, sdkUserId: sdkUser.id, fullName: sdkUser.fullName, profilePictureUri: sdkUser.profilePictureUri, force: force) { result in
            switch result {
            case .success(account: let account):
                self.externalUser = sdkUser
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: BullhornSdk.OnExternalAccountChangedNotification, object: self, userInfo: nil)
                    
                    if UserDefaults.standard.isPushNotificationsFeatureEnabled && UserDefaults.standard.isPushNotificationsEnabled {
                        BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
                    }
                }
                completion(.success(user: account.user))
            case .failure(error: let error):
                completion(.failure(error: error.localizedDescription))
            }
        }
    }
    
    public func logout(_ sdkUser: BHSdkUser) {
        BHLog.p("\(#function)")
        
        externalUser = nil

        BHHybridPlayer.shared.close()
        BHLivePlayer.shared.close()

        BHAccountManager.shared.loginAnonymously() { _ in
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: BullhornSdk.OnExternalAccountChangedNotification, object: self, userInfo: nil)

                if UserDefaults.standard.isPushNotificationsFeatureEnabled && UserDefaults.standard.isPushNotificationsEnabled {
                    BHNotificationsManager.shared.checkUserNotificationsEnabled(withNotDeterminedStatusEnabled: false)
                }
            }
        }
    }
    
    public func getSelfUser() -> BHSelfUser? {
        return BHAccountManager.shared.user
    }
    
    public func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if BHOrientationManager.shared.landscapeSupported {
            return .allButUpsideDown
        }
        return .portrait
    }
        
    public func updateUserInterfaceStyle(_ style: UIUserInterfaceStyle) {
        BHLog.p("\(#function) - style: \(style)")

        var info = [String : Int]()
        info["style"] = style.rawValue
        
        UserDefaults.standard.userInterfaceStyle = style

        NotificationCenter.default.post(name: BullhornSdk.UserInterfaceStyleChangedNotification, object: self, userInfo: info)
    }
        
    public func onPlayerStarted() {
        BHHybridPlayer.shared.pause()
    }
    
    public func setImage(for imageView: UIImageView, url: URL?) {
        imageView.sd_setImage(with: url)
    }
    
    public func resetNetwork(with networkId: String) {
        UserDefaults.standard.networkId = networkId
        
        NotificationCenter.default.post(name: BullhornSdk.NetworkIdChangedNotification, object: self, userInfo: nil)
    }
    
    public func shouldOpenUrl(_ url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

        if url.scheme == BHAppConfiguration.shared.customSchemeString {
            let schemeString = url.absoluteString
            let replaceFrom = BHAppConfiguration.shared.customSchemeString + "://"
            let replaceTo = BHAppConfiguration.shared.webSiteURL1String + "/"
            let urlString = schemeString.replacingOccurrences(of: replaceFrom, with: replaceTo)
            guard let webURL = URL(string: urlString) else { return true }
            
            return BHLinkResolver.shared.resolveUniversalLink(webURL)
        }

        return false
    }
    
    public func shouldContinueUserActivity(_ url: URL?) -> Bool {

        if let webURL = url {
            if let webURL1FromConfiguration = URL.init(string: BHAppConfiguration.shared.webSiteURL1String), let webURL2FromConfiguration = URL.init(string: BHAppConfiguration.shared.webSiteURL2String) {

                if webURL1FromConfiguration.host == webURL.host || webURL2FromConfiguration.host == webURL.host {
                    return BHLinkResolver.shared.resolveUniversalLink(webURL)
                }
            }
        }

        return false
    }
    
    public func didRegisterForRemoteNotifications(with token: Data) {
        BHNotificationsManager.shared.didRegisterForRemoteNotifications(with: token)
    }
    
    public func searchPodcasts(_ text: String, completion: @escaping (CommonResult) -> Void) {
        BHLog.p("\(#function) - \(text)")

        if BHPlayableContentController.shared.isConnected {
            BHPlayableContentController.shared.searchPodcasts(text, completion: completion)
        } else {
            /// Search in app
        }
    }

    public func searchEpisodes(_ text: String, completion: @escaping (CommonResult) -> Void) {
        BHLog.p("\(#function) - \(text)")

        if BHPlayableContentController.shared.isConnected {
            BHPlayableContentController.shared.searchEpisodes(text, completion: completion)
        } else {
            /// Search in app
        }
    }

    // MARK: - Notifications
    
    @objc func appDidEnteredBackgound() {
        
    }

    @objc func appWillEnteredForeground() {
        isBackgroundTaskRequested = false
        backgroundTaskStartTime = nil
        BHDownloadsManager.shared.restartFailedItemsIfNeeded()
    }
    
    @objc func appDidBecomeActive() {
        BHPlaybacksManager.shared.restorePlaybacks()
    }

    @objc func appWillTerminate() {
        BHPlaybacksManager.shared.savePlaybacks()
    }


    // MARK: - Private
    
    private func setupAppearance() {

        let navigationBarControlsTintColor = UIColor.navigationText()
        let navigationBarTitleFont = UIFont.fontWithName(.robotoBold, size: 19)
        let navigationBarTitleColor = UIColor.navigationText()

        let navigationBarLargeTitleFont = UIFont.fontWithName(.robotoBold, size: 30)
        let navigationBarLargeTitleColor = UIColor.navigationText()

        let navigationBarAppearance = UINavigationBar.appearance()
        navigationBarAppearance.tintColor = navigationBarControlsTintColor

        navigationBarAppearance.titleTextAttributes = [
            NSAttributedString.Key.font: navigationBarTitleFont,
            NSAttributedString.Key.foregroundColor: navigationBarTitleColor]

        navigationBarAppearance.largeTitleTextAttributes = [
            NSAttributedString.Key.font: navigationBarLargeTitleFont,
            NSAttributedString.Key.foregroundColor: navigationBarLargeTitleColor]

        let barButtonItemFont = UIFont.fontWithName(.robotoRegular, size: 17)

        UIBarButtonItem.appearance().setTitleTextAttributes([NSAttributedString.Key.font: barButtonItemFont], for: UIControl.State.normal)

        UIBarButtonItem.appearance(whenContainedInInstancesOf:[UISearchBar.self]).title = NSLocalizedString("Done", comment: "")

        UIRefreshControl.appearance().tintColor = .accent()
    }
    
    private func initBackgroundTask() {

        let conditionToBeginTask: () -> Bool = { [weak self] in

            guard let strongSelf = self else { return false }

            let result = !BHHybridPlayer.shared.hasActivePlaying() && BHDownloadsManager.shared.hasActiveDouwnloads()
            
            if !strongSelf.isBackgroundTaskRequested && result {
                strongSelf.isBackgroundTaskRequested = true
            }
            
            if let timeInterval = strongSelf.backgroundTaskStartTime {
                let taskLength = Date().timeIntervalSince1970 - timeInterval

                if taskLength >= BullhornSdk.backgroundTaskLength {
                    strongSelf.backgroundTaskStartTime = nil
                    return false
                }
            } else {
                strongSelf.backgroundTaskStartTime = Date().timeIntervalSince1970
            }

            return result
        }

        let checkInterval: TimeInterval = 10
        let task = BHBackgroundTask.init(name: "BullhornSDK.MainBgTask",
                                       minimumIntervalBeforeTimeout: { min(checkInterval, max(0, $0 - 2)) },
                                       conditionToBeginTask: conditionToBeginTask)

        task.condition = { $0 < 2 * checkInterval }

        backgroundTask = task
    }
}
