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
                    .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),

                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .integer64AttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType),
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
                    .attribute(name: "rawType", type: .integer16AttributeType, defaultValue: Int16(0))
                ]
        ),
        // attribute parent is an object attribute is nested within
        .entity(name: "CRAttributeOp",
                managedObjectClass: CRAttributeOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "name", type: .stringAttributeType, defaultValue: "default"),
                    .attribute(name: "rawType", type: .integer16AttributeType, defaultValue: Int16(0))
                ],
                relationships: [
                    .relationship(name: "attributeOperations", destination: "CRAbstractOp", toMany: true, inverse: "attribute"),
                    // we may need the head attribute operation or a quick query to find it - e.g. all operations pointint to this attribute but without parent - shoub be good enough
                ]
        ),
        .entity(
            name: "CRLWWOp",
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
        .entity(
            name: "CRDeleteOp",
            managedObjectClass: CRDeleteOp.self,
            parentEntity: "CRAbstractOp"
        ),
        .entity(
            name: "RenderedString",
            managedObjectClass: RenderedString.self,
            attributes: [
                .attribute(name: "string", type: .binaryDataAttributeType)
            ]
        ),
        .entity(
            name: "CRStringInsertOp",
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
        .entity(
            name: "CRQueue",
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
        .entity(name: "ReplicatedOperationPack",
                managedObjectClass: ReplicatedOperationPack.self,
                attributes: [
                    .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),
                    .attribute(name: "attributeLamport", type: .integer64AttributeType),
                    .attribute(name: "attributePeerID", type: .integer64AttributeType),
                    .attribute(name: "rawPack", type: .binaryDataAttributeType),
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
