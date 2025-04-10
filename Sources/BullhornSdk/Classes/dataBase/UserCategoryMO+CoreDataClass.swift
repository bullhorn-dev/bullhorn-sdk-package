import Foundation
import CoreData

@objc(UserCategoryMO)
public class UserCategoryMO: NSManagedObject {
    
    static let entityName = "UserCategory"
    
    // MARK: - Public
    
    func toUserCategory() -> BHUserCategory? {

        guard let validId = id else { return nil }
        
        var userCategory = BHUserCategory(id: validId.intValue)
        
//        userCategory.icon = URL(string: icon ?? "")
//        userCategory.alias = alias
//        userCategory.gradientFrom = gradientFrom
//        userCategory.gradientTo = gradientTo
//        userCategory.gradientDegree = gradientDegree?.intValue
        userCategory.name = name
//        userCategory.users = users.array(of: String.self)
//        userCategory.subCategoriesCount = subCategoriesCount?.intValue
        
        return userCategory
    }
}
