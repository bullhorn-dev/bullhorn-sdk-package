import Foundation
import CoreData

@objc(CategoriesMO)
public class CategoriesMO: NSManagedObject {
    
    static let entityName = "Categories"
    
    // MARK: - Public
        
    func toCategories() -> [BHCategory] {

        var result: [BHCategory] = []

        if let validCategories = categories {
            for categoryMO in validCategories.compactMap({ $0 as? CategoryMO }) {
                if let category = categoryMO.toCategory() {
                    result.append(category)
                }
            }
        }
        return result
    }
}


