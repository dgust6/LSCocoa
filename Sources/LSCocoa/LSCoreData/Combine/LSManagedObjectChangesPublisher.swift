import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    func changesPublisher<Object: NSManagedObject>(for fetchRequest: NSFetchRequest<Object>, saveContext: NSManagedObjectContext? = nil)
        -> LSManagedObjectChangesPublisher<Object> {
        LSManagedObjectChangesPublisher(fetchRequest: fetchRequest, context: self, saveContext: saveContext)
    }
}

public struct LSManagedObjectChangesPublisher<Object: NSManagedObject>: Publisher {
    public typealias Output = [Object]
    public typealias Failure = Error

    public let fetchRequest: NSFetchRequest<Object>
    public let context: NSManagedObjectContext
    private let saveContext: NSManagedObjectContext?

    public init(fetchRequest: NSFetchRequest<Object>, context: NSManagedObjectContext, saveContext: NSManagedObjectContext?) {
        self.fetchRequest = fetchRequest
        self.context = context
        self.saveContext = saveContext
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let inner = Inner(downstream: subscriber, fetchRequest: fetchRequest, context: context, saveContext: saveContext)
        subscriber.receive(subscription: inner)
    }

    private final class Inner<Downstream: Subscriber>: NSObject, Subscription,
        NSFetchedResultsControllerDelegate
    where Downstream.Input == [Object], Downstream.Failure == Error {
        private let downstream: Downstream
        private var fetchedResultsController: NSFetchedResultsController<Object>?

        init(
            downstream: Downstream,
            fetchRequest: NSFetchRequest<Object>,
            context: NSManagedObjectContext,
            saveContext: NSManagedObjectContext?
        ) {
            self.downstream = downstream
            fetchedResultsController
                = NSFetchedResultsController(
                    fetchRequest: fetchRequest,
                    managedObjectContext: context,
                    sectionNameKeyPath: nil,
                    cacheName: nil)

            super.init()

            fetchedResultsController!.delegate = self
            
            if let saveContext = saveContext {
                NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleMainContextSaved),
                                               name: .NSManagedObjectContextDidSave,
                                               object: saveContext)
            }

            do {
                try fetchedResultsController!.performFetch()
                updateDiff()
            } catch {
                downstream.receive(completion: .failure(error))
            }
        }

        private var demand: Subscribers.Demand = .none

        func request(_ demand: Subscribers.Demand) {
            self.demand += demand
            fulfillDemand()
        }

        private var objects = [Object]()

        private func updateDiff() {
            objects = fetchedResultsController?.fetchedObjects ?? []
            fulfillDemand()
        }

        private func fulfillDemand() {
            if demand > 0 {
                let newDemand = downstream.receive(objects)

                demand += newDemand
                demand -= 1
            }
        }

        func cancel() {
            fetchedResultsController?.delegate = nil
            fetchedResultsController = nil
        }

        func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {
            updateDiff()
        }
        
        @objc private func handleMainContextSaved() {
            fetchedResultsController?.managedObjectContext.perform { [weak self] in
                self?.updateDiff()
            }
        }

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}
