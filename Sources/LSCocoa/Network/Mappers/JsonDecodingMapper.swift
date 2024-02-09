import Foundation
import LSData

public class JsonDecodingMapper<T: Decodable>: FailableMapper {
    
    public typealias Input = Data
    public typealias Output = T
    public typealias MappingError = DecodingError
    
    public init() {}
    
    public func map(_ input: Data) -> Result<Output, MappingError> {
        let decoder = JSONDecoder()
        do {
            let output = try decoder.decode(T.self, from: input)
            return .success(output)
        } catch (let error) {
            return .failure(error as! DecodingError)
        }
        
    }
}

extension DataSource where Output == Data {
    public func jsonDecodeMap<T: Decodable>(to type: T.Type) -> FailableOutputMappingDataSource<Self, JsonDecodingMapper<T>> {
        FailableOutputMappingDataSource(mapper: JsonDecodingMapper<T>(), dataSource: self)
    }
}
