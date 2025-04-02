import Foundation
import CoreData

extension StreamMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StreamMO> {
        return NSFetchRequest<StreamMO>(entityName: StreamMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var startAt: NSNumber?
    @NSManaged public var endAt: NSNumber?
    @NSManaged public var coverUrl: String?
    @NSManaged public var phoneNumber: String?
}
