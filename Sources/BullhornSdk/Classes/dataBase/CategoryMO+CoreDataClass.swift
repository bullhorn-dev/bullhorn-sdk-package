import Foundation
import CoreData

@objc(CategoryMO)
public class CategoryMO: NSManagedObject {
    
    static let entityName = "Category"
    
    // MARK: - Public
    
    func toCategory() -> BHCategory? {

        guard let validId = id else { return nil }
        
        var userCategory = BHCategory(id: validId.intValue)
        
//        userCategory.icon = URL(string: icon ?? "")
        userCategory.alias = alias
        userCategory.shareLink = shareLink != nil ? URL(string: shareLink!) : nil
//        userCategory.gradientFrom = gradientFrom
//        userCategory.gradientTo = gradientTo
//        userCategory.gradientDegree = gradientDegree?.intValue
        userCategory.name = name
//        userCategory.users = users.array(of: String.self)
//        userCategory.subCategoriesCount = subCategoriesCount?.intValue
        
        return userCategory
    }
}
