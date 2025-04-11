import Foundation
import CoreData

@objc(PostMO)
public class PostMO: NSManagedObject {
    
    static let entityName = "Post"
    
    // MARK: - Public
    
    func toPost() -> BHPost? {

        guard let validId = id else { return nil }
        guard let validTitle = title else { return nil }
        guard let validType = postType else { return nil }
        guard let validPrivacy = privacy else { return nil }
        guard let validShareLink = shareLink,
              let shareLinkUrl = URL(string: validShareLink) else { return nil }
        guard let validUser = user?.toUser() else { return nil }

        let type = BHPost.PostType(rawValue: validType) ?? .preRecorded
        let pr = BHPost.PostPrivacy(rawValue: validPrivacy) ?? .public
        let st = BHPost.PostStatus(rawValue: status ?? "") ?? .finished

        let post = BHPost(id: validId, title: validTitle, description: descr, postType: type, alias: alias, startTime: startTime, endTime: endTime, scheduledAt: scheduledAt, hasMeetingRoom: hasMeetingRoom, originalTime: originalTime, playbackOffset: playbackOffset, isPlaybackCompleted: isPlaybackCompleted, privacy: pr, published: published, publishedAt: publishedAt, liked: liked, shareLink: shareLinkUrl, user: validUser, recording: recording?.toRecording(), bulletin: bulletin?.toPostBulletin(), status: st)
                
        return post
    }
}
