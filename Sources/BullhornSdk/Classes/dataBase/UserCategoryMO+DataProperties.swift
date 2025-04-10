import Foundation
import CoreData

extension UserCategoryMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserCategoryMO> {
        return NSFetchRequest<UserCategoryMO>(entityName: UserCategoryMO.entityName)
    }
    
    @NSManaged public var id: NSNumber?
//    @NSManaged public var icon: String?
//    @NSManaged public var alias: String?
//    @NSManaged public var gradientFrom: String?
//    @NSManaged public var gradientTo: String?
//    @NSManaged public var gradientDegree: NSNumber?
    @NSManaged public var name: String?
//    @NSManaged public var users: NSSet?
//    @NSManaged public var subCategoriesCount: NSNumber?
}
