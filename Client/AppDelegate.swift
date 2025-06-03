
import UIKit
import Foundation
import BullhornSdk
import Intents

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
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else { return false }
        guard let url = userActivity.webpageURL else { return false }

        return BullhornSdk.shared.shouldContinueUserActivity(url)
    }
    
    func application(_ application: UIApplication, handle intent: INIntent, completionHandler: @escaping (INIntentResponse) -> Void) {
        if let playMediaIntent = intent as? INPlayMediaIntent {
            handlePlayMediaIntent(playMediaIntent, completion: completionHandler)
        } else {
            debugPrint("Unknown Intent")
            completionHandler(INPlayMediaIntentResponse(code: .failure, userActivity: nil))
        }
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
        bullhornLogin()
    }
    
    private func bullhornLogin() {

        var sdkUserId: String
        
        if let validSdkUserId = UserDefaults.standard.sdkUserId, !validSdkUserId.isEmpty {
            sdkUserId = validSdkUserId // use previously logged in user
        } else {
            sdkUserId = UUID().uuidString // generate new user id
            UserDefaults.standard.sdkUserId = sdkUserId
        }

        let sdkUser = BHSdkUser(id: sdkUserId, fullName: nil, profilePictureUri: nil, level: .anonymous)
        BullhornSdk.shared.restore(sdkUser: sdkUser)
    }
    
    private func handlePlayMediaIntent(_ intent: INPlayMediaIntent,
                               completion: @escaping (INPlayMediaIntentResponse) -> Void) {
        if let mediaSearch = intent.mediaSearch?.mediaName {
            debugPrint("\(#function) - mediaSearch: \(mediaSearch)")

            BullhornSdk.shared.searchMedia(mediaSearch) { response in
                // Donate an interaction to the system.
                let response = INPlayMediaIntentResponse(code: .success, userActivity: nil)
                let interaction = INInteraction(intent: intent, response: response)
                interaction.donate(completion: nil)
                completion(response)
            }
        }

        completion(INPlayMediaIntentResponse(code: .failure, userActivity: nil))
    }
}

