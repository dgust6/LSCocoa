import Combine
import Foundation
import LSData

public class NetworkResponseToErrorMapper<DS: DataSource>: DataSource where DS.Output == NetworkResponse {
    
    public typealias Output = Data
    public typealias OutputError = NetworkError
    
    private let modifiedDataSource: AnyDataSource<Data, DS.Parameter, NetworkError>
    
    public init(dataSource: DS) {
        modifiedDataSource = dataSource.modifyPublisher { publisher in
            publisher
                .tryMap { response in
                    if let httpResponse = response.httpUrlResponse {
                        switch httpResponse.statusCode {
                        case 200...299:
                            return response.data
                        default:
                            throw NetworkResponseError(responseCode: httpResponse.statusCode, data: response.data, allHeaderFields: httpResponse.allHeaderFields)
                        }
                    } else {
                        throw NetworkError.noHttpResponse
                    }
                }
                .mapError { error in
                    if let urlError = error as? URLError {
                        return .urlError(urlError)
                    } else if let responseError = error as? NetworkResponseError {
                        return .responseError(responseError)
                    } else if let networkError = error as? NetworkError {
                        return networkError
                    } else {
                        return .unknown
                    }
                }
                .eraseToAnyPublisher()
        }
        .erase()
    }
    
    public func publisher(parameter: DS.Parameter) -> AnyPublisher<Data, NetworkError> {
        modifiedDataSource.publisher(parameter: parameter)
    }
}
