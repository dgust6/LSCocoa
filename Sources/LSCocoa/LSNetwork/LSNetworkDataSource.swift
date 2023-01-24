import Foundation
import Combine
import LSData

public class LSNetworkDataSource: DataSource {
    
    public static var shared = LSNetworkDataSource()
        
    public typealias Output = Data
    public typealias Parameter = URLRequest
    public typealias OutputError = LSNetworkError
    
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
    
    public func publisher(parameter: URLRequest) -> AnyPublisher<Data, LSNetworkError> {
        return session
            .dataTaskPublisher(for: parameter)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else { throw LSNetworkError.notHttpResponse }
                switch httpResponse.statusCode {
                case 200...299:
                    return data
                case 400:
                    throw LSNetworkError.badRequest
                case 401:
                    throw LSNetworkError.unauthorized
                case 403:
                    throw LSNetworkError.forbidden
                case 404:
                    throw LSNetworkError.notFound
                case 500:
                    throw LSNetworkError.internalServerError
                default:
                    throw LSNetworkError.unknown(statusCode: httpResponse.statusCode)
                }
            }
            .mapError { error -> LSNetworkError in
                if let error = error as? URLSession.DataTaskPublisher.Failure {
                    return .urlError(error: error)
                } else if let networkError = error as? LSNetworkError {
                    return networkError
                }
                return LSNetworkError.appSpecific(error: error)
            }
            .eraseToAnyPublisher()
    }
}
