
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
}
