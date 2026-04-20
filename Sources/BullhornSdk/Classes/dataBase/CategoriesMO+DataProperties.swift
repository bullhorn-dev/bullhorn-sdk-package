import Foundation
import CoreData

extension CategoriesMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CategoriesMO> {
        return NSFetchRequest<CategoriesMO>(entityName: CategoriesMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var categories: NSSet?
}


