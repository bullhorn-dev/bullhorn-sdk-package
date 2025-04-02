
import UIKit
import Foundation

class CountryCallingCode: NSObject {
    
    var alpha2: String
    var alpha3: String
    var callingCode: String
    var countryName: String
    
    init?(withAlpha2 alpha2:String) {
        
        self.alpha2 = alpha2.uppercased()
        
        guard let item = CountryCallingCodesProvider.shared.itemWithAlpha2(self.alpha2) else {
            return nil
        }
        
        self.countryName = item.countryName
        self.callingCode = item.callingCode
        self.alpha3 = item.countryCodeAlpha3
        
        super.init()
    }

    init?(withAlpha3 alpha3:String) {
        
        self.alpha3 = alpha3.uppercased()
        
        guard let item = CountryCallingCodesProvider.shared.itemWithAlpha3(self.alpha3) else {
            return nil
        }
        
        self.countryName = item.countryName
        self.callingCode = item.callingCode
        self.alpha2 = item.countryCodeAlpha2
        
        super.init()
    }

    init?(withCallingCode callingCode:String) {
        
        self.callingCode = callingCode
        
        guard let item = CountryCallingCodesProvider.shared.itemWithCallingCode(callingCode) else {
            return nil
        }
        
        self.countryName = item.countryName
        self.alpha2 = item.countryCodeAlpha2
        self.alpha3 = item.countryCodeAlpha3
        
        super.init()
    }
    
    static func availableCodes() -> [CountryCallingCode] {
        
        let items = CountryCallingCodesProvider.shared.items
        
        return items.compactMap { CountryCallingCode.init(withAlpha2: $0.countryCodeAlpha2) }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? CountryCallingCode else {
            return false
        }
        
        return alpha2 == other.alpha2
    }
}
