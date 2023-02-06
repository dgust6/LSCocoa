//
//  OAuthTokenRefresh.swift
//  
//
//  Created by Dino Gustin on 28.01.2023..
//

import LSData
import Foundation
import Combine

public protocol TokenRefreshResponse {
    var refreshToken: String? { get }
    var accessToken: String { get }
}

public enum TokenRefreshError: Error {
    case noRefreshToken
    case networkError(NetworkError)
}

public class OAuthTokenRefreshService {
    
    let refreshEndpointDataSource: AnyDataSource<TokenRefreshResponse, String, NetworkError>
    let accessTokenStorage: KeychainItemRepository<String>
    let refreshTokenStorage: KeychainItemRepository<String>
    let networkDataSource: AnyDataSource<Data, URLRequest, NetworkError>
    var cancelBag = Set<AnyCancellable>()
    
    public init(
        refreshEndpointDataSource: AnyDataSource<TokenRefreshResponse, String, NetworkError>,
        accessTokenStorage: KeychainItemRepository<String>,
        refreshTokenStorage: KeychainItemRepository<String>,
        networkDataSource: AnyDataSource<Data, URLRequest, NetworkError> = NetworkDataSource.shared.erase()
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
                .networkError(error)
            }
            .eraseToAnyPublisher()
    }
}

public class TokenRefreshNetworkDataSource: DataSource {
    
    public typealias Output = Data
    public typealias Parameter = URLRequest
    public typealias OutputError = TokenRefreshError
    
    private let networkDataSource: AnyDataSource<Data, URLRequest, NetworkError>
    private let tokenRefreshService: OAuthTokenRefreshService
    
    public init(networkDataSource: AnyDataSource<Data, URLRequest, NetworkError>, tokenRefreshService: OAuthTokenRefreshService) {
        self.networkDataSource = networkDataSource
        self.tokenRefreshService = tokenRefreshService
    }
    
    public func publisher(parameter: URLRequest) -> AnyPublisher<Data, TokenRefreshError> {
        networkDataSource.publisher(parameter: parameter)
            .catch({ [weak self] error -> AnyPublisher<Data, TokenRefreshError> in
                guard let self = self else {
                    return Fail<Data, TokenRefreshError>(error: .networkError(error)).eraseToAnyPublisher()
                }
                switch error {
                case .unauthorized:
                    return self.refreshTokenAndRepeatRequest(urlRequest: parameter)
                default:
                    return Fail<Data, TokenRefreshError>(error: .networkError(error)).eraseToAnyPublisher()

                }
            })
            .eraseToAnyPublisher()
    }
    
    private func refreshTokenAndRepeatRequest(urlRequest: URLRequest) -> AnyPublisher<Data, TokenRefreshError> {
        tokenRefreshService.refreshAccessToken()
            .flatMap { [weak self] _ in
                guard let self = self else {
                    return Fail<Data, TokenRefreshError>(error: .noRefreshToken).eraseToAnyPublisher()
                }
                return self.networkDataSource.publisher(parameter: urlRequest)
                    .mapError { TokenRefreshError.networkError($0) }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
