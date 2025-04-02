
import Foundation

class BHConfigManager: NSObject {

    static let ConfigChangedNotification = Notification.Name.init("BHConfigManager.ConfigChangedNotification")

    enum WebConfigManagerResult {
        case success(c: BHConfigBody)
        case fallback(c: BHConfigBody?, e: WebConfigManagerError?)
    }

    enum WebConfigManagerError: Error {
        case invalidURL
        case failedToParse
        case commonError(e: Error?)
    }

    static let shared = BHConfigManager()

    var isRefreshNeeded: Bool {
        return configData == nil
    }

    private(set) var configData: BHConfigBody? {
        didSet {
            guard configData != nil else { return }
            guard configData != oldValue else { return }

            NotificationCenter.default.post(name: BHConfigManager.ConfigChangedNotification, object: configData)
        }
    }

    private let workingQueue = DispatchQueue.init(label: "WebConfigManagerQueue", qos: .userInitiated)
    private var workItem: DispatchWorkItem?
    private var lastError: WebConfigManagerError?

    private var currentResult: WebConfigManagerResult {
        if let validConfig = configData, lastError == nil {
            return .success(c: validConfig)
        }
        else {
            return .fallback(c: configData, e: lastError)
        }
    }

    // MARK: - Public

    func setNeedsRefresh() {
        workItem = nil
    }

    func setNeedsRefreshAndGetConfig() {

        setNeedsRefresh()
        getConfig { _ in }
    }

    func getConfig(completion: @escaping (WebConfigManagerResult) -> Void) {

        if let validWorkItem = workItem {
            validWorkItem.notify(queue: .main) { completion(self.currentResult) }
            return
        }

        refreshConfig(completion: completion)
    }
    
    func updateConfig(_ newConfigData: BHConfigBody) {
        configData = newConfigData
    }

    // MARK: - Private

    private func refreshConfig(completion: @escaping (WebConfigManagerResult) -> Void) {

        guard let webConfigURL = URL.init(string: BHAppConfiguration.shared.webConfigURLString) else {
            DispatchQueue.main.async { completion(self.currentResult) }
            return
        }

        let newWorkItem = composeWorkItem(for: webConfigURL) { config, error in
            self.lastError = error

            if config != nil {
                self.configData = config
            }
            else {
                self.setNeedsRefresh()
            }
        }
        workItem = newWorkItem

        newWorkItem.notify(queue: .main, execute: {
            completion(self.currentResult)
        })
        workingQueue.async(execute: newWorkItem)
    }

    private func composeWorkItem(for url: URL, completion: @escaping (BHConfigBody?, WebConfigManagerError?) -> Void) -> DispatchWorkItem {

        let session = URLSession.init(configuration: URLSessionConfiguration.ephemeral)
        let request = URLRequest.init(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 30.0)

        return DispatchWorkItem.init(block: {

            let semaphore = DispatchSemaphore.init(value: 0)
            let task = session.dataTask(with: request) { data, response, error in

                var configData: BHConfigBody?
                var configError: WebConfigManagerError?

                if error == nil && data != nil {
                    if let jsonObject = try? JSONSerialization.jsonObject(with: data!), let validConfigData = BHConfigBody.fromJSON(jsonObject) {
                        configData = validConfigData
                        BHLog.p("BHConfigBody = \(String(describing: validConfigData))")
                    }
                    else {
                        configError = WebConfigManagerError.failedToParse
                        BHLog.w("Error parsing WebConfigBody")
                    }
                }
                else {
                    configError = WebConfigManagerError.commonError(e: error)
                    BHLog.w("Error retreiving WebConfig: \(String(describing: error))")
                }

                DispatchQueue.main.sync { completion(configData, configError) }
                semaphore.signal()
            }

            task.resume()
            semaphore.wait()
        })
    }
}
