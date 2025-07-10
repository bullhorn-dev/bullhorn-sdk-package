
import Foundation

class BHSettingsManager {

    static let shared = BHSettingsManager()

    fileprivate var authToken: String {
        BHAccountManager.shared.authToken
    }

    fileprivate lazy var apiSettings = BHServerApiSettings.init(withApiType: .regular)
        
    var notificationsUsers: [BHUser] = []

    // MARK: - Public

    func getNotificationsUsers(_ completion: @escaping (BHServerApiBase.UsersResult) -> Void) {

        apiSettings.getNotificationsUsers(authToken: authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users):
                    self.notificationsUsers = users
                case .failure(error: let error):
                    BHLog.w("Notifications users load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func enableUserNotifications(_ userId: String, enable: Bool, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiSettings.enableUserNotifications(authToken: authToken, userId: userId, enable: enable) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    /// track event
                    let banner: BHTrackBanner = enable ? .notificationsOn : .notificationsOff
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: banner, context: user.shareLink?.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
                    BHTracker.shared.trackEvent(with: request)

                case .failure(error: let error):
                    BHLog.w("User enable: \(enable) notifications failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func getDownloadsUsers(_ completion: @escaping (BHServerApiBase.UsersResult) -> Void) {

        apiSettings.getDownloadsUsers(authToken: authToken) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(users: let users):
                    self.notificationsUsers = users
                case .failure(error: let error):
                    BHLog.w("Downloads users load failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func enableUserDownloads(_ userId: String, enable: Bool, completion: @escaping (BHServerApiUsers.UserResult) -> Void) {

        apiSettings.enableUserDownloads(authToken: authToken, userId: userId, enable: enable) { response in
            DispatchQueue.main.async {
                switch response {
                case .success(user: let user):
                    /// track event
                    let banner: BHTrackBanner = enable ? .downloadsOn : .downloadsOff
                    let request = BHTrackEventRequest.createRequest(category: .explore, action: .ui, banner: banner, context: user.shareLink?.absoluteString, podcastId: user.id, podcastTitle: user.fullName)
                    BHTracker.shared.trackEvent(with: request)
                    
                    if enable {
                        BHDownloadsManager.shared.autoDownloadNewEpisodesIfNeeded()
                    } else {
                        BHDownloadsManager.shared.removeAutoDownloads(for: user)
                    }

                case .failure(error: let error):
                    BHLog.w("User enable: \(enable) auto downloads failed \(error.localizedDescription)")
                }
                completion(response)
            }
        }
    }

    func reportProblem(_ params: Parameters, completion: @escaping (CommonResult) -> Void) {

        apiSettings.reportProblem(authToken: authToken, params: params) { response in
            switch response {
            case .success:
                break

            case .failure(error: let error):
                BHLog.w("Filed to send report: \(error.localizedDescription)")
            }
            completion(response)
        }
    }

    // MARK: - Initial fetch for screen

    func fetch(_ completion: @escaping (CommonResult) -> Void) {

        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        getNotificationsUsers() { response in
            switch response {
            case .success(users: _): break
            case .failure(error: let error):
                responseError = error
            }
            fetchGroup.leave()
        }

        fetchGroup.notify(queue: .main) {
            if let error = responseError {
                completion(.failure(error: error))
            } else {
                completion(.success)
            }
        }
    }
}

