import Foundation
import CoreData

@objc(NetworkPostsMO)
public class NetworkPostsMO: NSManagedObject {
    
    static let entityName = "NetworkPosts"
    
    // MARK: - Public
        
    func toNetworkPosts() -> (posts: [BHPost], page: Int, pages: Int) {

        var psts: [BHPost] = []

        if let validPosts = posts {
            for postMO in validPosts.compactMap({ $0 as? PostMO }) {
                if let post = postMO.toPost() {
                    psts.append(post)
                }
            }
        }
        
        return (posts: psts, page: page, pages: pages)
    }
}
