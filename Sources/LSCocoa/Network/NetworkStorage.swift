import Foundation
import Combine
import LSData

public class APINetworkStorage<Endpoint: ApiEndpoint>: DataStorage {
    
    public typealias StoredItem = Endpoint.Parametrers
    public typealias StorageReturn = AnyPublisher<Data, NetworkError>

    public var endpoint: Endpoint

    private let dataSource: AnyDataSource<Data, URLRequest, NetworkError>

    public init(endpoint: Endpoint, dataSource: AnyDataSource<Data, URLRequest, NetworkError> = NetworkDataSource.shared.erase()) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func store(_ item: StoredItem) -> AnyPublisher<Data, NetworkError> {
        dataSource.publisher(parameter: endpoint.buildRequest(with: item))
    }
}
