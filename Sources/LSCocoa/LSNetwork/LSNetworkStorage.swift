import Foundation
import Combine
import LSData

public class LSAPINetworkStorage: DataStorage {
    
    public typealias StoredItem = [LSApiEndpointAttribute]
    public typealias StorageError = LSNetworkError

    public var endpoint: ApiEndpoint

    private let dataSource: LSAnyDataSource<Data, URLRequest, LSNetworkError>

    public init(endpoint: ApiEndpoint, dataSource: LSAnyDataSource<Data, URLRequest, LSNetworkError> = LSNetworkDataSource.shared.erase()) {
        self.endpoint = endpoint
        self.dataSource = dataSource
    }
    
    public func store(_ item: StoredItem) -> AnyPublisher<Data, StorageError> {
        dataSource.publisher(parameter: endpoint.buildRequest(with: item))

    }
}
