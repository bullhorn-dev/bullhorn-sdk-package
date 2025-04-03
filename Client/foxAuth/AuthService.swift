
import Foundation
import UIKit
import FoxKitProfile

final public class AuthService {

    public static let AccountChangedNotification = Notification.Name(rawValue: "AuthService.AccountChangedNotification")

    public static let shared = AuthService()
        
    var profileInfo: ProfileInformation?
    
    private let config = AuthConfig.shared
    private let service = ProfileService.shared
    private var serviceError: ProfileServiceError?

    private var profileConfiguration: ProfileService.Configuration
    
    init() {
        
        let qa_env: Bool = (Bundle.main.infoDictionary?["CFBundleName"] as! String).contains("QA")

        self.profileConfiguration = ProfileService.Configuration(
            apiKey: config.apiKey,
            preferencesApiKey: config.preferencesApiKey,
            accessToken: config.accessToken,
            dcgUdid: config.deviceId,
            baseURL: config.baseApiURL,
            productAPIBaseUrl: config.productApiProdBaseUrl,
            xidBaseUrl: config.xidBaseURL_Prod,
            xidEventBaseUrl: config.xidEventBaseURL_Prod,
            preferencesBaseUrl: config.preferencesBaseURL,
            dma: nil,
            foxClient: nil,
            cohorts: nil,
            deviceIp: nil,
            userLocation: nil,
            experimentGroups: nil,
            applicationId: config.applicationId,
            sessionId: config.sessionId,
            environment: qa_env ? .qa : .prod
        )

        service.setup(withConfiguration: profileConfiguration)
    }

    // MARK: - Public
    
    public var hasAuth: Bool {
        return profileInfo != nil
    }
    
    public var hasError: Bool {
        return serviceError != nil
    }
    
    public var serviceErrorDescription: String {
        return serviceError?.localizedDescription ?? ""
    }

    public var serviceErrorMessage: String? {
        return handleProfileServiceError(serviceError)
    }

    public var profileId: String? {
        return profileInfo?.profileId
    }
    
    public var profileEmail: String? {
        return profileInfo?.email
    }
    
    //
    
    public var encodedProfile: Data? {
        guard let validInfo = profileInfo else { return nil }
        
        if let encoded = try? NSKeyedArchiver.archivedData(withRootObject: validInfo, requiringSecureCoding: true) {
            return encoded
        }
        
        return nil
    }
    
    public func setEncodedProfile(_ encoded: Data) {
        let decoded = try! NSKeyedUnarchiver.unarchivedObject(ofClass: ProfileInformation.self, from: encoded)
        if let validInfo = decoded {
            profileInfo = validInfo
            updateProfileConfiguration(accessToken: validInfo.accessToken ?? "")
        }
    }
    
    func storedFoxAuth() -> Data? {
        return UserDefaults.standard.data(forKey: "foxAuth")
    }
    
    func store(foxAuth: Data?) {
        UserDefaults.standard.set(foxAuth, forKey: "foxAuth")
        notifyAccountChanged()
        return
    }
    
    // MARK: - Network

    public func signupWith(email: String, password: String, displayName: String?, completion: @escaping (Bool) -> Void) {
        service.registerV2(
            email: email,
            password: password,
            displayName: displayName
        ) { regRes in
            completion(self.handleResult(regRes))
        }
    }
    
    public func loginWith(email: String, password: String, completion: @escaping (Bool) -> Void) {
        let authBuilder = ProfileAuthBuilder<ProfileLogin>()
            .setEmail(email)
            .setPassword(password)
            .build()
        
        service.loginV2(
            auth: authBuilder
        ) { logRes in            
            completion(self.handleResult(logRes))
        }
    }
    
    public func refresh(completion: @escaping (Bool) -> Void) {
        guard let refreshToken = profileInfo?.refreshToken else {
            completion(false)
            return
        }
        
        service.refreshToken(refreshToken) { refRes in
            completion(self.handleResult(refRes))
        }
    }
    
    public func logout(completion: @escaping (Bool) -> Void) {
        guard let accessToken = profileInfo?.accessToken else {
            completion(false)
            return
        }
        
        service.logoutV2(
            refreshTokenHint: accessToken
        ) { logoutRes in
            completion(self.handleResult(logoutRes))
        }
    }

    public func delete(completion: @escaping (Bool) -> Void) {
        guard let profileId = profileInfo?.profileId else {
            completion(false)
            return
        }
        
        service.deleteProfile(withId: profileId) {
             deleteRes in
            completion(self.handleResult(deleteRes))
        }
    }
    
    // MARK: - Private
        
    private func updateProfileConfiguration(accessToken: String) {
        profileConfiguration.accessToken = accessToken
        service.updateJWTAccessToken(accessToken)
    }

    private func handleResult<T>(_ result: ProfileServiceResult<T>) -> Bool {
        serviceError = nil;
        
        switch result {
        case let .success(response, _, _):
            
            if let value = response as? ProfileUserResponse,
               let accessToken = value.accessToken  {
                profileInfo = ProfileInformation(loginResponse: value)
                updateProfileConfiguration(accessToken: accessToken)
                return true;
            } 
            
            // Todo, LXC: What should be done with hasIncompleteStatus with no tokens ? 
            /* else if let value = response as? ProfileUserResponse, value.hasIncompleteStatus {
                let profileInfo = ProfileInformation(loginResponse: value)
                self.profileInfo = profileInfo
                return true;
            } */
            
            else if response is ProfileLogoutResponse {
                profileInfo = nil;
                updateProfileConfiguration(accessToken: "")
                return true;
            } 
            
            else if let value = response as? RefreshTokenResponse,
                      let accessToken = value.accessToken,
                      let refreshToken = value.refreshToken {
                profileInfo?.accessToken = accessToken
                profileInfo?.refreshToken = refreshToken
                updateProfileConfiguration(accessToken: accessToken)
                return true
            }
            
            else if response is ProfileUpdateResponse {
                profileInfo = nil;
                updateProfileConfiguration(accessToken: "")
                return true;
            }
            
            return false
            
        case let .failure(error):
            serviceError = error
            return false
        }
    }
    
    private func handleProfileServiceError(_ profileServiceError: ProfileServiceError?) -> String? {
        guard let validProfileServiceError = profileServiceError else { return nil }
        var resultMessage: String?
        
        switch validProfileServiceError {
        case let .serviceError(error: serviceError):
            switch serviceError {
            case let .server(_, errorInfo, _, _):
                let errorJson = errorInfo?.message?.toJSON() as? [String:AnyObject]
                if let message = errorJson?["message"] as? String {
                    resultMessage = message
                } else {
                    resultMessage = nil
                }
            case .badRequest(message: let message, httpCode: _, responseTimeInMilliseconds: _):
                resultMessage = message
            case .invalidRequestUrl(url: let url):
                resultMessage = "Invalid request url: \(url)"
            case .notConnected(responseTimeInMilliseconds: _):
                resultMessage = "The Internet connection appears to be offline"
            case .requestTimedOut(responseTimeInMilliseconds: _):
                resultMessage = "Request timed out"
            case .internalInconsistency(message: let message, httpCode: _, responseTimeInMilliseconds: _):
                resultMessage = message
            default:
                resultMessage = "Internal server error"
            }
        case .notInitialized:
            resultMessage = "The service has not been initialized yet"
        case .internalInconsistency(message: let message):
            resultMessage = message
        default:
            resultMessage = "Internal server error"
        }
        
        return resultMessage
    }
    
    fileprivate func notifyAccountChanged() {
        NotificationCenter.default.post(name: AuthService.AccountChangedNotification, object: self, userInfo: nil)
    }
}

extension String {

    func toJSON() -> Any? {
        guard let data = self.data(using: .utf8, allowLossyConversion: false) else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
    }
}
