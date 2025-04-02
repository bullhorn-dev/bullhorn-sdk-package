
import Foundation

struct Version: Equatable {

    enum Depth: Int {
        case prime = 0
        case major = 1
        case minor = 2
        case build = 3
    }

    struct Diff {

        let depth: Version.Depth
        let order: ComparisonResult
    }

    let components: [UInt]
    let isValid: Bool

    var prime: UInt {
        return getComponent(depth: .prime)
    }
    var major: UInt {
        return getComponent(depth: .major)
    }
    var minor: UInt {
        return getComponent(depth: .minor)
    }
    var build: UInt {
        return getComponent(depth: .build)
    }

    init(from stringValue: String) {

        let stringComponents = stringValue.components(separatedBy: ".")

        var convertedComponents = [UInt]()
        for singleStringComponent in stringComponents {
            if let convertedComponent = UInt(singleStringComponent) {
                convertedComponents.append(convertedComponent)
            }
            else {
                break
            }
        }

        isValid = convertedComponents.count > 0
        components = convertedComponents
    }

    func firstDiff(from another: Version) -> Diff? {

        guard isValid && another.isValid else { return nil }

        var result: Diff?

        let allComponentDepths: [Depth] = [.prime, .major, .minor, .build]
        for depth in allComponentDepths {
            let selfComponentValue = getComponent(depth: depth)
            let anotherComponentValue = another.getComponent(depth: depth)

            if selfComponentValue != anotherComponentValue {
                result = Diff.init(depth: depth, order: (selfComponentValue > anotherComponentValue ? .orderedAscending : .orderedDescending))
                break
            }
        }

        return result ?? Diff.init(depth: .build, order: .orderedSame)
    }

    func getComponent(depth: Version.Depth) -> UInt {
        let depthValue = depth.rawValue
        return components.count > depthValue ? components[depthValue] : 0
    }

    func toString() -> String {
        let stringComponents = components.map { return "\($0)" }
        return stringComponents.joined(separator: ".")
    }
}
