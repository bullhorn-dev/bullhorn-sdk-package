import Foundation
import CoreData

@objc(LikedPostsMO)
public class LikedPostsMO: NSManagedObject {
    
    static let entityName = "LikedPosts"
    
    // MARK: - Public
        
    func toPosts() -> (posts: [BHPost], page: Int, pages: Int) {

        var posts: [BHPost] = []

        if let validPosts = likedPosts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    posts.append(post)
                }
            }
        }
        
        return (posts: posts, page: page, pages: pages)
    }
}

