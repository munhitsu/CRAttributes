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
    var operationObjectID: NSManagedObjectID? = nil // CDObjectOp
    let type: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
    let context: NSManagedObjectContext
    
    // creates new CRObjects
    init(context: NSManagedObjectContext, type: CRObjectType, container: CRObject?) {
        self.context = context
        self.type = type
        context.performAndWait {
            let containerObject: CDOperation?
            if container != nil {
                containerObject = context.object(with: container!.operationObjectID!) as? CDOperation
            } else {
                containerObject = nil
            }
            let operation = CDOperation.createObject(context: context, container: containerObject, type: type)
            try! context.save()
            self.operationObjectID = operation.objectID
        }
    }
    
    // Remember to execute within context.perform {}
    init(context: NSManagedObjectContext, from: CDOperation) {
        self.context = context
        operationObjectID = from.objectID
        type = from.objectType
        prefetchAttributes()
    }
        
    //getOrCreate
    func attribute(name: String, type attributeType: CRAttributeType) -> CRAttribute {
        if let attribute = self.attributesDict[name] {
            assert(attribute.type == attributeType)
            return attribute
        }

        context.performAndWait {
            // let's check if it doesn't exist already
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            let predicate = NSPredicate(format: "container == %@ AND attributeName == %@", context.object(with: operationObjectID!), name)
            request.predicate = predicate

            let cdResults:[CDOperation] = try! context.fetch(request)

            let attribute:CRAttribute
            if cdResults.count > 0 {
                //it exists
                assert(cdResults.first!.attributeType == attributeType)
                attribute = CRAttribute.factory(context: context, from: cdResults.first!, container: self)
            } else {
                //let's create
                attribute = CRAttribute.factory(context: context, container:self, name:name, type:attributeType)
            }
            attributesDict[name] = attribute

        }
        
        return attributesDict[name]!
    }
        
    static func allObjects(context: NSManagedObjectContext, type:CRObjectType) -> [CRObject] {
        var crResults:[CRObject] = []
        
        context.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawObjectType == \(type.rawValue)")

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(context: context, from: $0) }
            
        }
        return crResults
    }

    func prefetchAttributes() {
//        context.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ AND rawType == %@ ", argumentArray: [context.object(with: operationObjectID!), CDOperationType.attribute.rawValue])

    
            let cdResults:[CDOperation] = try! context.fetch(request)

            if cdResults.count > 0 {
                for attributeOp in cdResults {
                    attributesDict[attributeOp.attributeName!] = CRAttribute.factory(context: context, from:attributeOp, container: self)
                }
            }
//        }
        //TODO: prefetch string sub deletes
    }
        
    func subObjects() -> [CRObject] {
        var crResults:[CRObject] = []

        context.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == %@", context.object(with: operationObjectID!))

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(context: context, from: $0) }
        }
        return crResults
    }
}
