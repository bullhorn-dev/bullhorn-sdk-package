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
        user.outgoingStatus = outgoingStatus
        user.receiveNotifications = receiveNotifications
        user.autoDownload = autoDownload
        user.newEpisodesCount = newEpisodesCount?.intValue

        var cnls: [BHChannel] = []
        var ctgrs: [BHCategory] = []
        var links: BHSocialLinks?

        if let validChannels = channels {
            let channelsMO = validChannels.legacyUnarchivedObject() as? [[String: Any]]

            channelsMO?.forEach { item in
                if let channel = BHChannel.fromDictionary(item) {
                    cnls.append(channel)
                }
            }
        }

        if let validCategories = categories {
            let categoriesMO = validCategories.legacyUnarchivedObject() as? [[String: Any]]

            categoriesMO?.forEach { item in
                if let category = BHCategory.fromDictionary(item) {
                    ctgrs.append(category)
                }
            }
        }
        
        if let validSocialLinks = socialLinks {
            let socialLinksMO = validSocialLinks.legacyUnarchivedObject() as? [String: Any]

            if let socialLinksMO = socialLinksMO {
                links = BHSocialLinks.fromDictionary(socialLinksMO)
            }
        }

        user.channels = cnls
        user.categories = ctgrs
        user.socialLinks = links

        return user
    }
}
