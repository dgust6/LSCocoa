import Foundation

public protocol Attributable {
    func value<T>(for attribute: OwnedAttribute<T, Self>) -> T
}
