import Foundation
import CoreData

@objc(UserPostsMO)
public class UserPostsMO: NSManagedObject {
    
    static let entityName = "UserPosts"
    
    // MARK: - Public
        
    func toPosts() -> (posts: [BHPost], page: Int, pages: Int) {

        var posts: [BHPost] = []

        if let validPosts = userPosts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    posts.append(post)
                }
            }
        }
        
        return (posts: posts, page: page, pages: pages)
    }
}
