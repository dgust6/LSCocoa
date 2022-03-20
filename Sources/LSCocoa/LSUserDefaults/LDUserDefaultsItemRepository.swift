import Foundation
import LSData
import Combine

public class LSUserDefaultsItemRepository<T: Codable>: NSObject, DataBasicRepository, DeletableStorage {
        
    public typealias Output = T?
    public typealias StoredItem = T?
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
    
    public var currentlySavedItem: T? {
        subject.value
    }
    
    public func store(_ item: T?) -> Void {
        let value = try? JSONEncoder().encode(item)
        userDefaults.set(value, forKey: itemKey)
    }
    
    public func delete(_ item: T?) -> () {
        userDefaults.set(nil, forKey: itemKey)
    }
    
    public func deleteAll() -> () {
        userDefaults.set(nil, forKey: itemKey)
    }
    
    public func publisher(parameter: ()?) -> AnyPublisher<T?, Never> {
        subject.eraseToAnyPublisher()
    }
}
