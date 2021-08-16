//
//  CRObject.swift
//  CRObject
//
//  Created by Mateusz Lapsa-Malawski on 08/08/2021.
//

import Foundation
import CoreData


//TODO: (IDEA) - this feels like a perfect candidate for actors, but let's wait for a wider understanding of actors and async/await

//TODO: future - delay attribute creation until it's used - but then it increases prorability of duplicate attribute objects...., so maybe not
// ideally object creation should instantly create attributes

class CRObject {
    var operationObjectID: NSManagedObjectID? = nil // CRObjectOp
    let type: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
    
    // creates new CRObjects
    init(type: CRObjectType, container: CRObject?) {
        let context = CRStorageController.shared.localContainer.viewContext
        self.type = type
        context.performAndWait {
            let containerObject: CRObjectOp?
            if container != nil {
                containerObject = context.object(with: container!.operationObjectID!) as? CRObjectOp
            } else {
                containerObject = nil
            }
            let operation = CRObjectOp(context: context, container: containerObject, type: type)
            try! context.save()
            self.operationObjectID = operation.objectID
        }
    }
    
    // Remember to execute within context.perform {}
    init(from: CRObjectOp) {
        operationObjectID = from.objectID
        type = from.type
        prefetchAttributes()
    }
        
    //getOrCreate
    func attribute(name: String, type attributeType: CRAttributeType) -> CRAttribute {
        let context = CRStorageController.shared.localContainer.viewContext

        if let attribute = self.attributesDict[name] {
            assert(attribute.type == attributeType)
            return attribute
        }

        context.performAndWait {
            let request:NSFetchRequest<CRAttributeOp> = CRAttributeOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            let predicate = NSPredicate(format: "container == %@ AND name == %@", context.object(with: operationObjectID!), name)
            request.predicate = predicate

            let cdResults:[CRAttributeOp] = try! context.fetch(request)

            let attribute:CRAttribute
            if cdResults.count > 0 {
                assert(cdResults.first!.type == attributeType)
                attribute = CRAttribute.factory(from: cdResults.first!, container: self)
            } else {
                attribute = CRAttribute.factory(container:self, name:name, type:attributeType)
            }
            attributesDict[name] = attribute

        }
        
        return attributesDict[name]!
    }
        
    static func allObjects(type:CRObjectType) -> [CRObject] {
        let context = CRStorageController.shared.localContainer.viewContext
        var crResults:[CRObject] = []
        
        context.performAndWait {
            let request:NSFetchRequest<CRObjectOp> = CRObjectOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawType == \(type.rawValue)")

            let cdResults:[CRObjectOp] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(from: $0) }
            
        }
        return crResults
    }

    func prefetchAttributes() {
        let context = CRStorageController.shared.localContainer.viewContext
//        context.performAndWait {
            let request:NSFetchRequest<CRAttributeOp> = CRAttributeOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == %@", context.object(with: operationObjectID!))

    
            let cdResults:[CRAttributeOp] = try! context.fetch(request)

            if cdResults.count > 0 {
                for attributeOp in cdResults {
                    attributesDict[attributeOp.name!] = CRAttribute.factory(from:attributeOp, container: self)
                }
            }
//        }
        //TODO: prefetch string sub deletes
    }
        
    func subObjects() -> [CRObject] {
        let context = CRStorageController.shared.localContainer.viewContext
        var crResults:[CRObject] = []

        context.performAndWait {
            let request:NSFetchRequest<CRObjectOp> = CRObjectOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == %@", context.object(with: operationObjectID!))

            let cdResults:[CRObjectOp] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(from: $0) }
        }
        return crResults
    }
}
