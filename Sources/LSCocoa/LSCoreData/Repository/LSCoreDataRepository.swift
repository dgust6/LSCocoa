import Foundation
import Combine
import CoreData
import LSData

public enum RepositoryError: Error {
    case contextSaveFailed
}

public class LSCoreDataRepository<ManagedObject>: DataRepository where ManagedObject: LSManagedObject {
    
    public typealias StoredItem = [ManagedObject.AppModel]
    public typealias Parameter = [LSValuedAttribute<Any, ManagedObject>]

    private let stack: LSCoreDataStack
    
    public init(stack: LSCoreDataStack) {
        self.stack = stack
    }
    
    public func delete(_ item: StoredItem) -> AnyPublisher<Void, Error> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.delete(item)
        }
    }
    
    public func deleteAll() -> AnyPublisher<Void, Error> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.deleteAll(type: ManagedObject.self)
        }
    }
    
    public func publisher(parameter: Parameter? = nil) -> AnyPublisher<StoredItem, Error> {
        let parameters = parameter ?? []
        let query = parameters.map { "\($0.attribute.key) == %@" }.joined(separator: " AND ")
        let cvars = parameters.compactMap { $0.value as? CVarArg }
        let predicate = parameters.isEmpty ? nil : NSPredicate(format: query, cvars)
        return stack.mainContext.publishedItems(for: predicate, ofType: ManagedObject.self)
            .map { $0.compactMap { $0.toModel() } }
            .eraseToAnyPublisher()
    }
        
    public func insert(_ item: StoredItem) -> AnyPublisher<Void, StorageError> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.insert(item)
        }
    }
    
    public func overwriteAll(_ item: StoredItem) -> AnyPublisher<Void, StorageError> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.overwriteAll(item)
        }
    }
    
    public func upsert(_ item: StoredItem) -> AnyPublisher<Void, StorageError> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.upsert(item)
        }
    }
    
    public func update(_ item: StoredItem) -> AnyPublisher<Void, StorageError> {
        backgroundPerform { [weak self] in
            self?.stack.backgroundContext.update(item)
        }
    }
    
    private func backgroundPerform(instructions: @escaping () -> ()) -> AnyPublisher<Void, Error> {
            Deferred {
                Future { [weak self] promise in
                    self?.stack.backgroundContext.perform {
                        instructions()
                        do {
                            try self?.stack.backgroundContext.save()
                        } catch {
                            promise(.failure(RepositoryError.contextSaveFailed))
                        }
                        promise(.success(()))
                    }
                 }
            }
            .eraseToAnyPublisher()
    }
    
    private func backgroundPerform(instructions: @escaping () -> ()) {
        stack.backgroundContext.perform { [weak self] in
            instructions()
            try? self?.stack.backgroundContext.save()
        }
        return
    }
}
