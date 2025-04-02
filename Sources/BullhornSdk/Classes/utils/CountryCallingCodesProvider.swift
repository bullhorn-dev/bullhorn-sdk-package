
import UIKit
import Foundation

class CountryCallingCodesProvider: NSObject {
    
    struct Item {
        
        var countryName: String
        var countryCodeAlpha2: String
        var countryCodeAlpha3: String
        var callingCode: String
    }
    
    static let shared: CountryCallingCodesProvider = CountryCallingCodesProvider()
    
    lazy var items: [Item] = {
        
        guard let plistPath = Bundle.main.path(forResource: "CountryCallingCodes", ofType: "plist") else {
            return []
        }
        
        guard let plistArray = NSArray(contentsOfFile: plistPath) as? [NSDictionary] else {
            return []
        }
        
        var codesArray = [Item]()
        
        for item in plistArray {
            
            var codeItem = Item.init(countryName: Bundle.main.localizedString(forKey: item["alpha2"] as! String, value: "", table: "CountryNames"), countryCodeAlpha2: item["alpha2"] as! String, countryCodeAlpha3: item["alpha3"] as! String, callingCode: item["code"] as! String);
            
            codesArray.append(codeItem)
        }
        
        return codesArray
    }()
    
    private lazy var codesMappingByAlpha2: [String:Item] = {
        
        var mapping = [String:Item]()
        for item in self.items {
            mapping[item.countryCodeAlpha2] = item
        }
        
        return mapping
    }()
    
    private lazy var codesMappingByAlpha3: [String:Item] = {
        
        var mapping = [String:Item]()
        for item in self.items {
            mapping[item.countryCodeAlpha3] = item
        }
        
        return mapping
    }()
    
    private lazy var codesMappingByCallingCode: [String:Item] = {
        
        var mapping = [String:Item]()
        for item in self.items {
            mapping[item.callingCode] = item
        }
        
        return mapping
    }()
    
    func itemWithAlpha2(_ alpha2: String) -> Item? {
        return codesMappingByAlpha2[alpha2]
    }
    
    func itemWithAlpha3(_ alpha3: String) -> Item? {
        return codesMappingByAlpha3[alpha3]
    }
    
    func itemWithCallingCode(_ callingCode: String) -> Item? {
        return codesMappingByCallingCode[callingCode]
    }

}
