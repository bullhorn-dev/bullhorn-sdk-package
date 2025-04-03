
import UIKit
import Foundation
import BullhornSdk

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        loadBundle()
        
        var configType: BHAppConfigType
        var clientId: String
        let networkId: String = UserDefaults.standard.networkId

        if let mainBundleInfo = Bundle.main.infoDictionary, let appConfigTypeString = mainBundleInfo["AppConfigType"] as? String, let clientIdString = mainBundleInfo["BullhornSdkId"] as? String {
            configType = BHAppConfigType.init(rawValue: appConfigTypeString) ?? .prod
            clientId = clientIdString
            
        } else {
            configType = .prod
            clientId = ""
        }
                
        BullhornSdk.shared.isLoggingEnabled = true
        BullhornSdk.shared.configure(clientId: clientId, networkId: networkId, configType: configType)

        ThemesManager.shared.updateTheme(theme: ThemesManager.shared.currentTheme())

        authorize()

        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {}

    func applicationDidEnterBackground(_ application: UIApplication) {}

    func applicationWillEnterForeground(_ application: UIApplication) {}

    func applicationDidBecomeActive(_ application: UIApplication) {
        ThemesManager.shared.updateTheme(theme: ThemesManager.shared.currentTheme())
    }

    func applicationWillTerminate(_ application: UIApplication) {
        BullhornSdk.shared.terminate()
    }

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return BullhornSdk.shared.supportedInterfaceOrientations()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return BullhornSdk.shared.shouldOpenUrl(url, options: options)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        return BullhornSdk.shared.shouldContinueUserActivity(userActivity, restorationHandler: restorationHandler)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        debugPrint("\(#function)")
        BullhornSdk.shared.didRegisterForRemoteNotifications(with: deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("\(#function) - \(error)")
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        debugPrint("Unexpected memory warning!")
    }
    
    // MARK: - Private
    
    private func loadBundle() {
        let bundleNames = ["BullhornSdk_BullhornSdk"]
        bundleNames.forEach { (bundleName) in
            guard let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle"),
                  let bundle = Bundle(url: bundleURL) else {
                preconditionFailure()
            }
            bundle.load()
        }
        
        Bundle.allBundles.forEach { (bundle) in
            debugPrint("Bundle identifier loaded: \(bundle.bundleIdentifier ?? "unknown")")
        }
    }
    
    private func authorize() {

        if let storedAuth = AuthService.shared.storedFoxAuth() {
            AuthService.shared.setEncodedProfile(storedAuth)
        }
        
        if AuthService.shared.hasAuth {
            AuthService.shared.refresh() { [weak self] success in
                guard let self = self else { return }
                
                AuthService.shared.store(foxAuth: (true == success) ? AuthService.shared.encodedProfile : nil)
                
                self.bullhornLogin(with: AuthService.shared.profileInfo)
            }
        } else {
            bullhornLogin(with: nil)
        }
    }
    
    private func bullhornLogin(with foxUser: ProfileInformation?) {

        var sdkUserId: String
        
        if let validSdkUserId = UserDefaults.standard.string(forKey: "sdk_user_id"), validSdkUserId.count > 0 {
            sdkUserId = validSdkUserId // use previously logged in user
        } else {
            sdkUserId = UUID().uuidString // generate new user id
            UserDefaults.standard.set(sdkUserId, forKey: "sdk_user_id")
        }

        if let validFoxUser = foxUser {
            let sdkUser = BHSdkUser(id: validFoxUser.profileId, fullName: validFoxUser.displayName, profilePictureUri: nil, level: .fox)
            BullhornSdk.shared.restore(sdkUser: sdkUser)
        } else {
            let sdkUser = BHSdkUser(id: sdkUserId, fullName: nil, profilePictureUri: nil, level: .anonymous)
            BullhornSdk.shared.restore(sdkUser: sdkUser)
        }
    }
}

