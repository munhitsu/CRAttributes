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
    var objectOperation:CDOperation? = nil
    let context: NSManagedObjectContext
    let type: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
    
    // creates new CRObjects
    init(context: NSManagedObjectContext, type: CRObjectType, container: CRObject?) {
        self.context = context
        self.type = type
        context.performAndWait {
            let containerObject: CDOperation?
            containerObject = container?.objectOperation
            self.objectOperation = CDOperation.createObject(context: context, container: containerObject, type: type)
        }
    }
    
    // Remember to execute within context.perform {}
    init(context: NSManagedObjectContext, from: CDOperation) {
        self.context = context
        objectOperation = from
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
            let predicate = NSPredicate(format: "container == %@ AND attributeName == %@", argumentArray: [objectOperation!, name])
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
        request.predicate = NSPredicate(format: "container == %@ AND rawType == %@ ", argumentArray: [objectOperation!, CDOperationType.attribute.rawValue])

    
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
            request.predicate = NSPredicate(format: "container == %@", objectOperation!)

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(context: context, from: $0) }
        }
        return crResults
    }
}
