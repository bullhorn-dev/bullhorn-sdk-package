
import Foundation
import UIKit

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
            
            if !username.isEmpty {
                BHUserManager.shared.getUserByUsername(username) { result in
                    switch result {
                    case .success(user: let user):
                        DispatchQueue.main.async {
                            let bundle = Bundle.module
                            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
                            let vc = storyboard.instantiateViewController(withIdentifier: BHUserDetailsViewController.storyboardIndentifer) as! BHUserDetailsViewController
                            vc.user = user
                            
                            UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                        }
                        
                    case .failure(error: let e):
                        BHLog.w(e)
                        break
                    }
                }
                result = true
            }
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

            if !username.isEmpty && !alias.isEmpty {
                BHPostsManager.shared.getPostByAlias(username, postAlias: alias) { result in
                    switch result {
                    case .success(post: let post):
                        DispatchQueue.main.async {
                            let bundle = Bundle.module
                            let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
                            let vc = storyboard.instantiateViewController(withIdentifier: BHPostDetailsViewController.storyboardIndentifer) as! BHPostDetailsViewController
                            vc.post = post
                            
                            UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                        }
                        
                    case .failure(error: let e):
                        BHLog.w(e)
                        break
                    }
                }
                result = true
            }
        } else {
            BHLog.w("Failed to read username and alias from universal link")
        }

        return result
    }
}

