import Foundation

protocol ValuedAttribute {
    associatedtype ValueType
    
    var key: String { get }
    var value: ValueType { get }
}

public struct OwnedValuedAttribute<T, Owner>: ValuedAttribute {
    
    typealias ValueType = T
    
    public let attribute: OwnedAttribute<T, Owner>
    public let value: T
    
    public var key: String {
        attribute.key
    }
    
    public init(attribute: OwnedAttribute<T, Owner>, value: T) {
        self.attribute = attribute
        self.value = value
    }
}

extension OwnedValuedAttribute {
    func asAnyValuedAttribute() -> AnyValuedAttribute<Owner> {
        AnyValuedAttribute<Owner>(attribute: attribute.asAnyAttribute(), value: value as Any?)
    }
}

extension OwnedValuedAttribute: Equatable where T: Equatable {
    public static func == (lhs: OwnedValuedAttribute<T, Owner>, rhs: OwnedValuedAttribute<T, Owner>) -> Bool {
        lhs.value == rhs.value && lhs.attribute.key == rhs.attribute.key
    }
}

public typealias AnyValuedAttribute<Owner> = OwnedValuedAttribute<Any?, Owner>
