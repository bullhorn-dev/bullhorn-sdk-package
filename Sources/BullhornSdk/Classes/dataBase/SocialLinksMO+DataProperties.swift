import Foundation
import CoreData

extension SocialLinksMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SocialLinksMO> {
        return NSFetchRequest<SocialLinksMO>(entityName: SocialLinksMO.entityName)
    }
    
    @NSManaged public var facebook: String?
    @NSManaged public var instagram: String?
    @NSManaged public var twitter: String?
    @NSManaged public var twitch: String?
    @NSManaged public var website: String?
    @NSManaged public var youtube: String?
    @NSManaged public var linkedin: String?
}

