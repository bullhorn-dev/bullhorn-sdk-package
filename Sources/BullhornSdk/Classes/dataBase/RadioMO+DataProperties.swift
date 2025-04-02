import Foundation
import CoreData

extension RadioMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RadioMO> {
        return NSFetchRequest<RadioMO>(entityName: RadioMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var playbackUrl: String?
    @NSManaged public var phoneNumber: String?
    @NSManaged public var streams: NSSet?
}

