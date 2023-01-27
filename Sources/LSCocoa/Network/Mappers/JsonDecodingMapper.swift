import Foundation
import LSData

public class JsonDecodingMapper<T: Decodable>: Mapper {
    
    public typealias Input = Data
    public typealias Output = T?
    
    public init() {}
    
    public func map(_ input: Data) -> T? {
        let decoder = JSONDecoder()
        return try? decoder.decode(T.self, from: input)
    }
}

extension DataSource where Output == Data {
    public func jsonDecodeMap<T: Decodable>(to type: T.Type) -> OutputMappingDataSource<Self, JsonDecodingMapper<T>> {
        outMap(with: JsonDecodingMapper<T>())
    }
}
