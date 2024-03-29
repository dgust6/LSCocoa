import Foundation
import Combine
import LSData

public class NetworkEndpointDataStorage<NetworkEndpoint: Endpoint>: DataStorage {
    
    public typealias StoredItem = NetworkEndpoint.Parametrers
    public typealias StorageReturn = AnyPublisher<NetworkResponse, URLError>

    public let endpoint: NetworkEndpoint
    private let dataSource: any DataSource<NetworkResponse, URLRequest, URLError>

    public init(endpoint: NetworkEndpoint, dataSource: any DataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func store(_ item: StoredItem) -> AnyPublisher<NetworkResponse, URLError> {
        dataSource.publisher(parameter: endpoint.buildRequest(with: item))
    }
}
