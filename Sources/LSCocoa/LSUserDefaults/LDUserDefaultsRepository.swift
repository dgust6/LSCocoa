import Foundation
import LSData
import Combine

class LSUserDefaultsRepository {
    
    private let userDefaults: UserDefaults
    private var repositoryMap = [String: Any]()
    
    init(userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }
    
    public func store<T: Encodable>(_ item: T?, for key: String = String(describing: T.self)) {
        let encoder = JSONEncoder()
        let value = try? encoder.encode(item)
        let repository = fetchCreateIfNeeded(for: key)
        _ = repository.store(value)
    }
    
    public func publisher<T: Decodable>(for key: String = String(describing: T.self), ofType: T.Type = T.self) -> AnyPublisher<T?, Never> {
        fetchCreateIfNeeded(for: key).publisher()
            .map {
                guard let data = $0 else { return nil }
                let decoder = JSONDecoder()
                return try? decoder.decode(T.self, from: data)
            }
            .eraseToAnyPublisher()
    }
    
    private func fetchCreateIfNeeded(for key: String) -> LSUserDefaultsItemRepository<Data> {
        if let repository = repositoryMap[key] as? LSUserDefaultsItemRepository<Data> {
            return repository
        } else {
            let repository = LSUserDefaultsItemRepository<Data>(itemKey: key, userDefaults: userDefaults)
            return repository
        }
    }
}
