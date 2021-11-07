import Foundation

protocol ValuedAttribute {
    associatedtype ValueType
    
    var key: String { get }
    var value: ValueType { get }
}

public struct LSValuedAttribute<Type, Owner>: ValuedAttribute {
    
    typealias ValueType = Type
    
    public let attribute: LSAttribute<Type, Owner>
    public let value: Type
    
    public var key: String {
        attribute.key
    }
    
    public init(attribute: LSAttribute<Type, Owner>, value: Type) {
        self.attribute = attribute
        self.value = value
    }
}

extension LSValuedAttribute {
    func asAnyValuedAttribute() -> AnyValuedAttribute<Owner> {
        AnyValuedAttribute<Owner>(attribute: attribute.asAnyAttribute(), value: value as Any?)
    }
}

extension LSValuedAttribute: Equatable where Type: Equatable {
    public static func == (lhs: LSValuedAttribute<Type, Owner>, rhs: LSValuedAttribute<Type, Owner>) -> Bool {
        lhs.value == rhs.value && lhs.attribute.key == rhs.attribute.key
    }
}

public typealias AnyValuedAttribute<Owner> = LSValuedAttribute<Any?, Owner>
