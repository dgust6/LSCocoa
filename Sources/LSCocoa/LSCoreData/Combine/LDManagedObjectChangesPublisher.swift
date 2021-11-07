import Foundation
import CoreData
import Combine

public extension NSManagedObjectContext {
    func changesPublisher<Object: NSManagedObject>(for fetchRequest: NSFetchRequest<Object>)
        -> LSManagedObjectChangesPublisher<Object>
    {
        LSManagedObjectChangesPublisher(fetchRequest: fetchRequest, context: self)
    }
}

public struct LSManagedObjectChangesPublisher<Object: NSManagedObject>: Publisher {
    public typealias Output = [Object]
    public typealias Failure = Error

    public let fetchRequest: NSFetchRequest<Object>
    public let context: NSManagedObjectContext

    public init(fetchRequest: NSFetchRequest<Object>, context: NSManagedObjectContext) {
        self.fetchRequest = fetchRequest
        self.context = context
    }

    public func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        let inner = Inner(downstream: subscriber, fetchRequest: fetchRequest, context: context)
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
            context: NSManagedObjectContext
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

        override var description: String {
            "ManagedObjectChanges(\(Object.self))"
        }
    }
}
