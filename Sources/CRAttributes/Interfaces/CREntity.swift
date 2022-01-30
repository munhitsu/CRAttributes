//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 14/01/2022.
//

import Foundation
import CoreData
import Combine

/**
 CREntities are a rendered layer on top of core data
 they preserve the last known state and get updated on all core data changes
 when updating they will notify UI about the changes
 */

/**
 What are virtualRoots?
 Virtual Root is a container (nil) of all objects of specific type that have no container - e.g. all root level notes, or the top level folder "/"
 */


/**
 to add to a collection:
 - create a new CRobject within the container
 to delete from collection:
 - create tombstone on the object
 */
@MainActor public class CREntity: ObservableObject { //AnyObject
    var context: NSManagedObjectContext
    var operation: CDOperation?
    var type: CDOperationType
    var _containedEntities: [CREntity] = []
    var containedObservers: [AnyCancellable] = []
    
    public lazy var operationID: CROperationID =  {
        operation!.operationID()
    }()
    
    var is_virtual: Bool {
        return operation == nil
    }

    // read only
    // updates are done through creation/deletion of specific related objects
    public var containedEntities: [CREntity] {
        get {
           return _containedEntities
        }
    }
    
    static var virtualRootObjects: [CRObjectType: CRObject] = [:] //TODO: move to NSMapTable

    /**
     I have a linked CDOperation and I know that CREntity hasn't been created
     */
    init(operation: CDOperation) {
        assert(operation.weakCREntity == nil)
        self.context = CRStorageController.shared.localContainer.viewContext // we are on MainActor
        self.operation = operation
        self._containedEntities = []
        self.type = operation.type
        assert(type != .ghost)
//        if let containerOp = operation.container {
//            self.container = containerOp.getOrCreateCREntity()
//        }
        prefetchContainedEntities()
    }
    
    /**
     purely to create virtualRoot
     */
    //TODO: convert to     static func virtualRoot(type: CDOperationType) -> CREntity {
    init(type: CDOperationType) {
        self.context = CRStorageController.shared.localContainer.viewContext // we are on MainActor
        self.operation = nil
        self._containedEntities = []
        self.type = type
//        self.container = nil
        prefetchContainedEntities()
    }
    
    /**
     only to be used when also creating CDOperation
     */
    init(operation: CDOperation?, type: CDOperationType, prefetchContainedEntities: Bool=true) {
        assert(operation?.weakCREntity == nil)
        self.context = CRStorageController.shared.localContainer.viewContext // we are on MainActor
        self.operation = operation
//        self.container = container
        self.type = type
        if prefetchContainedEntities {
            self.prefetchContainedEntities()
        }
        self.operation?.weakCREntity = self
    }
        
    func prefetchContainedEntities() {
        self._containedEntities = getStorageContainedObjects()
        containedObservers = []
        for containedEntity in _containedEntities {
            containedObservers.append(containedEntity.objectWillChange.sink {
                [weak self] _ in
                self?.objectWillChange.send()
            })
        }
    }
    
    public static func getOrCreateVirtualRootObject(objectType: CRObjectType) -> CRObject {
        if let virtualRoot = CRObject.virtualRootObjects[objectType] {
            return virtualRoot
        }
        let newVirtualRoot = CRObject(objectType: objectType)
        CRObject.virtualRootObjects[objectType] = newVirtualRoot
        return newVirtualRoot
    }

    /**
     this will be executed on both merge and local changes
     */
    func renderOperations(_ operations: [CDOperation]) {
        prefetchContainedEntities()
//        _containedEntities = getStorageContainedObjects()
    }

    /**
     it creates new array but all CREntities should be reused
     */
    func getStorageContainedObjects() -> [CREntity] {
        print("CREntity.getStorageContainedObjects")
        var crResults:[CREntity] = []
//        print("context.name: \(context.name)")

        context.performAndWait { // do we still need context.performAndWait if we are @MainActor?
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            if let operation = operation {
                request.predicate = NSPredicate(format: "container == %@", argumentArray: [operation])
            } else { // I'm a virtualRoot
                fatalNotImplemented()
            }

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            for cd in cdResults {
                if let cr = cd.getOrCreateCREntity() {
                    crResults.append(cr)
                }
            }
        }
        return crResults
    }
    public func markAsDeleted() {
        context.performAndWait { // do we still need context.performAndWait if we are @MainActor?
            let delete = CDOperation.createDelete(context: context, within: operation?.container, of: operation!)
            self.operation?.hasTombstone = true
            delete.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }
}
