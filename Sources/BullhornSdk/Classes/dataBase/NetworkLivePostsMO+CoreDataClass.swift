import Foundation
import CoreData

@objc(NetworkLivePostsMO)
public class NetworkLivePostsMO: NSManagedObject {
    
    static let entityName = "NetworkLivePosts"
    
    // MARK: - Public
        
    func toPosts() -> [BHPost] {

        var posts: [BHPost] = []

        if let validPosts = livePosts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    posts.append(post)
                }
            }
        }
        
        return posts
    }
}
