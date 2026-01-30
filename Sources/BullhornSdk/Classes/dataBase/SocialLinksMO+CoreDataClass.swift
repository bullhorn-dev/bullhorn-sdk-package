import Foundation
import CoreData

@objc(SocialLinksMO)
public class SocialLinksMO: NSManagedObject {
    
    static let entityName = "SocialLinks"
    
    // MARK: - Public
    
    func toSocialLinks() -> BHSocialLinks? {

        var sl = BHSocialLinks()
        
        sl.facebook = facebook != nil ? URL(string: facebook!) : nil
        sl.instagram = instagram != nil ? URL(string: instagram!) : nil
        sl.twitter = twitter != nil ? URL(string: twitter!) : nil
        sl.twitch = twitch != nil ? URL(string: twitch!) : nil
        sl.website = website != nil ? URL(string: website!) : nil
        sl.youtube = youtube != nil ? URL(string: youtube!) : nil
        sl.linkedin = linkedin != nil ? URL(string: linkedin!) : nil

        return sl
    }
}

