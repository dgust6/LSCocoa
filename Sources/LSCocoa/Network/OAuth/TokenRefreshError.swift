import Foundation

public enum TokenRefreshError: Error {
    case noRefreshToken
    case tokenExpired
    case urlError(URLError)
}
