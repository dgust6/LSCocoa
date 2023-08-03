import Foundation
import LSData
import Combine

public class UserDefaultsArrayRepository<T: Codable & Identifiable>: NSObject, DataRepository {

    public typealias Output = [T]
    public typealias StoredItem = [T]
    public typealias DeletableItem = [T]
    public typealias OutputError = Never
    
    let itemKey: String
    let type = T.self
    
    private let userDefaults: UserDefaults
    private let subject: CurrentValueSubject<[T], Never>
    
    public init(itemKey: String = String(describing: T.self), userDefaults: UserDefaults = UserDefaults.standard) {
        self.itemKey = itemKey
        self.userDefaults = userDefaults
        subject = CurrentValueSubject<[T], Never>(userDefaults.value(forKey: itemKey) as? [T] ?? [])
        super.init()
        userDefaults.addObserver(self, forKeyPath: itemKey, options: [.new], context: nil)
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == self.itemKey else {
            return
        }
        guard let data = change?[NSKeyValueChangeKey.newKey] as? Data else {
            subject.send([])
            return
        }
        let decodedItem = try? JSONDecoder().decode([T].self, from: data)
        subject.send(decodedItem ?? [])
    }
    
    public var currentlySavedItem: [T] {
        subject.value
    }
    
    public func delete(_ item: [T]) -> () {
        userDefaults.set(nil, forKey: itemKey)
    }
    
    public func deleteAll() -> () {
        userDefaults.set(nil, forKey: itemKey)
    }
    
    public func publisher(parameter: ()) -> AnyPublisher<[T], Never> {
        subject.eraseToAnyPublisher()
    }
    
    public func insert(_ item: [T]) -> () {
        let newItems = currentlySavedItem + process(oldItems: currentlySavedItem, with: item).uniqueNew
        setNewItems(newItems)
    }
    
    public func overwriteAll(_ item: [T]) -> () {
        setNewItems(item)
    }
    
    public func upsert(_ item: [T]) -> () {
        let processResult = process(oldItems: currentlySavedItem, with: item)
        setNewItems(processResult.uniqueOld + processResult.shared + processResult.uniqueNew)
    }
    
    public func update(_ item: [T]) -> () {
        let processResult = process(oldItems: currentlySavedItem, with: item)
        setNewItems(processResult.uniqueOld + processResult.shared)
    }
    
    private func process(oldItems: [T], with newItems: [T]) -> (uniqueOld: [T], shared: [T], uniqueNew: [T]) {
        var shared = [T]()
        var uniqueNew = [T]()
        for newItem in newItems {
            if oldItems.contains(where: { $0.id == newItem.id }) {
                shared.append(newItem)
            } else {
                uniqueNew.append(newItem)
            }
        }
        let uniqueOld = oldItems.filter { oldItem in
            !shared.contains(where: { $0.id == oldItem.id })
        }
        return (uniqueOld, shared, uniqueNew)
    }
    
    private func setNewItems(_ items: [T]) {
        let value = try? JSONEncoder().encode(items)
        userDefaults.set(value, forKey: itemKey)
    }
}
