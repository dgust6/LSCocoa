import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    func publishedItems<T: ManagedObjectModel>(with ids: [String], ofType: T.Type = T.self) -> AnyPublisher<[T], Never> {
        return publishedItems(for: NSPredicate(format: "\(T.identityName) IN %@", ids))
            .assertNoFailure()
            .eraseToAnyPublisher()
    }
    
    func publishedAllItems<T: ManagedObjectModel>(ofType: T.Type = T.self) -> AnyPublisher<[T], Never> {
        return publishedItems(for: nil)
            .assertNoFailure()
            .eraseToAnyPublisher()
    }
    
    func publishedItem<T: ManagedObjectModel>(with id: String, ofType: T.Type = T.self) -> AnyPublisher<T?, Never> {
        return publishedItems(for: NSPredicate(format: "\(T.identityName) == %@", id))
            .assertNoFailure()
            .map { $0.first }
            .eraseToAnyPublisher()
    }
    
    func publishedItems<T: ManagedObjectModel>(for predicate: NSPredicate?, ofType: T.Type = T.self, saveContext: NSManagedObjectContext? = nil) -> AnyPublisher<[T], Error> {
        let fetchRequest = NSFetchRequest<T.ManagedObject>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: T.identityName, ascending: true)]
        return changesPublisher(for: fetchRequest, saveContext: saveContext).eraseToAnyPublisher()
    }
}
