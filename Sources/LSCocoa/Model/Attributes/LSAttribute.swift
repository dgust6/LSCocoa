import Foundation

protocol Attribute {
    var key: String { get }
}

public struct LSAttribute<Type, Owner>: Attribute {
    public let key: String
    
    public init(key: String) {
        self.key = key
    }
}

extension LSAttribute {
    
    func asAnyAttribute() -> AnyAttribute<Owner> {
        AnyAttribute<Owner>(key: key)
    }
}

public typealias AnyAttribute<Owner> = LSAttribute<Any?, Owner>
