import Foundation

public enum NetworkError: Error {
    case badRequest
    case unauthorized
    case forbidden
    case notFound
    case internalServerError
    case notHttpResponse
    case urlError(error: URLSession.DataTaskPublisher.Failure)
    case unknown(statusCode: Int)
    case appSpecific(error: Error)
}
