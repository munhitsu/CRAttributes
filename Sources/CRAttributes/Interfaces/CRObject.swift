//
//  CRObject.swift
//  CRObject
//
//  Created by Mateusz Lapsa-Malawski on 08/08/2021.
//

import Foundation
import CoreData


//TODO: (IDEA) - this feels like a perfect candidate for actors, but let's wait for a wider understanding of actors and async/await

class CRObject {
    let operation: CRObjectOp
    let type: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
    
    // creates new CRObjects
    init(type: CRObjectType, container: CRObject?) {
        let context = CRStorageController.shared.localContainer.viewContext
        operation = CRObjectOp(context: context, container: container?.operation, type: type)
        self.type = type
        try! context.save()
    }
    
    // object from CoreData form
    init(from: CRObjectOp) {
        operation = from
        type = from.type
        prefetchAttributes()
        
    }
        
    //getOrCreate
    func attribute(name:String, type:CRAttributeType) -> CRAttribute {
        let context = CRStorageController.shared.localContainer.viewContext
        if let attribute = self.attributesDict[name] {
            assert(attribute.type == type)
            return attribute
        }
        
        let request:NSFetchRequest<CRAttributeOp> = CRAttributeOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "parent == %@ AND name == %@ AND rawType == %@", operation, name, type.rawValue)


        let cdResults:[CRAttributeOp] = try! context.fetch(request)
        let attribute:CRAttribute
        if cdResults.count > 0 {
            attribute = CRAttribute.factory(from:cdResults.first!)
        } else {
            attribute = CRAttribute.factory(container:self, name:name, type:type)
        }
        attributesDict[name] = attribute
        return attribute
    }
        
    static func allObjects(type:CRObjectType) -> [CRObject] {
        let request:NSFetchRequest<CRObjectOp> = CRObjectOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "typeRaw == %@", type.rawValue)
        
        let context = CRStorageController.shared.localContainer.viewContext
        
        let cdResults:[CRObjectOp] = try! context.fetch(request)
        let crResults:[CRObject] = cdResults.map { CRObject(from: $0) }
        return crResults
    }

    func prefetchAttributes() {
        let request:NSFetchRequest<CRAttributeOp> = CRAttributeOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "parent == %@", operation)

        let context = CRStorageController.shared.localContainer.viewContext

        let cdResults:[CRAttributeOp] = try! context.fetch(request)
        if cdResults.count > 0 {
            for attributeOp in cdResults {
                attributesDict[attributeOp.name!] = CRAttribute.factory(from:attributeOp)
            }
        }
    }
        
    func subObjects() -> [CRObject] {
        let request:NSFetchRequest<CRObjectOp> = CRObjectOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "parent == %@", operation)

        let context = CRStorageController.shared.localContainer.viewContext
        let cdResults:[CRObjectOp] = try! context.fetch(request)
        
        let crResults = cdResults.map { CRObject(from: $0) }
        return crResults
    }
}
