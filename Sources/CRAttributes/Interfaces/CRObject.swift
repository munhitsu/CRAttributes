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
    var operation:CDOperation? = nil
    let context: NSManagedObjectContext
    let type: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
    
    // creates new CRObjects
    init(context: NSManagedObjectContext, type: CRObjectType, container: CRObject?) {
        self.context = context
        self.type = type
        context.performAndWait {
            let containerObject: CDOperation?
            containerObject = container?.operation
            self.operation = CDOperation.createObject(context: context, container: containerObject, type: type)
        }
    }
    
    // Remember to execute within context.perform {}
    init(context: NSManagedObjectContext, from: CDOperation) {
        self.context = context
        operation = from
        type = from.objectType
        prefetchAttributes()
    }
        
    //getOrCreate
    func attribute(name: String, type attributeType: CRAttributeType) -> CRAttribute {
        print("attribute")
        if let attribute = self.attributesDict[name] {
//            print("attributesDict:")
//            for (key, value) in attributesDict {
//                print("name:\(key) type:\(value.type)")
//            }
            assert(attribute.type == attributeType)
            return attribute
        }

        context.performAndWait {
            // let's check if it doesn't exist already
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            let predicate = NSPredicate(format: "container == %@ AND attributeName == %@ AND rawType == %@ AND rawAttributeType == %@", argumentArray: [operation!, name, CDOperationType.attribute.rawValue, attributeType.rawValue])
            request.predicate = predicate

            let cdResults:[CDOperation] = try! context.fetch(request)

            var attribute:CRAttribute? = nil
            for op in cdResults {
                guard op.container == operation && op.attributeName == name && op.type == .attribute && op.attributeType == attributeType else {
                    continue
                }
                print(op)
                assert(op.type == .attribute)
                assert(op.attributeType == attributeType)
                attribute = CRAttribute.factory(context: context, from: op, container: self)
                break //TODO: make it deterministic in case we have multiple attributes of the same name
            }
            if attribute == nil {
                attribute = CRAttribute.factory(context: context, container:self, name:name, type:attributeType)
            }
            print("caching attribute \(name) of type \(String(describing: attribute?.type))")
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
        print("prefetchAttributes")
//        context.performAndWait {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ AND rawType == %@ ", argumentArray: [operation!, CDOperationType.attribute.rawValue])

    
        let cdResults:[CDOperation] = try! context.fetch(request)

        if cdResults.count > 0 {
            for attributeOp in cdResults {
                guard attributeOp.type == .attribute else { continue }
                print(attributeOp)
                attributesDict[attributeOp.attributeName!] = CRAttribute.factory(context: context, from:attributeOp, container: self)
                print("caching attribute \(attributeOp.attributeName!) of type \(attributesDict[attributeOp.attributeName!]!.type)")
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
            request.predicate = NSPredicate(format: "container == %@", operation!)

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            crResults = cdResults.map { CRObject(context: context, from: $0) }
        }
        return crResults
    }
}
