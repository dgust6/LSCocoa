import LSData
import Foundation
import Combine

public class TokenRefreshNetworkDataSource: DataSource {

    public typealias Output = NetworkResponse
    public typealias Parameter = URLRequest
    public typealias OutputError = TokenRefreshError
    
    private let networkDataSource: AnyDataSource<NetworkResponse, URLRequest, URLError>
    private let tokenRefreshService: OAuthTokenRefreshService
    
    public init(networkDataSource: AnyDataSource<NetworkResponse, URLRequest, URLError>, tokenRefreshService: OAuthTokenRefreshService) {
        self.networkDataSource = networkDataSource
        self.tokenRefreshService = tokenRefreshService
    }
    
    public func publisher(parameter: URLRequest) -> AnyPublisher<NetworkResponse, TokenRefreshError> {
        networkDataSource
            .publisher(parameter: parameter)
            .mapError { error in
                return TokenRefreshError.urlError(error)
            }
            .map { [weak self] response in
                guard
                    let self = self,
                    let httpResponse = response.httpUrlResponse,
                    httpResponse.statusCode == 401
                else {
                    return Just(response)
                        .setFailureType(to: TokenRefreshError.self)
                        .eraseToAnyPublisher()
                }
                return self.tokenRefreshService.refreshAccessToken()
                    .compactMap { [weak self] in
                        self?.networkDataSource.publisher(parameter: parameter)
                            .mapError { error in
                                return TokenRefreshError.urlError(error)
                            }
                    }
                    .switchToLatest()
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }
}
