//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData
import CoreDataModelDescription


// use case
// list of all top level folders
// list of all folders and notes within a folder
// list of all attributes within a note

let localModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "CRAbstractOp",
                managedObjectClass: CRAbstractOp.self,
                isAbstract: true,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .UUIDAttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType),
                    .attribute(name: "upstreamQueue", type: .booleanAttributeType, defaultValue: true) //TODO: remove default
                ],
                relationships: [
                    .relationship(name: "parent", destination: "CRAbstractOp", optional: true, toMany: false, inverse: "subOperations"),  // insertion point
                    .relationship(name: "attribute", destination: "CRAttributeOp", optional: true, toMany: false),  // insertion point
                    .relationship(name: "subOperations", destination: "CRAbstractOp", optional: true, toMany: true, inverse: "parent"),  // insertion point
                ],
                indexes: [
                    .index(name: "lamport", elements: [.property(name: "lamport")]),
                    .index(name: "lamportPeerID", elements: [.property(name: "lamport"),.property(name: "peerID")])
                ],
                constraints: ["lamport", "peerID"]
               ),
        // object parent is an object it is nested within
        // null parent means it's a top level object
        // if you are a folder then set yourself a CRAttributeOp "name"
        // subOperations will be either sub attributes or sub objects
            .entity(name: "CRObjectOp",
                    managedObjectClass: CRObjectOp.self,
                    parentEntity: "CRAbstractOp",
                    attributes: [
                        .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                    ]
                   ),
        // attribute parent is an object attribute is nested within
        .entity(name: "CRAttributeOp",
                managedObjectClass: CRAttributeOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "name", type: .stringAttributeType, defaultValue: "default"),
                    .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                ],
                relationships: [
                    .relationship(name: "attributeOperations", destination: "CRAbstractOp", toMany: true, inverse: "attribute"),
                    // we may need the head attribute operation or a quick query to find it - e.g. all operations pointint to this attribute but without parent - shoub be good enough
                ]
               ),
        .entity(name: "CRLWWOp",
                managedObjectClass: CRLWWOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "int", type: .integer64AttributeType, isOptional: true),
                    .attribute(name: "float", type: .floatAttributeType, isOptional: true),
                    .attribute(name: "date", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "boolean", type: .booleanAttributeType, isOptional: true),
                    .attribute(name: "string", type: .stringAttributeType, isOptional: true)
                ]
               ),
        // parent is what was deleted
        .entity(name: "CRDeleteOp",
                managedObjectClass: CRDeleteOp.self,
                parentEntity: "CRAbstractOp"
               ),
        .entity(name: "RenderedString",
                managedObjectClass: RenderedString.self,
                attributes: [
                    .attribute(name: "string", type: .binaryDataAttributeType)
                ]
               ),
        .entity(name: "CRStringInsertOp",
                managedObjectClass: CRStringInsertOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "contribution", type: .stringAttributeType),
                ],
                relationships: [
                    .relationship(name: "next", destination: "CRStringInsertOp", toMany: false, inverse: "prev"),
                    .relationship(name: "prev", destination: "CRStringInsertOp", toMany: false, inverse: "next"),
                ]
               ),
        .entity(name: "CRQueue",
                managedObjectClass: CRQueue.self,
                attributes: [
                    .attribute(name: "rawType", type: .integer64AttributeType),
                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .integer64AttributeType),
                ],
                relationships: [
                    .relationship(name: "operation", destination: "CRAbstractOp", optional: false, toMany: false)
                ]
               )
    ]
)


let replicatedModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "OperationsForest",
                managedObjectClass: OperationsForest.self,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "peerID", type: .UUIDAttributeType, defaultValue: localPeerID),
                    .attribute(name: "data", type: .binaryDataAttributeType),
                ]
               )
    ]
)


// global variables are lazy
public let CRLocalModel = localModelDescription.makeModel()
public let CRReplicatedModel = replicatedModelDescription.makeModel()


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


extension CRStorageController {
    static func processUpsteamQueue() {
        let contextLocal = CRStorageController.shared.localContainer.newBackgroundContext()
        let contextRemote = CRStorageController.shared.replicatedContainer.newBackgroundContext()
        
        let forests = protoOperationsForests(context: contextLocal)
        
        for protoForest in forests {
            let _ = OperationsForest(context: contextRemote, from:protoForest)
        }
        try? contextRemote.save()
    }
    
    static func protoOperationsForests(context: NSManagedObjectContext) -> [ProtoOperationsForest] {
        let request:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "upstreamQueue == true")
        let queuedOperations:[CRAbstractOp] = try! context.fetch(request)
        
        var forests:[ProtoOperationsForest] = []
        var forest = ProtoOperationsForest()
        
        
        for queuedOperation in queuedOperations {
            // as we progress operations will be removed
            if queuedOperation.upstreamQueue {
                var tree = ProtoOperationsTree()
                if let id = queuedOperation.parent?.protoOperationID() {
                    tree.parentID = id //TODO: what with the null?
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
                case let op as CRStringInsertOp:
                    tree.stringInsertOperation = protoStringInsertOperationRecurse(op)
                default:
                    fatalNotImplemented()
                }
                forest.trees.append(tree)
            }
        }
        forest.version = 0
        forest.peerID = localPeerID.data
        forests.append(forest)
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
            $0.lamport = operation.lamport
            $0.rawType = operation.rawType
        }
        
        for operation in operation.subOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueue {
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
        operation.upstreamQueue = false
        return proto
    }

    static func protoDeleteOperationRecurse(_ operation: CRDeleteOp) -> ProtoDeleteOperation {
        let proto = ProtoDeleteOperation.with {
            $0.version = operation.version
            $0.lamport = operation.lamport
        }
        operation.upstreamQueue = false
        return proto
    }

    static func protoAttributeOperationRecurse(_ operation: CRAttributeOp) -> ProtoAttributeOperation {
        var proto = ProtoAttributeOperation.with {
            $0.version = operation.version
            $0.lamport = operation.lamport
            $0.name = operation.name!
            $0.rawType = operation.rawType
        }
        
        for operation in operation.subOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueue {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    case let op as CRLWWOp:
                        proto.lwwOperations.append(protoLWWOperationRecurse(op))
                    case let op as CRStringInsertOp:
                        proto.stringInsertOperations.append(protoStringInsertOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueue = false
        return proto
    }
    
    static func protoLWWOperationRecurse(_ operation: CRLWWOp) -> ProtoLWWOperation {
        var proto = ProtoLWWOperation.with {
            $0.version = operation.version
            $0.lamport = operation.lamport
            switch (operation.parent as! CRAttributeOp).type {
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
        
        for operation in operation.subOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueue {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueue = false
        return proto
    }
    
    static func protoStringInsertOperationRecurse(_ operation: CRStringInsertOp) -> ProtoStringInsertOperation {
        var proto = ProtoStringInsertOperation.with {
            $0.version = operation.version
            $0.lamport = operation.lamport
            $0.contribution = operation.contribution
        }
        
        for operation in operation.subOperations!.allObjects {
            if let operation = operation as? CRAbstractOp {
                if operation.upstreamQueue {
                    switch operation {
                    case let op as CRDeleteOp:
                        proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                    case let op as CRStringInsertOp:
                        proto.stringInsertOperations.append(protoStringInsertOperationRecurse(op))
                    default:
                        fatalError("unsupported subOperation")
                    }
                }
            }
        }
        operation.upstreamQueue = false
        return proto
    }



}
