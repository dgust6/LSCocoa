import Foundation
import Combine
import CoreData
import LSData

public enum RepositoryError: Error {
    case contextSaveFailed
}

open class CoreDataRepository<ManagedObject>: DataRepository where ManagedObject: ManagedObjectModel {
    
    public typealias StoredItem = [ManagedObject.AppModel]
    public typealias Parameter = [LSValuedAttribute<Any?, ManagedObject>]
    public typealias DeletionReturn = Void

    public let stack: CoreDataStack
    private let reactOnChildUpdates: Bool //updates it's publishers whenever context is changed
    
    public init(stack: CoreDataStack, reactOnChildUpdates: Bool = true) {
        self.reactOnChildUpdates = reactOnChildUpdates
        self.stack = stack
    }
    
    public func delete(_ item: StoredItem) -> DeletionReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.delete(item)
        }
    }
    
    public func deleteAll() -> DeletionReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.deleteAll(type: ManagedObject.self)
        }
    }
    
    public func publisher(ids: [String]) -> AnyPublisher<StoredItem, Error> {
        let predicate = NSPredicate(format: "\(ManagedObject.identityName) IN %@", ids)
        return publisher(predicate: predicate)
    }
    
    public func publisher(predicate: NSPredicate?) -> AnyPublisher<StoredItem, Error> {
        return stack.mainContext.publishedItems(for: predicate, ofType: ManagedObject.self, saveContext: reactOnChildUpdates ? stack.backgroundContext : nil)
            .map { $0.compactMap { $0.toModel() } }
            .eraseToAnyPublisher()
    }
    
    public func publisher(parameter: Parameter = []) -> AnyPublisher<StoredItem, Error> {
        let predicate = predicate(from: parameter)
        return publisher(predicate: predicate)
    }
    
    public func fetch(parameter: Parameter) -> StoredItem {
        let predicate = predicate(from: parameter)
        let result: Result<[ManagedObject], Error> = stack.mainContext.fetch(with: predicate)
        switch result {
        case .success(let objects):
            return objects.map { $0.toModel() }
        case .failure(_):
            return []
        }
    }
    
    private func predicate(from parameter: Parameter) -> NSPredicate? {
        let query = parameter.map { "\($0.attribute.key) == %@" }.joined(separator: " AND ")
        let cvars = parameter.compactMap { $0.value as? CVarArg }
        let predicate = parameter.isEmpty ? nil : NSPredicate(format: query, cvars)
        return predicate
    }
        
    public func insert(_ item: StoredItem) -> StorageReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.insert(item)
        }
    }
    
    public func overwriteAll(_ item: StoredItem) -> StorageReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.overwriteAll(item)
        }
    }
    
    public func upsert(_ item: StoredItem) -> StorageReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.upsert(item)
        }
    }
    
    public func update(_ item: StoredItem) -> StorageReturn {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.update(item)
        }
    }
    
    public func insertPublisher(_ item: StoredItem) -> AnyPublisher<Void, Error> {
        backgroundPerformPublisher { [weak self] in
            self?.stack.backgroundContext.insert(item)
        }
    }
    
    public func overwriteAllPublisher(_ item: StoredItem) -> AnyPublisher<Void, Error> {
        backgroundPerformPublisher { [weak self] in
            self?.stack.backgroundContext.overwriteAll(item)
        }
    }
    
    public func upsertPublisher(_ item: StoredItem) -> AnyPublisher<Void, Error> {
        backgroundPerformPublisher { [weak self] in
            self?.stack.backgroundContext.upsert(item)
        }
    }
    
    public func updatePublisher(_ item: StoredItem) -> AnyPublisher<Void, Error> {
        backgroundPerformPublisher { [weak self] in
            self?.stack.backgroundContext.update(item)
        }
    }
    
    private func backgroundPerformPublisher(instructions: @escaping () -> Void) -> AnyPublisher<Void, Error> {
            Deferred {
                Future { [weak self] promise in
                    self?.stack.backgroundContext.perform { [weak self] in
                        instructions()
                        do {
                            if self?.stack.backgroundContext.hasChanges == true {
                                try self?.stack.backgroundContext.save()
                            }
                        } catch let error {
                            print(error)
                            print(error.localizedDescription)
                            promise(.failure(RepositoryError.contextSaveFailed))
                        }
                        promise(.success(()))
                    }
                 }
            }
            .eraseToAnyPublisher()
    }
    
    private func backgroundPerform(instructions: @escaping () -> Void) {
        stack.backgroundContext.perform { [weak self] in
            instructions()
            do {
                if self?.stack.backgroundContext.hasChanges == true {
                    try self?.stack.backgroundContext.save()
                }
            } catch let error {
                print(error)
                print(error.localizedDescription)
            }
        }
    }
}
