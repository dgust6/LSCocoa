import Foundation

public protocol ManagedObjectConvertible {
    var id: String { get }

    associatedtype ManagedObject: ManagedObjectModel where ManagedObject.AppModel == Self
}
