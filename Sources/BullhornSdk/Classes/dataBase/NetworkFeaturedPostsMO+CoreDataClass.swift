import Foundation
import CoreData

@objc(NetworkFeaturedPostsMO)
public class NetworkFeaturedPostsMO: NSManagedObject {
    
    static let entityName = "NetworkFeaturedPosts"
    
    // MARK: - Public
        
    func toPosts() -> [BHPost] {

        var posts: [BHPost] = []

        if let validPosts = featuredPosts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    posts.append(post)
                }
            }
        }
        
        return posts
    }
}
