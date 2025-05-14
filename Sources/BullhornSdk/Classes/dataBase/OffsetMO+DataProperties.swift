import Foundation
import CoreData

extension OffsetMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OffsetMO> {
        return NSFetchRequest<OffsetMO>(entityName: OffsetMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var offset: Double
    @NSManaged public var timestamp: Double
    @NSManaged public var completed: Bool
}

