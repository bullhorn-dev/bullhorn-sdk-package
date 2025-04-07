import Foundation
import CoreData

extension NetworkChannelsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkChannelsMO> {
        return NSFetchRequest<NetworkChannelsMO>(entityName: NetworkChannelsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var channels: NSSet?
}

