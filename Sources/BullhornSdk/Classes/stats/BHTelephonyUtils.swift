
import Foundation
import CoreTelephony

class BHTelephonyUtils {
        
    static let shared = BHTelephonyUtils()

    func getMCC() -> String {
        let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        return carrier?.mobileCountryCode ?? ""
    }
    
    func getMNC() -> String {
        let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        return carrier?.mobileNetworkCode ?? ""
    }
    
    func getCallingCode() -> Int {
        let carrier = CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?.first?.value
        let countryCodeIso2 = carrier?.isoCountryCode ?? ""
        let countryCallingCode = CountryCallingCode.init(withAlpha2: countryCodeIso2)
        return Int(countryCallingCode?.callingCode ?? "1") ?? 1
    }
}
