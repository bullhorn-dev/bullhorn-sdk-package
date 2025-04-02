
import Foundation
import CoreData

extension RecentUsersMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RecentUsersMO> {
        return NSFetchRequest<RecentUsersMO>(entityName: RecentUsersMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var page: Int
    @NSManaged public var pages: Int
    @NSManaged public var recentUsers: NSSet?
}

