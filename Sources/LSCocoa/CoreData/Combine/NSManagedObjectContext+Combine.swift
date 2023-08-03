import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    
    func publishedItems<T: ManagedObjectModel>(for predicate: NSPredicate?, ofType: T.Type = T.self, saveContext: NSManagedObjectContext? = nil) -> AnyPublisher<[T], Error> {
        let fetchRequest = NSFetchRequest<T.ManagedObject>(entityName: T.entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: T.identityName, ascending: true)]
        return changesPublisher(for: fetchRequest, saveContext: saveContext).eraseToAnyPublisher()
    }
}
