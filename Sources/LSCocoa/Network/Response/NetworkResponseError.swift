import Foundation

public struct NetworkResponseError: Error {
    
    public enum ResponseCodeError: Error {
        case badRequest
        case unauthorized
        case forbidden
        case notFound
        case internalServerError
        case unknown
    }
    
    public let responseCode: Int
    public let data: Data
    public let allHeaderFields: [AnyHashable : Any]
    
    public var responseCodeError: ResponseCodeError {
        switch responseCode {
        case 400:
            return ResponseCodeError.badRequest
        case 401:
            return ResponseCodeError.unauthorized
        case 403:
            return ResponseCodeError.forbidden
        case 404:
            return ResponseCodeError.notFound
        case 500:
            return ResponseCodeError.internalServerError
        default:
            return ResponseCodeError.unknown
        }
    }
}
