
import Foundation

// MARK: - UniversalLinkType

enum UniversalLinkType: String {
    case podcast = "podcast"
    case episode = "episode"
    case unknown
}

// MARK: - UniversalNotificationInfo

struct UniversalNotificationInfo {
        
    let type: UniversalLinkType
    let username: String
    let alias: String?
}

// MARK: - BHLinkResolver

class BHLinkResolver {

    public static let UniversalLinkNotification = Notification.Name(rawValue: "LinkResolver.UniversalLinkNotification")

    enum LinkResolverResult {
        case success(p: [String : Any])
        case failure(e: String)
    }

    typealias LinkResolverCompletion = (LinkResolverResult?) -> Void

    static let shared = BHLinkResolver()
    
    fileprivate let validShortURLPathFirstComponents: Set<String> = ["posts"]
    
    fileprivate let podcastLinkDelimitersCount = 1
    fileprivate let episodeLinkDelimitersCount = 3

    func validateLink(_ url: URL) -> UniversalLinkType {

        guard let webSiteURL1 = URL.init(string: BHAppConfiguration.shared.webSiteURL1String) else { return .unknown }
        guard let webSiteURL2 = URL.init(string: BHAppConfiguration.shared.webSiteURL2String) else { return .unknown }
        if url.host != webSiteURL2.host && url.host != webSiteURL1.host { return .unknown }

        let pathComponentsWithoutDelimiters = url.pathComponentsWithoutDelimiters

        /// podcast link
        if pathComponentsWithoutDelimiters.count == podcastLinkDelimitersCount {
            return .podcast
        }
        
        /// episode link
        if pathComponentsWithoutDelimiters.count == episodeLinkDelimitersCount {
            let secondPathComponent = pathComponentsWithoutDelimiters[1]
            guard validShortURLPathFirstComponents.contains(secondPathComponent) else { return .unknown }
            return .episode
        }

        return .unknown
    }

    func resolveUniversalLink(_ url: URL) -> Bool {

        let result = validateLink(url)

        switch result {
        case .podcast:
            return resolvePodcastLink(url)
        case .episode:
            return resolveEpisodeLink(url)
        case .unknown:
            BHLog.w("Unsupported type of universal link")
        }

        return false
    }

    // MARK: - Private

    fileprivate func resolvePodcastLink(_ url: URL) -> Bool {
        var result = false
        let pathComponentsWithoutDelimiters = url.pathComponentsWithoutDelimiters

        if pathComponentsWithoutDelimiters.count == podcastLinkDelimitersCount {
            let username = pathComponentsWithoutDelimiters[0]
            let infoObject = UniversalNotificationInfo(type: .podcast, username: username, alias: nil)
            let info = ["info" : infoObject]
            NotificationCenter.default.post(name: BHLinkResolver.UniversalLinkNotification, object: self, userInfo: info)
            result = true
        } else {
            BHLog.w("Failed to read username from universal link")
        }
        
        return result
    }

    fileprivate func resolveEpisodeLink(_ url: URL) -> Bool {
        var result = false
        let pathComponentsWithoutDelimiters = url.pathComponentsWithoutDelimiters

        if pathComponentsWithoutDelimiters.count == episodeLinkDelimitersCount {
            let username = pathComponentsWithoutDelimiters[0]
            let alias = pathComponentsWithoutDelimiters[2]
            let infoObject = UniversalNotificationInfo(type: .episode, username: username, alias: alias)
            let info = ["info" : infoObject]
            NotificationCenter.default.post(name: BHLinkResolver.UniversalLinkNotification, object: self, userInfo: info)
            result = true
        } else {
            BHLog.w("Failed to read username and alias from universal link")
        }

        return result
    }
}

