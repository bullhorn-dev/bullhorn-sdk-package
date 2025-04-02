
import Foundation

// MARK: - BHRadioStreamsListener

protocol BHRadioStreamsListener: ObserverProtocol {
    func radioStreamsManager(_ manager: BHRadioStreamsManager, radioDidChange radio: BHRadio)
}

// MARK: - BHRadioStreamsManager

class BHRadioStreamsManager {
    
    static let shared = BHRadioStreamsManager()
    
    var currentRadio: BHRadio? {
        return radios.first
    }
    
    var currentStream: BHStream? {
        return radios.first?.streams.first
    }

    var radios: [BHRadio] = []
    
    var otherRadios: [BHRadio] {
        if radios.count > 1 {
            return Array(radios.dropFirst())
        }
        return []
    }

    var hasRadioStreams: Bool {
        return /*streams.count > 0 &&*/ shouldLoadRadios()
    }

    private let observersContainer: ObserversContainerNotifyingOnQueue<BHRadioStreamsListener>
    private let workingQueue = DispatchQueue.init(label: "BHRadioStreamsManager.Working", target: .global())

    private var timer: Timer?
    private var timerInterval: TimeInterval = 30 // sec

    init() {
        observersContainer = .init(notifyQueue: workingQueue)
    }
    
    deinit {
        stopTrackTimer()
    }

    // MARK: - Public listener

    func addListener(_ listener: BHRadioStreamsListener) {
        workingQueue.async { self.observersContainer.addObserver(listener) }
    }

    func removeListener(_ listener: BHRadioStreamsListener) {
        workingQueue.async { self.observersContainer.removeObserver(listener) }
    }

    // MARK: - Public
    
    func shouldLoadRadios() -> Bool {
        let networkId = BHAppConfiguration.shared.foxNetworkId
        return networkId == "540ea6c1-7e9c-4e2e-b3e0-09a5b1c378cd"
    }
    
    func updateCurrentStream() {
        BHLog.p("\(#function)")

        guard let radio = currentRadio else { return }
        guard let post = radio.asPost() else { return }

        observersContainer.notifyObserversAsync {
            $0.radioStreamsManager(self, radioDidChange: radio)
        }
                        
        if BHHybridPlayer.shared.isActive(), let playingPostId = BHHybridPlayer.shared.post?.id, playingPostId == post.id {
            BHHybridPlayer.shared.updatePlayingItemInfo(with: post)
        }
        
        startTrackTimer()
    }

    
    // MARK: - Network
    
    fileprivate func getRadios(_ networkId: String, completion: @escaping (BHServerApiNetwork.RadiosResult) -> Void) {
        
        BHNetworkManager.shared.getNetworkRadios(BHAppConfiguration.shared.foxNetworkId) { response in
            switch response {
            case .success(radios: _):
                self.fetchStorageRadios(networkId) { _ in }
            case .failure(error: let error):
                BHLog.w(error)
            }
            completion(response)
        }
    }
    
    func fetch(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        if shouldLoadRadios() {
            getRadios(networkId) { response in
                switch response {
                case .success(radios: _):
                    break
                case .failure(error: let error):
                    responseError = error
                }
                fetchGroup.leave()
            }
        } else {
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
    
    // MARK: - Data Storage
        
    func fetchStorageRadios(_ networkId: String, completion: @escaping (CommonResult) -> Void) {

        DataBaseManager.shared.fetchNetworkRadios(with: networkId) { response in
            switch response {
            case .success(radios: let radios):
                self.radios = radios
                completion(.success)
            case .failure(error: let error):
                completion(.failure(error: error))
            }
        }
    }
    
    func fetchStorage(_ networkId: String, completion: @escaping (CommonResult) -> Void) {
        
        let fetchGroup = DispatchGroup()
        var responseError: Error?
        
        fetchGroup.enter()

        if shouldLoadRadios() {
            fetchStorageRadios(networkId) { response in
                switch response {
                case .success:
                    break
                case .failure(error: let error):
                    responseError = error
                }
                fetchGroup.leave()
            }
        } else {
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
    
    // MARK: - Timer

    fileprivate func startTrackTimer() {

        if let currentTimer = timer, currentTimer.isValid { return }

        let timer = Timer(timeInterval: timerInterval, target: self, selector: #selector(timerHandler(_:)), userInfo: nil, repeats: true)
        timer.tolerance = timerInterval
        RunLoop.main.add(timer, forMode: .common)
        timer.tolerance = 0.1

        self.timer = timer
    }
    
    fileprivate func stopTrackTimer() {

        guard let validTimer = timer else { return }

        validTimer.invalidate()
        timer = nil
    }

    @objc fileprivate func timerHandler(_ timer: Timer) {

        guard timer.isValid else { return }

        self.timer = nil
        
        guard let validStream = currentStream else { return }
        
        if validStream.isTimeToUpdate() {
            getRadios(BHAppConfiguration.shared.foxNetworkId) { response in
                switch response {
                case .success(radios: let radios):
                    self.radios = radios
                    self.updateCurrentStream()
                case .failure(error: let error):
                    BHLog.w(error)
                }
            }
        }
    }
}

