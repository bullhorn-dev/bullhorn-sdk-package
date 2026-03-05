
import Foundation
import UIKit

// MARK: - UniversalLinkType

enum UniversalLinkType: String {
    case podcast = "podcast"
    case episode = "episode"
    case category = "category"
    case unknown
}

// MARK: - UniversalLinkInfo

struct UniversalLinkInfo {
        
    let type: UniversalLinkType
    let username: String?
    let alias: String?
    
    static let unknown = UniversalLinkInfo(type: .unknown, username: nil, alias: nil)
}

// MARK: - BHLinkResolver

class BHLinkResolver {

    static let shared = BHLinkResolver()
    
    fileprivate enum FirstPathComponents: String {
        case podcasts
        case posts
        case categories
    }
    
    fileprivate let podcastLinkDelimitersCount = 2
    fileprivate let categoryLinkDelimitersCount = 2
    fileprivate let episodeLinkDelimitersCount = 4

    func validateLink(_ url: URL) -> UniversalLinkInfo {

        let pathComponentsWithoutDelimiters = url.pathComponentsWithoutDelimiters
        
        if let firstComponent = pathComponentsWithoutDelimiters.first,
           firstComponent == FirstPathComponents.podcasts.rawValue {
            if pathComponentsWithoutDelimiters.count == podcastLinkDelimitersCount {
                let username = pathComponentsWithoutDelimiters[podcastLinkDelimitersCount-1]
                return UniversalLinkInfo(type: .podcast, username: username, alias: nil)
            } else if pathComponentsWithoutDelimiters.count == episodeLinkDelimitersCount {
                let username = pathComponentsWithoutDelimiters[episodeLinkDelimitersCount-3]
                let alias = pathComponentsWithoutDelimiters[episodeLinkDelimitersCount-1]
                return UniversalLinkInfo(type: .episode, username: username, alias: alias)
            }
        } else if let firstPathComponent = pathComponentsWithoutDelimiters.first,
                    firstPathComponent == FirstPathComponents.categories.rawValue,
                    pathComponentsWithoutDelimiters.count == categoryLinkDelimitersCount {
            let alias = pathComponentsWithoutDelimiters[categoryLinkDelimitersCount-1]
            return UniversalLinkInfo(type: .category, username: nil, alias: alias)
        }

        return .unknown
    }

    func resolveUniversalLink(_ url: URL) -> Bool {

        let info = validateLink(url)

        switch info.type {
        case .podcast:
            return resolvePodcastLink(info)
        case .episode:
            return resolveEpisodeLink(info)
        case .category:
            return resolveCategoryLink(info)
        case .unknown:
            BHLog.w("Unsupported type of universal link")
        }

        return false
    }

    // MARK: - Private

    fileprivate func resolvePodcastLink(_ linkInfo: UniversalLinkInfo) -> Bool {
        BHLog.p("\(#function) - username: \(linkInfo.username ?? "nil")")
        
        var result = false

        if let validUsername = linkInfo.username {
            if BHReachabilityManager.shared.isConnected() {
                BHUserManager.shared.getUserByUsername(validUsername) { result in
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
            } else {
                UIApplication.topViewController()?.showError("Failed to load episode details. The Internet connection is lost.")
            }
            result = true
        }
        
        return result
    }

    fileprivate func resolveEpisodeLink(_ linkInfo: UniversalLinkInfo) -> Bool {
        BHLog.p("\(#function) - username: \(linkInfo.username ?? "nil"), alias: \(linkInfo.alias ?? "nil")")

        var result = false

        if let validUsername = linkInfo.username, let validAlias = linkInfo.alias {
            if BHReachabilityManager.shared.isConnected() {
                BHPostsManager.shared.getPostByAlias(validUsername, postAlias: validAlias) { result in
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
                        DispatchQueue.main.async {
                            UIApplication.topViewController()?.showError("Failed to load episode details. This episode is no longer available.")
                        }
                        break
                    }
                }
            } else {
                UIApplication.topViewController()?.showError("Failed to load episode details. The Internet connection is lost.")
            }
            result = true
        }

        return result
    }
    
    fileprivate func resolveCategoryLink(_ linkInfo: UniversalLinkInfo) -> Bool {
        BHLog.p("\(#function) - alias: \(linkInfo.alias ?? "nil")")

        var result = false

        if let validAlias = linkInfo.alias {
            BHNetworkManager.shared.splitUsersForCarPlay()
            if let categoryModel = BHNetworkManager.shared.getCategoryModel(with: validAlias) {
                let bundle = Bundle.module
                let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
                let vc = storyboard.instantiateViewController(withIdentifier: BHCategoryViewController.storyboardIndentifer) as! BHCategoryViewController
                vc.categoryModel = categoryModel
                    
                UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
            } else {
                if BHReachabilityManager.shared.isConnected() {
                    let networkId = BHAppConfiguration.shared.networkId
                    BHNetworkManager.shared.fetchCategories(networkId) { result in
                        switch result {
                        case .success:
                            DispatchQueue.main.async {
                                BHNetworkManager.shared.splitUsersForCarPlay()
                                if let categoryModel = BHNetworkManager.shared.getCategoryModel(with: validAlias) {
                                    let bundle = Bundle.module
                                    let storyboard = UIStoryboard(name: StoryboardName.main, bundle: bundle)
                                    let vc = storyboard.instantiateViewController(withIdentifier: BHCategoryViewController.storyboardIndentifer) as! BHCategoryViewController
                                    vc.categoryModel = categoryModel
                                        
                                    UIApplication.topNavigationController()?.pushViewController(vc, animated: true)
                                }
                            }
                        case .failure(error: let e):
                            BHLog.w(e)
                            DispatchQueue.main.async {
                                UIApplication.topViewController()?.showError("Failed to load episode details. This episode is no longer available.")
                            }
                            break
                        }
                    }
                } else {
                    UIApplication.topViewController()?.showError("Failed to load category details. The Internet connection is lost.")
                }
            }
            result = true
        }
        
        return result
    }
}

