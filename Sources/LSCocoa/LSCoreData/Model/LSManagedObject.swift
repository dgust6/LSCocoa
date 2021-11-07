import Foundation
import CoreData

public protocol LSManagedObject {
            
    associatedtype T: NSManagedObject where T == Self
    associatedtype AppModel: LSManagedObjectConvertible where AppModel.ManagedObject == Self
    
    static var entityName: String { get }
    
    static var identityName: String { get }
        
    var id: String { get }
    
    func create(from model: AppModel) -> T
    
    func populate(with model: AppModel, in context: NSManagedObjectContext?)
    
    func toModel() -> AppModel?
}
