import Foundation
import CoreData

extension NetworkMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<NetworkMO> {
        return NSFetchRequest<NetworkMO>(entityName: NetworkMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var createdAt: String?
    @NSManaged public var descr: String?
    @NSManaged public var name: String?
    @NSManaged public var path: String?
    @NSManaged public var podcastsCount: Int
    @NSManaged public var profilePicture: String?
    @NSManaged public var profilePictureBig: String?
    @NSManaged public var profilePictureTiny: String?
    @NSManaged public var shareLink: String?
}
