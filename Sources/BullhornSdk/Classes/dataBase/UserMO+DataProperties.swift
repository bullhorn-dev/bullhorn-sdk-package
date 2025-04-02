import Foundation
import CoreData

extension UserMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserMO> {
        return NSFetchRequest<UserMO>(entityName: UserMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var bio: String?
    @NSManaged public var username: String?
    @NSManaged public var fullName: String?
    @NSManaged public var profilePicture: String?
    @NSManaged public var profilePictureBig: String?
    @NSManaged public var profilePictureTiny: String?
    @NSManaged public var level: NSNumber?
    @NSManaged public var external: Bool
    @NSManaged public var isNetwork: Bool
    @NSManaged public var hasActiveLive: Bool
    @NSManaged public var shareLink: String?
    @NSManaged public var website: String?
    @NSManaged public var categories: NSSet?
    @NSManaged public var ratingsCount: NSNumber?
    @NSManaged public var ratingValue: NSNumber?
}
