import Foundation

public struct NetworkResponse {
    
    public let data: Data
    public let urlResponse: URLResponse
    
    public var httpUrlResponse: HTTPURLResponse? {
        urlResponse as? HTTPURLResponse
    }
    
    public init(data: Data, urlResponse: URLResponse) {
        self.data = data
        self.urlResponse = urlResponse
    }
}
