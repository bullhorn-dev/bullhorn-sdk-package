
import UIKit
import Foundation

class AuthConfig {
    
    static let shared = AuthConfig()
    
    fileprivate var authKeys: [String : String]
    
    init() {
        if let mainBundleInfo = Bundle.main.infoDictionary, let keys = mainBundleInfo["AuthConfig"] as? [String : String] {
            authKeys = keys
        } else {
            debugPrint("Failed to read auth keys")
            authKeys = [:]
        }
    }
    
    // MARK: - Public
    
    let sessionId = UUID().uuidString
    
    var networkId: String {
        return authKeys["networkId"] ?? ""
    }
    
    var testNetworkId: String {
        return "0eef38b0-e345-45f3-a084-d8fba47754b7"
    }
    
    var nazarNetworkId: String {
        return "e3530011-10e6-4d5e-bf3c-0e9dc37f786f"
    }
    
    var apiKey: String {
        return authKeys["apiKey"] ?? ""
    }
    
    var preferencesApiKey: String {
        return authKeys["preferencesApiKey"] ?? ""
    }
    
    var accessToken: String {
        return authKeys["accessToken"] ?? ""
    }
    
    var deviceId: String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "deviceId"
    }
    
    var applicationId: String {
        return authKeys["applicationId"] ?? ""
    }
    
    var baseURL: String {
        return authKeys["baseURL"] ?? ""
    }

    var baseApiURL: String {
        return authKeys["baseApiURL"] ?? ""
    }
    
    var productApiProdBaseUrl: String {
        return authKeys["productApiProdBaseUrl"] ?? ""
    }
    
    var xidBaseURL_Prod: String {
        return authKeys["xidBaseURL_Prod"] ?? ""
    }
    
    var xidEventBaseURL_Prod: String {
        return authKeys["xidEventBaseURL_Prod"] ?? ""
    }
    
    var preferencesBaseURL: String {
        return authKeys["preferencesBaseURL"] ?? ""
    }

    var forgotPassword: String {
        return "https://my.foxnews.com/?p=forgot-password"
    }

    var termsOfUse: String {
        return "https://www.foxnews.com/terms-of-use"
    }

    var privacyPolicy: String {
        return "https://www.foxnews.com/privacy-policy"
    }

    var privacyChoices: String {
        return "https://privacy.foxnews.com/main/web/main"
    }
}
