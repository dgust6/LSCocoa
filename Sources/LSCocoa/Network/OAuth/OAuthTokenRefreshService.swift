import LSData
import Foundation
import Combine

public class OAuthTokenRefreshService {
    
    private let refreshEndpointDataSource: any DataSource<TokenRefreshResponse, String, URLError>
    private let accessTokenStorage: KeychainItemRepository<String>
    private let refreshTokenStorage: KeychainItemRepository<String>
    private let networkDataSource:  any DataSource<NetworkResponse, URLRequest, URLError>
    private var cancelBag = Set<AnyCancellable>()
    
    public init(
        refreshEndpointDataSource:  any DataSource<TokenRefreshResponse, String, URLError>,
        accessTokenStorage: KeychainItemRepository<String>,
        refreshTokenStorage: KeychainItemRepository<String>,
        networkDataSource:  any DataSource<NetworkResponse, URLRequest, URLError> = URLSession.shared
    ) {
        self.refreshEndpointDataSource = refreshEndpointDataSource
        self.accessTokenStorage = accessTokenStorage
        self.refreshTokenStorage = refreshTokenStorage
        self.networkDataSource = networkDataSource
    }
    
    public func refreshAccessToken() -> AnyPublisher<Void, TokenRefreshError> {
        guard let refreshToken = refreshTokenStorage.storedItem else {
            return Fail<Void, TokenRefreshError>(error: TokenRefreshError.noRefreshToken).eraseToAnyPublisher()
        }
        return refreshEndpointDataSource.publisher(parameter: refreshToken)
            .map { [weak self] response in
                self?.accessTokenStorage.store(response.accessToken)
                if let refreshToken = response.refreshToken {
                    self?.refreshTokenStorage.store(refreshToken)
                }
                return ()
            }
            .mapError { error in
                .urlError(error)
            }
            .eraseToAnyPublisher()
    }
}
