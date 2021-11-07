import Foundation

public enum LSApiEndpointAttribute {
    case addHeader(field: String, value: String)
    case addBody(codable: Codable)
    case addUrlParameter(key: String, value: String)
    case changeHttpMethod(method: LSHttpMethod)
    case appendPath(string: String)
}
