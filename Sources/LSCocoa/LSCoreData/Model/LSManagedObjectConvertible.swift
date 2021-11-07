import Foundation

public protocol LSManagedObjectConvertible {
    var id: String { get }

    associatedtype ManagedObject: LSManagedObject where ManagedObject.AppModel == Self
}
