
import  Foundation

public protocol ObserverProtocol: AnyObject {
    var objectIdentifier: ObjectIdentifier { get }
}

extension ObserverProtocol {
    public var objectIdentifier: ObjectIdentifier { return ObjectIdentifier.init(self) }
}

public protocol ObserversNotifierOnQueue {

    associatedtype T

    init(notifyQueue: DispatchQueue)

    func notifyObserversSync(block: (T) -> Void)
    func notifyObserversAsync(block: @escaping (T) -> Void)
}

public class ObserversContainer<T> {

    fileprivate struct ObserverWrapper<T> {

        fileprivate let instanceIdentifier: ObjectIdentifier
        private weak var instance: ObserverProtocol?

        fileprivate static func wrap(_ instance: ObserverProtocol) -> ObserverWrapper<T>? {
            return ObserverWrapper.init(instance)
        }

        fileprivate init?(_ instance: ObserverProtocol) {

            guard instance is T else { return nil }

            self.instance = instance
            instanceIdentifier = instance.objectIdentifier
        }

        fileprivate func unwrap() -> T? {
            return instance as? T
        }
    }

    fileprivate var observers = [ObserverWrapper<T>]()

    // MARK: - Public

    public init() {}

    @discardableResult public func addObserver(_ observer: ObserverProtocol) -> Bool {

        guard indexOfObserver(with: observer.objectIdentifier) == nil else { return false }

        return ObserverWrapper<T>.init(observer).map { observers.append($0) } != nil
    }

    public func removeObserver(_ observer: ObserverProtocol) {
        removeObserver(by: observer.objectIdentifier)
    }

    public func removeAll() {
        observers.removeAll()
    }

    public func notifyObservers(block: (T) -> Void) {
        observers.compactMap { $0.unwrap() }.forEach { block($0) }
    }

    // MARK: - Private

    private func indexOfObserver(with identifier: ObjectIdentifier) -> Int? {
        return observers.firstIndex { $0.instanceIdentifier == identifier }
    }

    private func removeObserver(by identifier: ObjectIdentifier) {

        guard let index = indexOfObserver(with: identifier) else { return }

        observers.remove(at: index)
    }
}

public class ObserversContainerNotifyingOnQueue<T>: ObserversContainer<T>, ObserversNotifierOnQueue {

    private let notifyQueue: DispatchQueue

    required public init(notifyQueue: DispatchQueue) {
        self.notifyQueue = notifyQueue

        super.init()
    }

    public func notifyObserversSync(block: (T) -> Void) {

        let observerInstances = observers.compactMap { $0.unwrap() }
        notifyQueue.sync { observerInstances.forEach { block($0) } }
    }

    public func notifyObserversAsync(block: @escaping (T) -> Void) {

        let observerInstances = observers.compactMap { $0.unwrap() }
        notifyQueue.async { observerInstances.forEach { block($0) } }
    }
}
