import Foundation
import Combine
import LSData

public class APINetworkDataSource<Endpoint: ApiEndpoint>: DataSource {
        
    public typealias Output = Data
    public typealias Parameter = Endpoint.Parametrers
    public typealias OutputError = NetworkError
    
    public let endpoint: Endpoint
    
    private let dataSource: AnyDataSource<Data, URLRequest, NetworkError>
    
    public init(endpoint: Endpoint, dataSource: AnyDataSource<Data, URLRequest, NetworkError> = NetworkDataSource.shared.erase()) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func publisher(parameter: Parameter) -> AnyPublisher<Data, NetworkError> {
        return dataSource.publisher(parameter: endpoint.buildRequest(with: parameter))
    }
}

extension ApiEndpoint {
    public func createDataSource(with networkDataSource: AnyDataSource<Data, URLRequest, NetworkError> = NetworkDataSource.shared.erase()) -> APINetworkDataSource<Self> {
        APINetworkDataSource(endpoint: self)
    }
}
