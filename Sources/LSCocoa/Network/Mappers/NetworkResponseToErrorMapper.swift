import Combine
import Foundation
import LSData

public class NetworkResponseToErrorMapper<DS: DataSource>: DataSource where DS.Output == NetworkResponse, DS.OutputError == URLError {
    
    public typealias Output = Data
    public typealias OutputError = NetworkError
    
    private let modifiedDataSource: any DataSource<Data, DS.Parameter, NetworkError>
    
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
                        return NetworkError.urlError(urlError)
                    } else if let responseError = error as? NetworkResponseError {
                        return NetworkError.responseError(responseError)
                    } else if let networkError = error as? NetworkError {
                        return networkError
                    } else {
                        return NetworkError.unknown
                    }
                }
                .eraseToAnyPublisher()
        }
    }
    
    public func publisher(parameter: DS.Parameter) -> AnyPublisher<Data, NetworkError> {
        modifiedDataSource.publisher(parameter: parameter)
    }
}

public extension DataSource where Self.Output == NetworkResponse, Self.OutputError == URLError {
    func networkResponseMap() -> some DataSource<Data, Self.Parameter, NetworkError> {
        NetworkResponseToErrorMapper(dataSource: self)
    }
}
