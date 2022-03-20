import Foundation
import CoreData

public protocol LSManagedObject {
            
    associatedtype ManagedObject: NSManagedObject where ManagedObject == Self
    associatedtype AppModel: LSManagedObjectConvertible where AppModel.ManagedObject == Self
    
    static var entityName: String { get }
    
    static var identityName: String { get }
        
    var id: String { get }
        
    func populate(with model: AppModel, in context: NSManagedObjectContext?)
    
    func toModel() -> AppModel
    
    static func createOrFetchEntity(with model: AppModel, in context: NSManagedObjectContext) -> ManagedObject
    
    static func fetchPredicate(for model: AppModel) -> NSPredicate
}

extension LSManagedObject {
    static var entityName: String {
        ManagedObject.entity().name ?? String(describing: self)
    }
    
    static var identityName: String {
        "id"
    }
}

extension LSManagedObject {
    init(model: AppModel, in context: NSManagedObjectContext) {
        self.init(context: context)
        populate(with: model, in: context)
    }
    
    static func createOrFetchEntity(with model: AppModel, in context: NSManagedObjectContext) -> ManagedObject {
        let result: Result<[ManagedObject], Error> = context.fetch(with: ManagedObject.fetchPredicate(for: model))
        switch result {
        case .success(let objects):
            if let object = objects.first {
                return object
            } else {
                return ManagedObject(model: model, in: context)
            }
        case .failure(_):
            return ManagedObject(model: model, in: context)
        }
    }
    
    static func fetchPredicate(for model: AppModel) -> NSPredicate {
        NSPredicate(format: "\(ManagedObject.identityName) == %@", model.id)
    }
}

extension NSSet {
    func toArray<T: LSManagedObjectConvertible>(of type: T.Type) -> [T] {
        (allObjects as? [T.ManagedObject])?.map { $0.toModel() } ?? []
    }
}

extension Array where Element: LSManagedObjectConvertible {
    func toManagedSet(in context: NSManagedObjectContext) -> NSSet {
        NSSet(array: self.map { Element.ManagedObject(model: $0, in: context) })
    }
}
