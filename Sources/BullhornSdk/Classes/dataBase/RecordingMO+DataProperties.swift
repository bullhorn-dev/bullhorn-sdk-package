import Foundation
import CoreData

extension RecordingMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecordingMO> {
        return NSFetchRequest<RecordingMO>(entityName: RecordingMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var duration: NSNumber?
    @NSManaged public var publishUrl: String?
}
