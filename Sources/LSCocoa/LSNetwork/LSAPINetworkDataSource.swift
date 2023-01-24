import Foundation
import Combine
import LSData

public class LSAPINetworkDataSource: DataSource {
        
    public typealias Output = Data
    public typealias Parameter = [LSApiEndpointAttribute]
    public typealias OutputError = LSNetworkError
    
    public let endpoint: ApiEndpoint
    public var parameters: [LSApiEndpointAttribute]
    
    private let dataSource: LSAnyDataSource<Data, URLRequest, LSNetworkError>
    
    public init(endpoint: ApiEndpoint, dataSource: LSAnyDataSource<Data, URLRequest, LSNetworkError> = LSNetworkDataSource.shared.erase(), parameters: [LSApiEndpointAttribute] = []) {
        self.endpoint = endpoint
        self.parameters = parameters
        self.dataSource = dataSource
    }
    
    public func publisher(parameter: Parameter) -> AnyPublisher<Data, LSNetworkError> {
        var queryingParameters = parameters
        queryingParameters.append(contentsOf: parameter)
        return dataSource.publisher(parameter: endpoint.buildRequest(with: queryingParameters))
    }
}
