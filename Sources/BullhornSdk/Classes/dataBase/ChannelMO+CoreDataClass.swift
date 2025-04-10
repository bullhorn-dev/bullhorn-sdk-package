import Foundation
import CoreData

@objc(ChannelMO)
public class ChannelMO: NSManagedObject {
    
    static let entityName = "Channel"
    
    // MARK: - Public
        
    func toChannel() -> BHChannel? {

        guard let validId = id else { return nil }
        guard let validName = name else { return nil }
        guard let validTitle = title else { return nil }
        
        var c: [BHUserCategory] = []

        if let validCategories = categories {
            let categoriesMO = NSKeyedUnarchiver.unarchiveObject(with: validCategories) as? [[String:Any]]
            
            categoriesMO?.forEach({ item in
                if let category = BHUserCategory.fromDictionary(item) {
                    c.append(category)
                }
            })
        }

        return BHChannel(id: validId, name: validName, title: validTitle, categories: c)
    }
}

