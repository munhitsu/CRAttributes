//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData

//TODO: follow iwht https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
public struct CRStorageController {
    
    static let shared = CRStorageController()
    
    static var preview: CRStorageController = {
        let result = CRStorageController(inMemory: true)
        //        let viewContext = result.container.viewContext
        //        for _ in 0..<10 {
        //            let newItem = Note(context: viewContext)
        //        }
        //        do {
        //            try viewContext.save()
        //        } catch {
        //            let nsError = error as NSError
        //            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        //        }
        return result
    }()
    
    let localContainer: NSPersistentContainer
    let replicatedContainer: NSPersistentContainer
    
    init(inMemory: Bool = true) {
        localContainer = NSPersistentContainer(name: "CRLocalModel", managedObjectModel: CRLocalModel)
        replicatedContainer = NSPersistentCloudKitContainer(name: "CRReplicatedModel", managedObjectModel: CRReplicatedModel)
        
        if inMemory {
            localContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            replicatedContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        localContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        localContainer.viewContext.automaticallyMergesChangesFromParent = true
        localContainer.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
        
        
        replicatedContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        let replicatedDescription  = replicatedContainer.persistentStoreDescriptions.first
        replicatedDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        replicatedDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    }
    
    

}


// Downstream
extension CRStorageController {
    // TODO: (later) introduce RGA Split and consolidate operations here, this will solve the recursion risk
    
    static func processDownstreamForest(forest cdForestObjectID: NSManagedObjectID) {
        let remoteContext = CRStorageController.shared.replicatedContainer.newBackgroundContext()
        let localContext = CRStorageController.shared.localContainer.newBackgroundContext()

        let cdForest = remoteContext.object(with: cdForestObjectID) as! CDOperationsForest
        
        localContext.performAndWait { //TODO: do I really need to wait here?
            let protoForest = cdForest.protoStructure()
            for tree in protoForest.trees {
                let protoContainerID:ProtoOperationID = tree.containerID
                let parentID = CROperationID(from: protoContainerID)
                if parentID.isZero() {
                    // this means independent tree
                    // just load me
                    _ = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, parent: nil)
                    try? localContext.save()
                } else {
                    if let parentOp = CRAbstractOp.operation(from: parentID, in: localContext) {
                        // just load me
                        // but link root op with the correct parent
                        _ = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, parent: parentOp)
                        try? localContext.save()
                    } else {
                        // just load me
                        // but mark root op as in the downstream queue
                        let root = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, parent: nil)
                        root?.downstreamQueueHeadOperation = true
                        //record somewhere the parentID
                        root?.peerID = parentID.peerID
                        root?.lamport = parentID.lamport
                        try? localContext.save()
                    }
                }
            }
        }
    }
    
    // creates operations
    // returns root CDOperation
    static func rootAfterTreeToOperations(context: NSManagedObjectContext, tree protoTree: ProtoOperationsTree, parent: CRAbstractOp?) -> CRAbstractOp? {
        var root:CRAbstractOp?=nil
        
        switch protoTree.value {
        case .some(.objectOperation):
            root = CRObjectOp(context: context, from: protoTree.objectOperation, container: nil)
            print("Object!")
        case .some(.attributeOperation):
            root = CRAttributeOp(context: context, from: protoTree.attributeOperation, container: nil)
            print("Attribute!")
        case .some(.deleteOperation):
            root = CRDeleteOp(context: context, from: protoTree.deleteOperation, container: nil)
            print("Delete!")
        case .some(.lwwOperation):
            root = CRLWWOp(context: context, from: protoTree.lwwOperation, container: nil)
            print("LWW!")
        case .some(.stringInsertOperation):
            print("StringInsert!")
        case .none:
            fatalNotImplemented()
        case .some(_):
            fatalNotImplemented()
        }
        return root
    }
    
    
}
 

// Upstream
extension CRStorageController {
    static func processUpsteamOperationsQueue() {
        //TODO: how to convert it to context.perform ?
        let contextLocal = CRStorageController.shared.localContainer.newBackgroundContext()
        let contextRemote = CRStorageController.shared.replicatedContainer.newBackgroundContext()
        
        let forests = protoOperationsForests(context: contextLocal)
        
        for protoForest in forests {
            let _ = CDOperationsForest(context: contextRemote, from:protoForest)
        }
        do {
            try contextRemote.save()
            try contextLocal.save()
        } catch {
            fatalError("couldn't save")
        }
    }
    
    static func protoOperationsForests(context: NSManagedObjectContext) -> [ProtoOperationsForest] {
        let request:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "upstreamQueueOperation == true")
        let queuedOperations:[CRAbstractOp] = try! context.fetch(request)
        
        var forests:[ProtoOperationsForest] = []
        var forest = ProtoOperationsForest()
        
        
        for queuedOperation in queuedOperations {
            // as we progress operations will be removed
            if queuedOperation.upstreamQueueOperation {
                var tree = ProtoOperationsTree()
                if let id = queuedOperation.container?.protoOperationID() {
                    tree.containerID = id //TODO: what with the null?
                } else {
                    tree.containerID = CROperationID.zero.protoForm()
                }
                switch queuedOperation {
                case let op as CRObjectOp:
                    tree.objectOperation = protoObjectOperationRecurse(op)
                case let op as CRAttributeOp:
                    tree.attributeOperation = protoAttributeOperationRecurse(op)
                case let op as CRDeleteOp:
                    tree.deleteOperation = protoDeleteOperationRecurse(op)
                case let op as CRLWWOp:
                    tree.lwwOperation = protoLWWOperationRecurse(op)
                case let op as CRStringInsertOp: // TODO: (high) order me here - it's broken!!!
                    tree.stringInsertOperation = protoStringInsertOperationRecurse(op)
                default:
                    fatalNotImplemented()
                }
                forest.trees.append(tree)
            }
        }
        if forest.trees.isEmpty == false {
            forest.version = 0
            forest.peerID = localPeerID.data
            forests.append(forest)
        }
        return forests
    }
    
//    static func protoOperationsForests() -> [ProtoOperationsForest] {
//        //TODO: (high) put a limit on the size of the Bundle
//        // CloudKit sync operation limit is 400 records or 2 MB
//        let operations = CRAbstractOp.upstreamWaitingOperations()
//        var bundle = ProtoOperationsBundle()
//        for operation in operations {
//            switch operation {
//            case let op as CRObjectOp:
//                bundle.objectOperations.append(op.protoOperation())
//            case let op as CRAttributeOp:
//                bundle.attributeOperations.append(op.protoOperation())
//            case let op as CRDeleteOp:
//                bundle.deleteOperations.append(op.protoOperation())
//            case let op as CRLWWOp:
//                bundle.lwwOperations.append(op.protoOperation())
//            case let op as CRStringInsertOp:
//                bundle.stringInsertOperations.append(op.protoOperation())
//            default:
//                fatalNotImplemented()
//            }
//        }
//        return bundle
//    }
//
//    static func uploadOperations() {
//        let context = CRStorageController.shared.replicatedContainer.newBackgroundContext()
//        let cdBundle = OperationsBundle(context: context)
//        cdBundle.version = 0
//        cdBundle.data = try? protoOperationsBundle().serializedData()
//        try? context.save()
//    }
//
//    static func downloadOperations() {
//
//    }

    static func protoObjectOperationRecurse(_ operation: CRObjectOp) -> ProtoObjectOperation {
        var proto = ProtoObjectOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.rawType = operation.rawType
        }
        print("ObjectOperation \(proto.id.lamport)")

        for operation in operation.containedOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueueOperation {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    case let op as CRAttributeOp:
                        proto.attributeOperations.append(protoAttributeOperationRecurse(op))
                    case let op as CRObjectOp:
                        proto.objectOperations.append(protoObjectOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueueOperation = false
        return proto
    }

    static func protoDeleteOperationRecurse(_ operation: CRDeleteOp) -> ProtoDeleteOperation {
        let proto = ProtoDeleteOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
        }
        print("DeleteOperation \(proto.id.lamport)")

        operation.upstreamQueueOperation = false
        return proto
    }

    static func protoAttributeOperationRecurse(_ operation: CRAttributeOp) -> ProtoAttributeOperation {
        var proto = ProtoAttributeOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.name = operation.name!
            $0.rawType = operation.rawType
        }
        print("AttributeOperation \(proto.id.lamport)")

        var headStringOperation:CRStringInsertOp? = nil
        
        for operation in operation.containedOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueueOperation {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    case let op as CRLWWOp:
                        proto.lwwOperations.append(protoLWWOperationRecurse(op))
                    case let op as CRStringInsertOp:
                        if op.prev == nil { // it will be only a new string in a new attribute in this scenario
                            headStringOperation = op
                        }
//                        proto.stringInsertOperations.append(protoStringInsertOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        var node = headStringOperation
        while node != nil {
            proto.stringInsertOperations.append(protoStringInsertOperationRecurse(node!))
            node = node!.next
        }
        operation.upstreamQueueOperation = false
        return proto
    }
    
    static func protoLWWOperationRecurse(_ operation: CRLWWOp) -> ProtoLWWOperation {
        var proto = ProtoLWWOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            switch (operation.container as! CRAttributeOp).type {
            case .int:
                $0.int = operation.int
            case .float:
                $0.float = operation.float
            case .date:
                fatalNotImplemented() //TODO: implement Date
            case .boolean:
                $0.boolean = operation.boolean
            case .string:
                $0.string = operation.string!
            case .mutableString:
                fatalNotImplemented()
            }
        }
        print("LWWOperation \(proto.id.lamport)")

        for operation in operation.containedOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueueOperation {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueueOperation = false
        return proto
    }
    
    static func protoStringInsertOperationRecurse(_ operation: CRStringInsertOp) -> ProtoStringInsertOperation {
        var proto = ProtoStringInsertOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.contribution = operation.contribution
            $0.parentID.lamport = operation.parentLamport
            $0.parentID.peerID = operation.parentPeerID.data
        }
        print("StringInsertOperation \(proto.id.lamport)")
        assert(operation.upstreamQueueOperation)
        for operation in operation.containedOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueueOperation {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueueOperation = false
        return proto
    }



}
