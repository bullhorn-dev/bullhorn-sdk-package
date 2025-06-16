
import Foundation
import Network
internal import Alamofire

class BHReachabilityManager: NSObject {
    
    static let ConnectionChangedNotification = Notification.Name(rawValue: "ReachabilityManager.ConnectionChangedNotification")
    static let NotificationInfoKey = "NotificationInfoKey"
    
    struct ConnectionChangedNotificationInfo {
        
        enum ConnectionType: String {
            case connected
            case connectedExpensive
            case unavailable
        }
        
        let type: ConnectionType
    }

    static let shared: BHReachabilityManager = BHReachabilityManager()
    
    private let afManager = Alamofire.NetworkReachabilityManager(host: "www.apple.com")
        
    override init() {
        super.init()

        afManager?.startListening(onUpdatePerforming: { listener in
            
            var type: ConnectionChangedNotificationInfo.ConnectionType = .unavailable

            switch listener {
            case .unknown:
                BHLog.p("Reachability. Alamofire unknown")
                break
            case .notReachable:
                BHLog.p("Reachability. Alamofire notReachable")
            case .reachable(_):
                BHLog.p("Reachability. Alamofire reachable")

                if self.isConnectedExpensive() {
                    BHLog.p("Reachability. Connected expensive")
                    type = .connectedExpensive
                } else {
                    BHLog.p("Reachability. Connected")
                    type = .connected
                }
            }
            
            self.notifyNetworkStatus(type)
        })
    }
    
    deinit {
        afManager?.stopListening()
    }
    
    // MARK: - Private
    
    private func notifyNetworkStatus(_ type: ConnectionChangedNotificationInfo.ConnectionType) {
        DispatchQueue.main.async {
            let infoObject = ConnectionChangedNotificationInfo.init(type: type)
            let info = [BHReachabilityManager.NotificationInfoKey: infoObject]

            NotificationCenter.default.post(name: BHReachabilityManager.ConnectionChangedNotification, object: self, userInfo: info)
        }
    }
    
    // MARK: - Public
    
    func isConnected() -> Bool {
        return afManager?.isReachable == true
    }
    
    func isConnectedExpensive() -> Bool {
        return isConnected() && afManager?.isReachableOnCellular == true
    }
}

