import Foundation

protocol Attribute {
    var key: String { get }
}

public struct OwnedAttribute<T, Owner>: Attribute {
    public let key: String
    
    public init(key: String) {
        self.key = key
    }
}

extension OwnedAttribute {
    func asAnyAttribute() -> AnyAttribute<Owner> {
        AnyAttribute<Owner>(key: key)
    }
}

public typealias AnyAttribute<Owner> = OwnedAttribute<Any?, Owner>
