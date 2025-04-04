
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
}
