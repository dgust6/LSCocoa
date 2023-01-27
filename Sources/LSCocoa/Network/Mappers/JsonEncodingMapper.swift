import Foundation
import LSData

public class JsonEncodingMapper<T: Encodable>: Mapper {

    public typealias Input = T
    public typealias Output = Data?
    
    public init() {}
    
    public func map(_ input: T) -> Data? {
        let encoder = JSONEncoder()
        return try? encoder.encode(input)
    }
}
