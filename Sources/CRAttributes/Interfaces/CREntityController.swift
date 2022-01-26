//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 14/01/2022.
//

import Foundation
import CoreData
import Combine

@MainActor public class CREntityController {
    let context: NSManagedObjectContext

    private var observers: [AnyCancellable] = []
    
    /**
     it will instantly subscribe to the merge events
     */
    init(localContainerViewContext: NSManagedObjectContext) {
        self.context = localContainerViewContext

        //source: https://www.donnywals.com/observing-changes-to-managed-objects-across-contexts-with-combine/
//        observers.append(NotificationCenter.default
//            .publisher(for: NSManagedObjectContext.didMergeChangesObjectIDsNotification, object: localContainerViewContext)
//            .sink(receiveValue: { [weak self] notification in
//            guard let self = self else { return }
//            if let inserted_ids = notification.userInfo?[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID> {
//                self.handleContextDidMerge(ids: inserted_ids, context: self.context)
//            }
//        }))

        observers.append(NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didChangeObjectsNotification, object: localContainerViewContext)
            .sink(receiveValue: { [weak self] notification in
            guard let self = self else { return }
            if let inserted_objects = notification.userInfo?[NSInsertedObjectsKey] as? Set<NSManagedObject> {
                if inserted_objects.count > 0 {
                    self.handleContextDidChange(inserted_objects: inserted_objects)
                }
            }
        }))
    }

//    func handleContextDidMerge(ids: Set<NSManagedObjectID>, context: NSManagedObjectContext) {
//        assert(!Thread.isMainThread)
//        assert(context == context)
//        context.perform { // if we performAndWait then we can't save - it's relying on the merge save
//            for objectID in ids {
//                // TODO: (optimisation) group operations for the same crEntity
//                if let op = context.object(with: objectID) as? CDOperation {
//                    op.weakCREntity?.renderOperations([op])
//                    op.container?.weakCREntity?.renderOperations([op])
//                }
//            }
//        }
//    }
    /**
     this will be executed on both local and remote changes
     */
    func handleContextDidChange(inserted_objects: Set<NSManagedObject>) {
        assert(!Thread.isMainThread)
        context.perform { // if we performAndWait then we can't save - it's relying on the merge save
            for object in inserted_objects {
                // TODO: (optimisation) group operations for the same crEntity
                if let op = object as? CDOperation {
                    op.weakCREntity?.renderOperations([op]) // we trigger render only on pre-existing entities
                    if let container = op.container, op.type != .ghost {
                        container.weakCREntity?.renderOperations([op])
                    } else {
                        CRObject.virtualRootObject(objectType: op.objectType).renderOperations([op])
                    }
                }
            }
        }
    }
}
