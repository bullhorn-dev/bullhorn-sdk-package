
import Foundation
import Network

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

    let pathMonitor = NWPathMonitor()
    
    var isPreviouslyConnected = true
    
    override init() {
        super.init()
        
        pathMonitor.pathUpdateHandler = { path in
            
            var type: ConnectionChangedNotificationInfo.ConnectionType = .unavailable
            var isConnected = false
            
            BHLog.p("Reachability. Path status: \(path.status)")

            if path.status == .satisfied {

                isConnected = true

                if path.isExpensive {
                    BHLog.p("Reachability. Connected expensive")
                    type = .connectedExpensive
                } else {
                    BHLog.p("Reachability. Connected")
                    type = .connected
                }
            } else {
                BHLog.p("Reachability. No connection. Reason: \(path.unsatisfiedReason)")
            }
                        
            if self.isPreviouslyConnected != isConnected {
                DispatchQueue.main.sync {
                    let infoObject = ConnectionChangedNotificationInfo.init(type: type)
                    let info = [BHReachabilityManager.NotificationInfoKey: infoObject]

                    NotificationCenter.default.post(name: BHReachabilityManager.ConnectionChangedNotification, object: self, userInfo: info)
                }
            }
            
            self.isPreviouslyConnected = isConnected

        }
        
        let queue = DispatchQueue(label: "Monitor")
        pathMonitor.start(queue: queue)
    }
    
    deinit {
        pathMonitor.cancel()
    }
    
    // MARK: - Public
    
    func isConnected() -> Bool {
        return pathMonitor.currentPath.status == .satisfied
    }
    
    func isConnectedExpensive() -> Bool {
        return pathMonitor.currentPath.status == .satisfied && pathMonitor.currentPath.isExpensive
    }
}

