import Foundation
import Combine
import LSData

public class NetworkEndpointDataSource<NetworkEndpoint: Endpoint>: DataSource {
        
    public typealias Output = NetworkResponse
    public typealias Parameter = NetworkEndpoint.Parametrers
    public typealias OutputError = URLError
    
    public let endpoint: NetworkEndpoint
    
    private let dataSource: AnyDataSource<NetworkResponse, URLRequest, URLError>
    
    public init(endpoint: NetworkEndpoint, dataSource: AnyDataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared.erase()) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func publisher(parameter: Parameter) -> AnyPublisher<NetworkResponse, URLError> {
        return dataSource.publisher(parameter: endpoint.buildRequest(with: parameter))
    }
}

extension Endpoint {
    public func createDataSource(with networkDataSource: AnyDataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared.erase()) -> NetworkEndpointDataSource<Self> {
        NetworkEndpointDataSource(endpoint: self)
    }
}

extension DecodableReturningEndpoint {
    public func createDataSource() -> AnyDataSource<ReturnDecodable?, Parametrers, URLError> {
        createDataSource()
            .outMap {
                $0.data
            }
            .jsonDecodeMap(to: ReturnDecodable.self)
            .erase()
    }
}
