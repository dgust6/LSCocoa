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
    
    public func publisher(parameter: URLRequest?) -> AnyPublisher<Data, LSNetworkError> {
        guard let request = parameter else {
            return Just(Data())
                .tryMap { _ in
                    throw LSNetworkError.badRequest
                }
                .mapError { error -> LSNetworkError in
                    .badRequest
                }
                .eraseToAnyPublisher()
        }
        
        return session
            .dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else { throw LSNetworkError.notHttpResponse }
                switch httpResponse.statusCode {
                case 200...300:
                    return data
                default:
                    throw LSNetworkError.unknown(statusCode: httpResponse.statusCode)
                }
            }
            .mapError { error -> LSNetworkError in
                if let error = error as? URLSession.DataTaskPublisher.Failure {
                    return .urlError(error: error)
                }
                return LSNetworkError.appSpecific(error: error)
            }
            .eraseToAnyPublisher()
    }
}
