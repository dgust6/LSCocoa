import Foundation
import Combine
import LSData

public class NetworkEndpointDataSource<NetworkEndpoint: Endpoint>: DataSource {
        
    public typealias Output = NetworkResponse
    public typealias Parameter = NetworkEndpoint.Parametrers
    public typealias OutputError = URLError
    
    public let endpoint: NetworkEndpoint
    
    private let dataSource: any DataSource<NetworkResponse, URLRequest, URLError>
    
    public init(endpoint: NetworkEndpoint, dataSource: any DataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func publisher(parameter: Parameter) -> AnyPublisher<NetworkResponse, URLError> {
        return dataSource.publisher(parameter: endpoint.buildRequest(with: parameter))
    }
}

extension Endpoint {
    public func createDataSource(with networkDataSource: any DataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared) -> some DataSource<Data, Parametrers, NetworkError> {
        let dataSource = NetworkEndpointDataSource(endpoint: self)
        return NetworkResponseToErrorMapper(dataSource: dataSource)
    }
}

extension DecodableReturningEndpoint {
    public func createDecodingDataSource() -> some DataSource<ReturnDecodable, Parametrers, ErrorUnion<NetworkError, DecodingError>> {
        let dataSource = NetworkEndpointDataSource(endpoint: self)
        return NetworkResponseToErrorMapper(dataSource: dataSource)
            .jsonDecodeMap(to: ReturnDecodable.self)
    }
}
