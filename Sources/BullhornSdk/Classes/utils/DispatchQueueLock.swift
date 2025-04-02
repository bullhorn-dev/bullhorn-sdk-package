
import Foundation

//@available(OSX 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
public func dispatchAssert(condition: @autoclosure () -> DispatchPredicate) {
#if DEBUG
    guard #available(iOS 10, *) else { return }
    Dispatch.dispatchPrecondition(condition: condition())
#endif
}

public func dispatchAssert(onQueue queue: DispatchQueue) {
    dispatchAssert(condition: DispatchPredicate.onQueue(queue))
}

public func dispatchAssert(onQueueAsBarrier queue: DispatchQueue) {
    dispatchAssert(condition: DispatchPredicate.onQueueAsBarrier(queue))
}

public func dispatchAssert(notOnQueue queue: DispatchQueue) {
    dispatchAssert(condition: DispatchPredicate.notOnQueue(queue))
}


final class DispatchQueueLock {

    let queue: DispatchQueue

    init(with queue: DispatchQueue) {
        self.queue = queue
    }

    convenience init(label: String, qos: DispatchQoS = .userInitiated) {

        let queue = DispatchQueue.init(label: label, qos: .userInitiated, attributes: .concurrent)

        self.init(with: queue)
    }

    func write(_ block: @escaping () -> Void) {
        queue.async(flags: .barrier, execute: block)
    }

    func read<T>(_ block: () -> T) -> T {
        return queue.sync { block() }
    }

    func exec(_ block: () -> Void) {
        queue.sync(execute: block)
    }
}
