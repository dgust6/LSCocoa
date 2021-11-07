import Foundation
import LSData
import Combine

public class LSUserDefaultsItemRepository<T: Codable>: NSObject, DataBasicRepository {
        
    public typealias Output = T?
    public typealias StoredItem = T?
    public typealias StorageError = Never
    public typealias OutputError = Never
    
    let itemKey: String
    let type = T.self
    
    private let userDefaults: UserDefaults
    private let subject: CurrentValueSubject<T?, Never>
    
    public init(itemKey: String = String(describing: T.self), userDefaults: UserDefaults = UserDefaults.standard) {
        self.itemKey = itemKey
        self.userDefaults = userDefaults
        subject = CurrentValueSubject<T?, Never>(userDefaults.value(forKey: itemKey) as? T)
        super.init()
        userDefaults.addObserver(self, forKeyPath: itemKey, options: [.new], context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == self.itemKey else {
            return
        }
        guard let data = object as? Data else {
            subject.send(nil)
            return
        }
        let decodedItem = try? JSONDecoder().decode(T.self, from: data)
        subject.send(decodedItem)
    }
    
    @discardableResult
    public func store(_ item: T?) -> AnyPublisher<(), Never> {
        let value = try? JSONEncoder().encode(item)
        userDefaults.set(value, forKey: itemKey)
        return Just(()).eraseToAnyPublisher()
    }
    
    public func publisher(parameter: ()?) -> AnyPublisher<T?, Never> {
        subject.eraseToAnyPublisher()
    }
}
