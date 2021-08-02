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
        .entity(name: "CoOpAbstractOperation",
                managedObjectClass: CoOpAbstractOperation.self,
                isAbstract: true,
                attributes: [
                    .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),

                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .integer64AttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType),
                ],
                relationships: [
                    .relationship(name: "parent", destination: "CoOpAbstractOperation", optional: true, toMany: false, inverse: "subOperations"),  // insertion point
                    .relationship(name: "attribute", destination: "CoOpAttribute", optional: true, toMany: false),  // insertion point
                    .relationship(name: "subOperations", destination: "CoOpAbstractOperation", optional: true, toMany: true, inverse: "parent"),  // insertion point
                ],
                indexes: [
                    .index(name: "lamport", elements: [.property(name: "lamport")]),
                    .index(name: "lamport-peerID", elements: [.property(name: "lamport"),.property(name: "peerID")])
                ],
                constraints: ["lamport", "peerID"]
        ),
        // object parent is an object it is nested within
        // null parent means it's a top level object
        // if you are a folder then set yourself a CoOpAttribute "name"
        // subOperations will be either sub attributes or sub objects
        .entity(name: "CoOpObject",
                managedObjectClass: CoOpObject.self,
                parentEntity: "CoOpAbstractOperation",
                attributes: [
                    .attribute(name: "rawType", type: .integer16AttributeType, defaultValue: Int16(0))
                ]
        ),
        // attribute parent is an object attribute is nested within
        .entity(name: "CoOpAttribute",
                managedObjectClass: CoOpAttribute.self,
                parentEntity: "CoOpAbstractOperation",
                attributes: [
                    .attribute(name: "name", type: .stringAttributeType, defaultValue: "default"),
                    .attribute(name: "rawType", type: .integer16AttributeType, defaultValue: Int16(0))
                ],
                relationships: [
                    .relationship(name: "attributeOperations", destination: "CoOpAbstractOperation", toMany: true, inverse: "attribute"),
                    // we may need the head attribute operation or a quick query to find it - e.g. all operations pointint to this attribute but without parent - shoub be good enough
                ]
        ),
        .entity(
            name: "CoOpLWW",
            managedObjectClass: CoOpLWW.self,
            parentEntity: "CoOpAbstractOperation",
            attributes: [
                .attribute(name: "int", type: .integer64AttributeType),
                .attribute(name: "float", type: .floatAttributeType),
                .attribute(name: "date", type: .dateAttributeType),
                .attribute(name: "boolean", type: .booleanAttributeType),
                .attribute(name: "string", type: .stringAttributeType)
            ]
        ),
        // parent is what was deleted
        .entity(
            name: "CoOpDelete",
            managedObjectClass: CoOpMutableStringOperationDelete.self
        ),
        .entity(
            name: "RenderedString",
            managedObjectClass: RenderedString.self,
            attributes: [
                .attribute(name: "string", type: .binaryDataAttributeType)
            ]
        ),
        .entity(
            name: "CoOpStringInsert",
            managedObjectClass: CoOpStringInsert.self,
            parentEntity: "CoOpAbstractOperation",
            attributes: [
                .attribute(name: "character", type: .integer32AttributeType),
            ],
            relationships: [
                .relationship(name: "next", destination: "CoOpStringInsert", toMany: false, inverse: "prev"),
                .relationship(name: "prev", destination: "CoOpStringInsert", toMany: false, inverse: "next"),
            ]
        ),
        .entity(
            name: "CoOpQueue",
            managedObjectClass: CoOpQueue.self,
            attributes: [
                .attribute(name: "rawType", type: .integer64AttributeType),
                .attribute(name: "lamport", type: .integer64AttributeType),
                .attribute(name: "peerID", type: .integer64AttributeType),
            ],
            relationships: [
                .relationship(name: "operation", destination: "CoOpAbstractOperation", optional: false, toMany: false)
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
public let coOpLocalModel = localModelDescription.makeModel()
public let coOpReplicatedModel = replicatedModelDescription.makeModel()


//TODO: follow iwht https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
public struct CoOpStorageController {

    static let shared = CoOpStorageController()

    static var preview: CoOpStorageController = {
        let result = CoOpStorageController(inMemory: true)
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

    init(inMemory: Bool = false) {

        localContainer = NSPersistentContainer(name: "CoOpLocalModel", managedObjectModel: coOpLocalModel)
        replicatedContainer = NSPersistentCloudKitContainer(name: "CoOpReplicatedModel", managedObjectModel: coOpReplicatedModel)

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
