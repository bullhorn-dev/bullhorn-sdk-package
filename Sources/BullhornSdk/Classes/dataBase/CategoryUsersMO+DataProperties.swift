import Foundation
import CoreData

extension CategoryUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoryUsersMO> {
        return NSFetchRequest<CategoryUsersMO>(entityName: CategoryUsersMO.entityName)
    }
    
    @NSManaged public var id: NSNumber?
    @NSManaged public var categoryUsers: NSSet?
}


