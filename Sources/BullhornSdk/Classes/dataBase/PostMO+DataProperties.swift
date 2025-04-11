import Foundation
import CoreData

extension PostMO {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PostMO> {
        return NSFetchRequest<PostMO>(entityName: PostMO.entityName)
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var descr: String?
    @NSManaged public var postType: String?
    @NSManaged public var alias: String?
    @NSManaged public var startTime: String?
    @NSManaged public var endTime: String?
    @NSManaged public var scheduledAt: String?
    @NSManaged public var hasMeetingRoom: Bool
    @NSManaged public var originalTime: String?
    @NSManaged public var playbackOffset: Double
    @NSManaged public var isPlaybackCompleted: Bool
    @NSManaged public var privacy: String?
    @NSManaged public var published: Bool
    @NSManaged public var publishedAt: String?
    @NSManaged public var liked: Bool
    @NSManaged public var shareLink: String?
    @NSManaged public var user: UserMO?
    @NSManaged public var recording: RecordingMO?
    @NSManaged public var bulletin: PostBulletinMO?
    @NSManaged public var status: String?    
}
