import Foundation
import CoreData

extension DownloadItemMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<DownloadItemMO> {
        return NSFetchRequest<DownloadItemMO>(entityName: DownloadItemMO.entityName)
    }

    @NSManaged public var id: String?
    @NSManaged public var post: PostMO?
    @NSManaged public var status: Int
    @NSManaged public var prevStatus: Int
    @NSManaged public var reason: Int
    @NSManaged public var progress: Double
    @NSManaged public var url: String?
    @NSManaged public var file: String?
    @NSManaged public var time: Double
}
