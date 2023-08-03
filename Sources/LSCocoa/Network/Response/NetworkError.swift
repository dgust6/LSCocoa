import Foundation

public enum NetworkError: Error {
    case urlError(URLError)
    case responseError(NetworkResponseError)
    case noHttpResponse
    case unknown
}
