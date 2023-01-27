import Foundation
import Combine
import LSData

public class NetworkDataSource: DataSource {
    
    public static var shared = NetworkDataSource()
        
    public typealias Output = Data
    public typealias Parameter = URLRequest
    public typealias OutputError = NetworkError
    
    private let session: URLSession
    private let sessionConfiguration: URLSessionConfiguration
    
    public init(configuration: URLSessionConfiguration = URLSessionConfiguration.default) {
        self.sessionConfiguration = configuration
        self.sessionConfiguration.timeoutIntervalForRequest = 130
        self.session = URLSession(configuration: self.sessionConfiguration)
    }
    
    public func cancel(url: URL) {
        self.session.getAllTasks {
            $0.filter({ $0.originalRequest?.url == url }).forEach({
                $0.cancel()
            })
        }
    }
    
    public func cancelAll() {
        self.session.getAllTasks { $0.forEach({ $0.cancel() }) }
    }
    
    public func reset() {
        self.cancelAll()
        URLCache.shared.removeAllCachedResponses()
    }
    
    public func publisher(parameter: URLRequest) -> AnyPublisher<Data, NetworkError> {
        return session
            .dataTaskPublisher(for: parameter)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.notHttpResponse }
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 400:
                    throw NetworkError.badRequest
                case 401:
                    throw NetworkError.unauthorized
                case 403:
                    throw NetworkError.forbidden
                case 404:
                    throw NetworkError.notFound
                case 500:
                    throw NetworkError.internalServerError
                default:
                    throw NetworkError.unknown(statusCode: httpResponse.statusCode)
                }
            }
            .mapError { error -> NetworkError in
                if let error = error as? URLSession.DataTaskPublisher.Failure {
                    return .urlError(error: error)
                } else if let networkError = error as? NetworkError {
                    return networkError
                }
                return NetworkError.appSpecific(error: error)
            }
            .eraseToAnyPublisher()
    }
}
