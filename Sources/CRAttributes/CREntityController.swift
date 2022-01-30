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

        
        //The notification is posted during processPendingChanges, after the changes have been processed, but before it is safe to call save
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
        
//        observers.append(NotificationCenter.default
//            .publisher(for: NSManagedObjectContext.didSaveObjectsNotification, object: localContainerViewContext)
//            .sink(receiveValue: { [weak self] notification in
//            guard let self = self else { return }
//            if let inserted_ids = notification.userInfo?[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID> {
//                print("viewContext.didSaveObjectsNotification")
//            }
//        }))
//
//        observers.append(NotificationCenter.default
//            .publisher(for: NSManagedObjectContext.didMergeChangesObjectIDsNotification, object: localContainerViewContext)
//            .sink(receiveValue: { [weak self] notification in
//            guard let self = self else { return }
//            if let inserted_ids = notification.userInfo?[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID> {
//                print("viewContext.didMergeChangesObjectIDsNotification")
//            }
//        }))

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
        assert(Thread.isMainThread)
        context.perform { // if we performAndWait then we can't save - it's relying on the merge save
            print("viewContext.handleContextDidChange")
            // we notify and render only on pre-existing entities

            for inserted_object in inserted_objects {
                // TODO: (optimisation) group operations for the same crEntity
                if let op = inserted_object as? CDOperation {
                    print("Root context has changed - objectWillChange.send()")
                    op.weakCREntity?.objectWillChange.send()
                    // now the containers
                    if op.type != .ghost {
                        if let container = op.container {
                            container.weakCREntity?.objectWillChange.send()
                        } else {
                            CRObject.getOrCreateVirtualRootObject(objectType: op.objectType).objectWillChange.send()
                        }
                    }
                }
            }
            
            for inserted_object in inserted_objects {
                if let op = inserted_object as? CDOperation {
                    print("Root context has changed - rendering changes")
                    op.weakCREntity?.renderOperations([op])
                    // now the containers
                    if op.type != .ghost {
                        if let container = op.container {
                            container.weakCREntity?.renderOperations([op]) // this should trigger container to pickup new sub objects
                        } else {
                            CRObject.getOrCreateVirtualRootObject(objectType: op.objectType).renderOperations([op])
                        }
                    }
                }
            }
        }
    }
}
