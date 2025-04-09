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
            for categoryMO in validCategories.compactMap({ $0 as? UserCategoryMO }) {
                if let category = categoryMO.toUserCategory() {
                    c.append(category)
                }
            }
        }

        return BHChannel(id: validId, name: validName, title: validTitle, categories: c)
    }
}

