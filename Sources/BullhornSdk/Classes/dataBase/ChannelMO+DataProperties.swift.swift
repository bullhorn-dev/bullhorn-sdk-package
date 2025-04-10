import Foundation
import CoreData

extension ChannelMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ChannelMO> {
        return NSFetchRequest<ChannelMO>(entityName: ChannelMO.entityName)
    }

    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var title: String?
    @NSManaged public var categories: Data?
}

