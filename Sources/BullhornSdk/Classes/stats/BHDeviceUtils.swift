
import Foundation
import UIKit

class BHDeviceUtils {
        
    static let shared = BHDeviceUtils()
    
    func getDeviceName() -> String {
        return UIDevice.current.localizedModel
    }
    
    func getOSPlatform() -> String {
        return UIDevice.current.systemName
    }
    
    func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? "000111"
    }
}

