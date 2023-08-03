import Foundation

public protocol TokenRefreshResponse {
    var refreshToken: String? { get }
    var accessToken: String { get }
}
