import Foundation
import CoreData

extension RelatedUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RelatedUsersMO> {
        return NSFetchRequest<RelatedUsersMO>(entityName: RelatedUsersMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var relatedUsers: NSSet?
}
