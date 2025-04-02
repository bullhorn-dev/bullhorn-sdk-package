
//https://github.com/smakeev/SwiftAnonymousClass

import ObjectiveC
import Foundation

fileprivate var AssociatedObjectHandle: UInt8 = 0

class LifeBinder {
    var holder: Any?
    init(_ holder: Any?) {
        self.holder = holder
    }
}

public func _new<Type>(owner: AnyObject? = nil, _ objectCreator:()->Type) -> Type {
    let object = objectCreator()
    if let validOwner = owner {
        let binder = LifeBinder(object)
        objc_setAssociatedObject(validOwner, &AssociatedObjectHandle, binder, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    return object
}

