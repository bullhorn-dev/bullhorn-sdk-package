
import Foundation
internal import Alamofire

class BHTracker {

    var dispatchQueue = DispatchQueue.global()

    static let shared = BHTracker()

    fileprivate var clientId: String?
    
    fileprivate var events = [[String : Any]]()

    fileprivate var authToken: String {
        return BHAccountManager.shared.authToken
    }

    fileprivate lazy var api = BHServerApiEvents.init(withApiType: .sdk)
    
    fileprivate let trackEventsThreshold: TimeInterval = 30
    fileprivate var lastSendTime = Date().timeIntervalSince1970
        
    // MARK: - Public
    
    func start(with clientId: String) {
        BHLog.p("Tracker start")
        
        self.clientId = clientId

        BHUserSessionManager.shared.start()
    }
    
    func trackNewUserSessionEvent() {
        let request = BHTrackEventRequest.createRequest(category: .initiation, action: .sessionGen)
        let event = createEvent(request: request)
        events.append(event)

        track()
    }
    
    func trackEvent(with request: BHTrackEventRequest) {
        let event = createEvent(request: request)
        events.append(event)
        
        let currentTime = Date().timeIntervalSince1970

        if (currentTime - lastSendTime) > trackEventsThreshold {
            track()
            lastSendTime = currentTime
        }
    }
    
    // MARK: - Private
    
    fileprivate func track() {
        guard let cid = clientId else { return }
        guard events.count != 0 else { return }
        
        let params: [String : Any] = [
            "events" : events,
            "_t" : Int(Date().timeIntervalSince1970)
        ]

        api.sendEvents(authToken: authToken, clientId: cid, events: params) { result in
            switch result {
            case .success:
                debugPrint("Tracker events sent")
                self.events.removeAll()
            case .failure(error: let error):
                debugPrint("Tracker event send failed. Error: \(error.localizedDescription)")
            }
        }
    }
    
    fileprivate func createEvent(request: BHTrackEventRequest) -> [String : Any] {
        
        var params: [String : Any] = [
            "client": "mobile",
            "app_version": BHAppConfiguration.shared.appVersion(useBuildNumber: true),
            "hardware": BHDeviceUtils.shared.getDeviceName(),
            "os_platform": BHDeviceUtils.shared.getOSPlatform(),
            "os_version": BHDeviceUtils.shared.getOSVersion(),
            "device_id": BHDeviceUtils.shared.getDeviceId(),
            "message": "Bullhorn SDK event",
            "service": "bullhorn_sdk",
            "session_id": UserDefaults.standard.userSessionId ?? BHUserSessionManager.defaultSessionId,
            "timestamp": Int(Date().timeIntervalSince1970),
        ]
        
        params["category"] = request.category.rawValue
        params["action"] = request.action.rawValue

        if let banner = request.banner {
            params["banner"] = banner.rawValue
        }
        if let context = request.context {
            params["context"] = context
        }
        if let variant = request.variant {
            params["variant"] = variant
        }
        if let podcastId = request.podcastId {
            params["podcast_id"] = podcastId
        }
        if let podcastTitle = request.podcastTitle {
            params["podcast_title"] = podcastTitle
        }
        if let episodeId = request.episodeId {
            params["episode_id"] = episodeId
        }
        if let episodeTitle = request.episodeTitle {
            params["episode_title"] = episodeTitle
        }
        if let episodeType = request.episodeType {
            params["episode_type"] = episodeType
        }
        if let startedAt = request.startedAt, startedAt > 0 {
            params["started_at"] = startedAt
        }
        if let finishedAt = request.finishedAt, finishedAt > 0 {
            params["finished_at"] = finishedAt
        }
//        if let extraParams = request.extraParams {
//            params["extra_params"] = request.extraParams
//        }

        params["subscription_id"] = BHAccountManager.shared.user?.id ?? ""
        params["bullhorn_sdk_id"] = BullhornSdk.shared.clientId
        params["is_anonymous"] = String(BHAccountManager.shared.user?.isAnonymous ?? true)
        
        return params
    }
}
