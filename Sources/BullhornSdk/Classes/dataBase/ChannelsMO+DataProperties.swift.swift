import Foundation
import CoreData

extension ChannelsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChannelsMO> {
        return NSFetchRequest<ChannelsMO>(entityName: ChannelsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var channels: NSSet?
}

