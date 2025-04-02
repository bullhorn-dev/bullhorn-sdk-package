import Foundation
import CoreData

extension UserPostsMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserPostsMO> {
        return NSFetchRequest<UserPostsMO>(entityName: UserPostsMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var page: Int
    @NSManaged public var pages: Int
    @NSManaged public var userPosts: NSSet?
}
