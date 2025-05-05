
import Foundation

class BHAccountManager {

    static let AccountChangedNotification = Notification.Name(rawValue: "BHAccountManager.AccountChangedNotification")
    static let NotificationInfoKey = "BHAccountManager.NotificationInfoKey"
    
    struct AccountChangedNotificationInfo {
        
        enum Reason: String {
            case restore
            case login
            case signup
            case logout
            case update
            case fail
        }
        
        let what: BHAccount.Difference
        let reason: Reason
        let account: BHAccount?
    }
    
    enum AccountResult {
        case success(account: BHAccount)
        case failure(error: Error)
    }
        
    // MARK: - Properties

    static let shared: BHAccountManager = BHAccountManager()

    var authToken: String { return account?.authToken ?? "" }
    var user: BHSelfUser? { return account?.user }
    var isLoggedIn: Bool { return account?.isValid ?? false }

    fileprivate(set) var account: BHAccount? { willSet { assert(Thread.isMainThread, "Account object must be set in main thread only") } }

    fileprivate lazy var server = BHServerApiUsers.init(withApiType: .regular)
    fileprivate lazy var serverSdk = BHServerApiUsers.init(withApiType: .sdk)

    func isMe(_ userId: String?) -> Bool {
        guard let validUserId = userId else { return false }
        guard let validMyUserId = user?.id else { return false }
        
        return validUserId == validMyUserId
    }

    // MARK: - Public

    func configure() -> Bool {
        if let sdkUserId = UserDefaults.standard.sdkUserId {
            return restoreAccount(with: sdkUserId)
        }
        return false
    }
    
    func update(with account: BHAccount) -> AccountResult {
        return setAccount(with: AccountResult.success(account: account), reason: .update)
    }

    func logout() {

        guard isLoggedIn else { return }

        notifyAccountChanged(with: .all, reason: .logout)

        account = nil
        storeAccountData()
    }
    
    func restoreAccount(with userId: String) -> Bool {
        
        guard let anonymousAuthToken = UserDefaults.standard.authToken,
              let anonymousUserId = UserDefaults.standard.userId,
              let sdkUserId = UserDefaults.standard.sdkUserId else {
            return false
        }
        
        BHLog.p("\(#function) - userId: \(anonymousUserId), sdkUserId: \(sdkUserId)")
        
//        if userId != sdkUserId {
//            BHLog.p("\(#function) - Login is necessary")
//            isNewUser = true
//            return false
//        }

        let user = BHSelfUser.init(withIdentifier: anonymousUserId)
        user.sdkUserId = sdkUserId
        user.fullName = UserDefaults.standard.sdkUserName
        if let profilePicture = UserDefaults.standard.sdkUserIcon {
            user.profilePicture = URL(string: profilePicture)
        }

        account = BHAccount.init(user: user, authToken: anonymousAuthToken)

        let result = account != nil
        if result {
            notifyAccountChanged(with: .all, reason: .restore)
        }

        return result
    }
    
    func loginAnonymously(completion: @escaping (AccountResult) -> Void) {
        
        server.getAuthTokenAnonymously() { (response: BHServerApiUsers.SelfUserResult) in
            switch response {
            case .success(user: let user):
                let account = BHAccount.parse(from: user)
                let accountSetResult = self.setAccount(with: .success(account: account), reason: .login)
                completion(accountSetResult)
            case .failure(error: let error):
                BHLog.w("Failed login anonymously \(error.localizedDescription)")
                completion(.failure(error: error))
            }
        }
    }
        
    func loginSdkUser(clientId: String, sdkUserId: String, fullName: String?, profilePictureUri: String?, completion: @escaping (AccountResult) -> Void) {
        
        serverSdk.loginSdkUser(clientId: clientId, authToken: authToken, sdkUserId: sdkUserId, fullName: fullName, profilePictureUri: profilePictureUri) { (response: BHServerApiUsers.SelfUserResult) in
            switch response {
            case .success(user: let user):
                let account = BHAccount.parse(from: user)
                if let validProfilePictureUri = profilePictureUri {
                    account.user.profilePicture = URL(string: validProfilePictureUri)
                } else {
                    account.user.profilePicture = nil
                }
                let accountSetResult = self.setAccount(with: .success(account: account), reason: .login)
                completion(accountSetResult)
            case .failure(error: let error):
                BHLog.w("Failed login sdk user \(error.localizedDescription)")
                completion(.failure(error: error))
            }
        }
    }

    // MARK: - Private
    
    fileprivate func notifyAccountChanged(with difference: BHAccount.Difference, reason: AccountChangedNotificationInfo.Reason) {

        let infoObject = AccountChangedNotificationInfo.init(what: difference, reason: reason, account: account)
        let info = [BHAccountManager.NotificationInfoKey: infoObject]

        NotificationCenter.default.post(name: BHAccountManager.AccountChangedNotification, object: self, userInfo: info)
    }
}

// MARK: - Save/Restore

extension BHAccountManager {
        
    fileprivate func storeAccountData() {

        UserDefaults.standard.authToken = account?.authToken
        UserDefaults.standard.userId = account?.user.id
        UserDefaults.standard.sdkUserId = account?.user.sdkUserId
        UserDefaults.standard.sdkUserName = account?.user.fullName
        UserDefaults.standard.sdkUserIcon = account?.user.profilePicture?.absoluteString
    }

    fileprivate func setAccount(with accountResult: AccountResult, reason: AccountChangedNotificationInfo.Reason) -> AccountResult {

//        assert(!Thread.isMainThread, "\(#function) must be called from non-main thread")

        let result: AccountResult

        switch accountResult {
        case .success(let account):
            if account.isValid {
                self.account = account
                self.storeAccountData()
                self.notifyAccountChanged(with: .all, reason: .update)
            }
            result = accountResult

        default:
            result = accountResult
        }

        return result
    }
}
