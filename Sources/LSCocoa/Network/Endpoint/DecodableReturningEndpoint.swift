import LSData
import Foundation

public protocol DecodableReturningEndpoint: Endpoint {
    associatedtype ReturnDecodable: Decodable
}
