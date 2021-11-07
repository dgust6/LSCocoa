import Foundation

public protocol Attributable {
    func value<T>(for attribute: LSAttribute<T, Self>) -> T
}
