import Foundation

public enum EndpointAttribute {
    case addHeader(field: String, value: String)
    case addBody(codable: Codable)
    case addUrlParameter(key: String, value: String)
    case changeHttpMethod(method: HttpMethod)
    case appendPath(string: String)
}
