import Foundation
import CoreData

@objc(UserMO)
public class UserMO: NSManagedObject {
    
    static let entityName = "User"
    
    // MARK: - Public
    
    func toUser() -> BHUser? {

        guard let validId = id else { return nil }
        
        var user = BHUser(id: validId)
        
        user.bio = bio
        user.username = username
        user.fullName = fullName
        user.profilePicture = profilePicture != nil ? URL(string: profilePicture!) : nil
        user.profilePictureBig = profilePictureBig != nil ? URL(string: profilePictureBig!) : nil
        user.profilePictureTiny = profilePictureTiny != nil ? URL(string: profilePictureTiny!) : nil
        user.level = BHUser.Level(rawValue: level?.intValue ?? 0) ?? .anonymous
        user.external = external
        user.isNetwork = isNetwork
        user.hasActiveLive = hasActiveLive
        user.shareLink = shareLink != nil ? URL(string: shareLink!) : nil
        user.website = website != nil ? URL(string: website!) : nil
        user.ratingsCount = ratingsCount?.intValue
        user.ratingValue = ratingValue?.doubleValue
        user.outgoingStatus = outgoingStatus

        var ctgrs: [BHUserCategory] = []

        if let validCategories = categories {
            for categoryMO in validCategories.compactMap({ $0 as? UserCategoryMO }) {
                if let category = categoryMO.toUserCategory() {
                    ctgrs.append(category)
                }
            }
        }

        user.categories = ctgrs

        return user
    }
}
