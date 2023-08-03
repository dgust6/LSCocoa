import Foundation
import Combine
import LSData

extension URLSession: DataSource {
    public func publisher(parameter: URLRequest) -> AnyPublisher<NetworkResponse, URLError> {
        dataTaskPublisher(for: parameter)
            .map { data, response in
                NetworkResponse(data: data, urlResponse: response)
            }
            .eraseToAnyPublisher()
    }
}


