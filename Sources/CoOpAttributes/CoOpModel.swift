//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData
import CoreDataModelDescription


let modelDescription = CoreDataModelDescription(
    entities: [
        .entity(
            name: "IntLwwCoOpAttribute",
            managedObjectClass: IntLwwCoOpAttribute.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),
            ],
            relationships: [
                .relationship(name: "operations", destination: "CoOpLog", toMany: true),
            ]
        ),
        .entity(
            name: "StringLwwCoOpAttribute",
            managedObjectClass: StringLwwCoOpAttribute.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),
            ],
            relationships: [
                .relationship(name: "operations", destination: "CoOpLog", toMany: true),
            ]
        ),
        .entity(
            name: "BooleanLwwCoOpAttribute",
            managedObjectClass: BooleanLwwCoOpAttribute.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),
            ],
            relationships: [
                .relationship(name: "operations", destination: "CoOpLog", toMany: true),
            ]
        ),
        .entity(
            name: "CoOpLog",
            managedObjectClass: CoOpLog.self,
            attributes: [
                .attribute(name: "lamport", type: .integer64AttributeType),
                .attribute(name: "peerID", type: .integer64AttributeType),
                .attribute(name: "version", type: .integer16AttributeType, defaultValue: Int16(0)),
                .attribute(name: "rawOperation", type: .binaryDataAttributeType),
            ],
            indexes: [
                .index(name: "lamport", elements: [.property(name: "lamport")])
            ],
            constraints: ["lamport", "peerID"]
        )
    ]
)

// global variables are lazy
public let coOpModel = modelDescription.makeModel()


struct CoOpPersistenceController {

    static let shared = CoOpPersistenceController()

    static var preview: CoOpPersistenceController = {
        let result = CoOpPersistenceController(inMemory: true)
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

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {

        container = NSPersistentContainer(name: "CoOpModel", managedObjectModel: coOpModel)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)

//        taskContext = container.newBackgroundContext()
    }
}
