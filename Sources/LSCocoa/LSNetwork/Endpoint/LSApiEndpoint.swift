import Foundation
import LSData

public protocol ApiEndpoint {
    
    var method: LSHttpMethod { get }
    var baseUrl: URL { get }
    var path: String? { get }
    var body: Codable? { get }
    var urlParameters: [String: String]? { get }
    var headers: [String: String]? { get }
    
    func buildRequest(with attributes: [LSApiEndpointAttribute]) -> URLRequest
}

extension ApiEndpoint {
    public var method: LSHttpMethod { .GET }
    public var path: String? { nil }
    public var body: Codable? { nil }
    public var urlParameters: [String: String]? { nil }
    public var headers: [String: String]? { nil }
}

extension ApiEndpoint {
    public func createDataSource() -> LSAPINetworkDataSource {
        LSAPINetworkDataSource(endpoint: self)
    }
}

extension ApiEndpoint {
    public func buildRequest(with attributes: [LSApiEndpointAttribute] = []) -> URLRequest {
        
        var body = self.body
        var urlParameters  = self.urlParameters ?? [String: String]()
        var headers = self.headers ?? [String: String]()
        var method = self.method
        var path = self.path ?? ""
        
        for attribute in attributes {
            switch attribute {
            case .addBody(let newBody):
                body = newBody
            case .addHeader(let field, let value):
                headers[field] = value
            case .addUrlParameter(let key, let value):
                urlParameters[key] = value
            case .changeHttpMethod(let newMethod):
                method = newMethod
            case .appendPath(let appeneded):
                path.append(contentsOf: appeneded)
            }
        }
        
        var request = URLRequest(url: baseUrl.appendingPathComponent(path))
        
        request.httpMethod = method.rawValue
        
        if let body = body {
            let jsonAsData = try? JSONSerialization.data(withJSONObject: body, options: .prettyPrinted)
            request.httpBody = jsonAsData
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            }
        }
        
        if let url = request.url, var urlComponents = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false), !urlParameters.isEmpty {
            
            urlComponents.queryItems = [URLQueryItem]()
            
            for (key,value) in urlParameters {
                let queryItem = URLQueryItem(name: key,
                                             value: "\(value)".addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))
                urlComponents.queryItems?.append(queryItem)
            }
            request.url = urlComponents.url
            
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
            }
        }
        
        for header in headers {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
            
        return request
    }
}
