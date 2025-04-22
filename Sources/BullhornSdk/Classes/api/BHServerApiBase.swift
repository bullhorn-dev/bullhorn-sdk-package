
import Foundation
internal import Alamofire

// MARK: - Server Api Error

enum ServerApiError: Error {
    case unknown(e: Error?)
    case network(e: Error?, r: URLResponse?)

    case invalidURL(urlString: String)
    case errorCode(c: Int, m: String?)
    case jsonSerializationError(e: Error)
    case parseError(m: String, data: Any)
    case canceled
}

// MARK: - Common Result

enum CommonResult {
    case success
    case failure(error: Error)
}

class BHServerApiBase: NSObject {
    
    enum BHApiType: String {
        case regular = "api_regular"
        case interactive = "api_interactive"
        case sdk = "api_sdk"
    }
    
    // MARK: - Meta

    struct Meta: Codable {
        
        enum CodingKeys: String, CodingKey {
            case status
            case code
            case message
            case pages
            case items
            case page
        }
        
        let status: String
        let code: Int
        let message: String
        let pages: Int
        let items: Int
        let page: Int
    }

    // MARK: - Posts Result

    struct Posts: Codable {
        
        enum CodingKeys: String, CodingKey {
            case posts
        }
        
        var posts: [BHPost]
    }

    enum PostsResult {
        case success(posts: [BHPost])
        case failure(error: Error)
    }

    // MARK: - Paginated Posts Result

    struct PaginatedPosts: Codable {
        
        enum CodingKeys: String, CodingKey {
            case posts
            case meta
        }
        
        var posts: [BHPost]
        var meta: Meta
    }

    enum PaginatedPostsResult {
        case success(posts: [BHPost], page: Int, pages: Int)
        case failure(error: Error)
    }

    // MARK: - Users Result

    struct Users: Codable {
        
        enum CodingKeys: String, CodingKey {
            case users
        }
        
        var users: [BHUser]
    }

    enum UsersResult {
        case success(users: [BHUser])
        case failure(error: Error)
    }
    
    // MARK: - Short Users Result

    struct ShortUsers: Codable {
        
        enum CodingKeys: String, CodingKey {
            case users
        }
        
        var users: [BHUserShort]
    }

    enum ShortUsersResult {
        case success(users: [BHUserShort])
        case failure(error: Error)
    }

    // MARK: - Paginated Users Result

    struct PaginatedUsers: Codable {
        
        enum CodingKeys: String, CodingKey {
            case users
            case meta
        }
        
        var users: [BHUser]
        var meta: Meta
    }

    enum PaginatedUsersResult {
        case success(users: [BHUser], page: Int, pages: Int)
        case failure(error: Error)
    }

    private var baseApiURL = BHConfigManager.shared.configData?.serverApiV1String ?? ""
    private var baseApiInteractiveURL = BHConfigManager.shared.configData?.serverApiInteractiveV1String ?? ""
    private var baseApiSdkUrl = BHConfigManager.shared.configData?.serverApiSdkV1String ?? ""
    
    let defaultPageCount: Int = 20
    
    private(set) var apiType: BHApiType

    // MARK: - Initialization

    init(withApiType type: BHApiType = .regular) {
        self.apiType = type
        super.init()
    }

    // MARK: - Private
    
    private func baseApiUrl() -> String {
        switch apiType {
        case .regular:
            return baseApiURL
        case .interactive:
            return baseApiInteractiveURL
        case .sdk:
            return baseApiSdkUrl
        }
    }
    
    private func contentType() -> String {
        switch apiType {
        case .regular:
            return "application/json"
        case .interactive:
            return "application/vnd.api+json"
        case .sdk:
            return "application/json"
        }
    }

    // MARK: - Public

    func composeFullApiURL(with path: String) -> String {

        guard !baseApiURL.isEmpty && !baseApiInteractiveURL.isEmpty && !path.isEmpty else { return String() }

        let baseUrl = baseApiUrl()

        guard !path.isEmpty else { return baseUrl }

        let apiURL: String

        let slashSymbol = "/"
        if !baseUrl.hasSuffix(slashSymbol) && !path.hasPrefix(slashSymbol) {
            apiURL = baseUrl + slashSymbol + path
        }
        else if baseUrl.hasSuffix(slashSymbol) && path.hasPrefix(slashSymbol) {
            var cleanedPath = path
            cleanedPath.remove(at: cleanedPath.startIndex)
            apiURL = baseUrl + cleanedPath
        }
        else {
            apiURL = baseUrl + path
        }

        return apiURL
    }
    
    func composeHeaders(_ authToken: String?) -> HTTPHeaders {

        let contentType = contentType()
        
        guard let token = authToken else {
            return [ .contentType(contentType) ]
        }
    
        return [
            .authorization(bearerToken: token),
            .authorization("Token token=\(token)"),
            .contentType(contentType)
        ]
    }
    
    func composePostHeaders(_ authToken: String?) -> HTTPHeaders {
        guard let token = authToken else { return [] }
    
        return [ .authorization("Token token=\(token)") ]
    }

    func composeIncluded(_ include: String) -> [String : String] {
        return ["include" : include]
    }
    
    func composeInclude(_ include: String) -> String {
        return "&include=" + include
    }
    
    func composePageFilter(page: Int?) -> String {

        guard let validPage = page else { return "" }

        return "?filter[page]=" + String(validPage)
    }
    
    func composePerPageFilter(perPage: Int?) -> String {

        guard let validValue = perPage else { return "" }

        return "&filter[per_page]=" + String(validValue)
    }
    
    func composeStatusFilter(status: String?) -> String {

        guard let validStatus = status else { return "" }
        
        return "&filter[status]=" + String(validStatus)
    }
        
    func composeTextFilter(text: String?) -> String {

        guard let validText = text else { return "" }
        guard !validText.isEmpty else { return "" }

        return "&filter[text]=" + validText
    }
    
    func composeContext(text: String?) -> String {

        guard let validText = text else { return "" }
        guard !validText.isEmpty else { return "" }

        return "?&context=" + validText
    }
    
    func composeNetworkId(text: String?) -> String {

        guard let validText = text else { return "" }
        guard !validText.isEmpty else { return "" }

        return "&network_id=" + validText
    }

    func composeNetworkIdFilter(networkId: String?) -> String {

        guard let validNetworkId = networkId else { return "" }

        return "&filter[network_id]=" + validNetworkId
    }
    
    func composeWithLivesFilter(value: Bool = true) -> String {
       return "&filter[with_lives]=" + String(value)
    }

    func composeOrderFilter(order: String) -> String {
       return "&order=" + order
    }
    
    func composeFullName(_ name: String?) -> String {
        guard let validName = name, validName.count > 0 else { return "" }
        return "&full_name=" + validName
    }

    func composeProfilePictureUri(_ uri: String?) -> String {
        guard let validUri = uri, validUri.count > 0 else { return "" }
        return "&original_profile_picture_uri=" + validUri
    }

    func composeSdkUserId(_ id: String?) -> String {
        guard let validId = id, validId.count > 0 else { return "" }
        return "?sdk_user_id=" + validId
    }

    func updateConfig(completion: @escaping (ServerApiError?) -> Void) {

        var error: ServerApiError?

        if BHConfigManager.shared.isRefreshNeeded {
            BHConfigManager.shared.getConfig { result in
                                
                switch result {
                case .success(let c):
                    self.baseApiURL = c.serverApiV1String
                    self.baseApiInteractiveURL = c.serverApiInteractiveV1String
                    self.baseApiSdkUrl = c.serverApiSdkV1String
                    
                case .fallback(let config, let configError):
                    if let validConfig = config {
                        self.baseApiURL = validConfig.serverApiV1String
                        self.baseApiInteractiveURL = validConfig.serverApiInteractiveV1String
                        self.baseApiSdkUrl = validConfig.serverApiSdkV1String
                    }
                    if let validConfigError = configError {
                        switch validConfigError {
                        case .commonError(let e): error = ServerApiError.network(e: e, r: nil)
                        default: error = ServerApiError.network(e: validConfigError, r: nil)
                        }
                    }
                    else {
                        error = ServerApiError.unknown(e: nil)
                    }
                }
                
                completion(error)
            }
        } else {
            completion(error)
        }
    }

    func cancelAllTasks() {
        AF.cancelAllRequests()
    }
    
    func trackError(_ error: Error) {
        let request = BHTrackEventRequest.createRequest(category: .explore, action: .error, banner: .contentLoadFailed, context: error.localizedDescription)
        BHTracker.shared.trackEvent(with: request)
    }
 }
