import Foundation
import CoreData

public extension NSManagedObjectContext {
    
    func fetch<T: LSManagedObject>(with predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]? = nil) -> Result<[T], Error> {
        let fetchRequest = NSFetchRequest<T>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors ?? [NSSortDescriptor(key: T.identityName, ascending: true)]
        do {
            let items = try self.fetch(fetchRequest)
            return .success(items)
        } catch let error {
            return .failure(error)
        }
    }
    
    func createEntity<T: LSManagedObject>(type: T.Type = T.self) -> T {
        let entity = T(context: self)
        return entity
    }
    
    func item<T: LSManagedObject>(by id: String, type: T.Type = T.self) -> Result<T?, Error> {
        return fetch(with: NSPredicate(format: "\(T.identityName) == %@", id)).map { $0.first }
    }

    func items<T: LSManagedObject>(with ids: [String], type: T.Type = T.self) -> Result<[T], Error> {
        return fetch(with: NSPredicate(format: "\(T.identityName) IN %@", ids))
    }
    
    func allItems<T: LSManagedObject>(type: T.Type = T.self) -> Result<[T], Error> {
        return fetch(with: nil)
    }
    
    @discardableResult
    func insert<T: LSManagedObjectConvertible>(_ item: T) -> Result<Void, Error> {
        let entity = createEntity(type: T.ManagedObject.self)
        entity.populate(with: item, in: self)
        return .success(())
    }
    
    @discardableResult
    func insert<T: LSManagedObjectConvertible>(_ items: [T]) -> Result<Void, Error> {
        for item in items {
            if case .failure(let error) = self.insert(item) {
                return .failure(error)
            }
        }
        return .success(())
    }
    
    @discardableResult
    func delete<T: LSManagedObject>(_ item: T) -> Result<Void, Error> {
        self.delete(item)
        return .success(())
    }
    
    @discardableResult
    func delete<T: LSManagedObject>(_ items: [T]) -> Result<Void, Error> {
        for item in items {
            self.delete(item)
        }
        return .success(())
    }
    
    @discardableResult
    func delete<T: LSManagedObjectConvertible>(_ item: T) -> Result<Void, Error> {
        self.item(by: item.id, type: T.ManagedObject.self).map { fetchedItem -> Void in
            guard let fetchedItem = fetchedItem else { return }
            self.delete([fetchedItem])
            return
        }
    }
    
    @discardableResult
    func delete<T: LSManagedObjectConvertible>(_ items: [T]) -> Result<Void, Error> {
        self.items(with: items.map { $0.id }, type: T.ManagedObject.self).map { fetchedItems -> Void in
            self.delete(fetchedItems)
            return
        }
    }
        
    //TODO: Replace with NSBatchDeleteRequest
    @discardableResult
    func deleteAll<T: LSManagedObject>(type: T.Type) -> Result<Void, Error> {
        allItems(type: type).map {
            for item in $0 {
                delete(item)
            }
            return
        }
    }
    
    // MARK: Update
    
    func pairs<T: LSManagedObjectConvertible>(_ items: [T], type: T.Type = T.self) -> Result<[(T, T.ManagedObject?)], Error> {
        self.items(with: items.map { $0.id }, type: T.ManagedObject.self).map { fetchedItems in
            var fetchedItemDict = [String: T.ManagedObject]()
            for fetchedItem in fetchedItems {
                fetchedItemDict[fetchedItem.id] = fetchedItem
            }
            return items.map { ($0, fetchedItemDict[$0.id]) }
        }
    }
    
    @discardableResult
    func update<T: LSManagedObjectConvertible>(_ items: [T]) -> Result<Void, Error> {
        self.pairs(items, type: T.self).map { pairs in
            for (item, managedItem) in pairs {
                managedItem?.populate(with: item, in: self)
            }
        }
    }
    
    @discardableResult
    func upsert<T: LSManagedObjectConvertible>(_ items: [T]) -> Result<Void, Error> {
        self.pairs(items, type: T.self).map { pairs in
            for (item, managedItem) in pairs {
                if let managedItem = managedItem {
                    managedItem.populate(with: item, in: self)
                } else {
                    self.insert(item)
                }
            }
        }
    }
    
    @discardableResult
    func overwriteAll<T: LSManagedObjectConvertible>(_ items: [T]) -> Result<Void, Error> {
        self.deleteAll(type: T.ManagedObject.self)
            .map {
                self.insert(items)
                return
            }
    }
}
