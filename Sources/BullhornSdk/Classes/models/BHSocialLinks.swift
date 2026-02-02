
import Foundation

// MARK: - Social Links

struct BHSocialLinks: Codable, Hashable {
    
    enum CodingKeys: String, CodingKey {
        case facebook
        case instagram
        case twitch
        case twitter
        case website
        case youtube
        case linkedin
    }
    
    var facebook: URL?
    var instagram: URL?
    var twitch: URL?
    var twitter: URL?
    var website: URL?
    var youtube: URL?
    var linkedin: URL?
    
    func hasFacebook() -> Bool { facebook != nil }
    func hasInstagram() -> Bool { instagram != nil }
    func hasTwitch() -> Bool { twitch != nil }
    func hasTwitter() -> Bool { twitter != nil }
    func hasWebsite() -> Bool { website != nil }
    func hasYouTube() -> Bool { youtube != nil }
    func hasLinkedIn() -> Bool { linkedin != nil }

    // MARK: - Link Items

    var facebookLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "Facebook", url: facebook, image: "ic_facebook.png")
    }
    
    var instagramLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "Instagram", url: instagram, image: "ic_instagram.png")
    }

    var twitchLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "Twitch", url: twitch, image: "ic_twitch.png")
    }

    var twitterLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "Twitter", url: twitter, image: "ic_twitter.png")
    }

    var websiteLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "Website", url: website, image: "ic_website.png")
    }

    var youtubeLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "YouTube", url: youtube, image: "ic_youtube.png")
    }

    var linkedinLink: BHSocialLinkItem {
        return BHSocialLinkItem(title: "LinkedIn", url: linkedin, image: "ic_linkedin.png")
    }
    
    func isEmpty() -> Bool {
        return facebook == nil && instagram == nil && twitch == nil && twitter == nil && website == nil && youtube == nil && linkedin == nil
    }
    
    static func fromDictionary(_ params: [String: Any]) -> BHSocialLinks? {
        var facebookUrl: URL?
        var instagramUrl: URL?
        var twitchUrl: URL?
        var twitterUrl: URL?
        var websiteUrl: URL?
        var youtubeUrl: URL?
        var linkedinUrl: URL?
        
        if let fb = params[CodingKeys.facebook.rawValue] as? String {
            facebookUrl = URL(string: fb)
        }
        if let inst = params[CodingKeys.instagram.rawValue] as? String {
            instagramUrl = URL(string: inst)
        }
        if let t = params[CodingKeys.twitch.rawValue] as? String {
            twitchUrl = URL(string: t)
        }
        if let tw = params[CodingKeys.twitter.rawValue] as? String {
            twitterUrl = URL(string: tw)
        }
        if let web = params[CodingKeys.website.rawValue] as? String {
            websiteUrl = URL(string: web)
        }
        if let you = params[CodingKeys.youtube.rawValue] as? String {
            youtubeUrl = URL(string: you)
        }
        if let lin = params[CodingKeys.linkedin.rawValue] as? String {
            linkedinUrl = URL(string: lin)
        }

        return BHSocialLinks(facebook: facebookUrl, instagram: instagramUrl, twitch: twitchUrl, twitter: twitterUrl, website: websiteUrl, youtube: youtubeUrl, linkedin: linkedinUrl)
    }

}
