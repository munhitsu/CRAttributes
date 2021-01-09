//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData
import CoreDataModelDescription

public enum CoOpAttributeType : UInt {

    case register = 0

    case text = 100

}

//let foo = CoreDataAttributeDescription.attribute(name: "version", type: .integer64AttributeType)
//
//let foo2:[CoreDataAttributeDescription] = [.attribute(name: "dd", type: .integer16AttributeType)]
//




let modelDescription = CoreDataModelDescription(
    entities: [
        .entity(
            name: "CoOpAttribute",
            managedObjectClass: CoOpAttribute.self,
            attributes: [
                .attribute(name: "type", type: .integer16AttributeType),
                .attribute(name: "version", type: .integer16AttributeType),
            ],
            relationships: [
                .relationship(name: "cache", destination: "CoOpCache", toMany: false, inverse: "attribute"),
                .relationship(name: "operations", destination: "CoOpLog", toMany: true, inverse: "attribute"),
            ],
            indexes: []
        ),
        .entity(
            name: "CoOpCache", // or use KV on LMDB
            managedObjectClass: CoOpCache.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType),
                .attribute(name: "int", type: .integer64AttributeType),
                .attribute(name: "string", type: .stringAttributeType),
            ],
            relationships: [
                .relationship(name: "attribute", destination: "CoOpAttribute", toMany: false, inverse: "cache")
            ]
        ),
        .entity(
            name: "CoOpLog",
            managedObjectClass: CoOpLog.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType),
                .attribute(name: "lamport", type: .integer64AttributeType),
                .attribute(name: "peerId", type: .UUIDAttributeType),
                .attribute(name: "operation", type: .stringAttributeType),
            ],
            relationships: [
                .relationship(name: "attribute", destination: "CoOpAttribute", toMany: false, inverse: "operations")
            ]
        ),
    ]
)


struct CoOpPersistenceController {
    let model = modelDescription.makeModel()

    static let shared = CoOpPersistenceController()

    static var preview: CoOpPersistenceController = {
        let result = CoOpPersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
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

        container = NSPersistentContainer(name: "CoOpModel", managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)

        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })

//        taskContext = container.newBackgroundContext()
    }
}
