import Foundation
import CoreData

@objc(NetworkScheduledPostsMO)
public class NetworkScheduledPostsMO: NSManagedObject {
    
    static let entityName = "NetworkScheduledPosts"
    
    // MARK: - Public
        
    func toPosts() -> [BHPost] {

        var posts: [BHPost] = []

        if let validPosts = scheduledPosts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    posts.append(post)
                }
            }
        }
        
        return posts
    }
}
