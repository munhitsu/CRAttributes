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

@MainActor public class CRObject: CREntity {
    let objectType: CRObjectType
    var attributesDict: [String:CRAttribute] = [:]
        
    // creates new CRObjects
    public init(objectType: CRObjectType, container: CRObject?) {
        self.objectType = objectType
        let context = CRStorageController.shared.localContainer.viewContext // we are on MainActor
        var newOperation:CDOperation? = nil
        
        context.performAndWait {
            let containerOp: CDOperation?
            containerOp = container?.operation
            newOperation = CDOperation.createObject(context: context, container: containerOp, type: objectType)
            try! context.save()
        }
        super.init(operation: newOperation!, type: .object, prefetchContainedEntities: false) //it's new so nothing to contain (for nor as we may want to accept that even new parent could be a duplicate)
    }
    
    public init(from: CDOperation) {
//        operation = from
        assert(from.weakCREntity == nil)
        objectType = from.objectType
        super.init(operation: from)
        self.operation?.weakCREntity = self
        prefetchAttributes()
    }
    

    /**
     for virtualRoot
     */
    init(context: NSManagedObjectContext, objectType: CRObjectType) {
        self.objectType = objectType
        super.init(context: context, type: .object)
    }

    
    
    //getOrCreate
    public func attribute(name: String, attributeType: CRAttributeType) -> CRAttribute {
        if let attribute = self.attributesDict[name] {
            assert(attribute.attributeType == attributeType)
            return attribute
        }
        assert(operation != nil)

        context.performAndWait {
            // let's check if it doesn't exist already
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            let predicate = NSPredicate(format: "container == %@ AND attributeName == %@ AND rawType == %@ AND rawAttributeType == %@",
                                        argumentArray: [operation!, name, CDOperationType.attribute.rawValue, attributeType.rawValue])
            request.predicate = predicate

            let cdResults:[CDOperation] = try! context.fetch(request)

            var attribute:CRAttribute? = nil
            for op in cdResults {
                guard op.container == operation && op.attributeName == name && op.type == .attribute && op.attributeType == attributeType else {
                    continue
                }
                assert(op.type == .attribute)
                assert(op.attributeType == attributeType)
                attribute = CREntity.getOrCreateCREntity(context: context, objectID: op.objectID) as? CRAttribute
                break //TODO: make it deterministic in case we have multiple attributes of the same name
            }
            if attribute == nil {
                attribute = CRAttribute.factory(container:self, name:name, type:attributeType)
            }
            attributesDict[name] = attribute

        }
        
        return attributesDict[name]!
    }
        
//    public static func allObjects(context: NSManagedObjectContext, type:CRObjectType) -> [CRObject] {
//        var crResults:[CRObject] = []
////        print("allObjects on \(context) using thread \(Thread.current)")
////        print("context.name: \(String(describing: context.name))")
//        context.performAndWait {
//            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
//            request.returnsObjectsAsFaults = false
//            request.predicate = NSPredicate(format: "rawObjectType == %@ AND hasTombstone == false",
//                                            argumentArray: [type.rawValue])
//
//            let cdResults:[CDOperation] = try! context.fetch(request)
//
//            crResults = cdResults.map { CRObject(from: $0) }
//
//        }
//        return crResults
//    }

    func prefetchAttributes() {
//        context.performAndWait {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ AND rawType == %@ ",
                                        argumentArray: [operation!, CDOperationType.attribute.rawValue])

    
        let cdResults:[CDOperation] = try! context.fetch(request)

        if cdResults.count > 0 {
            for attributeOp in cdResults {
                guard attributeOp.type == .attribute else { continue }
                attributesDict[attributeOp.attributeName!] = CREntity.getOrCreateCREntity(context: context, objectID: attributeOp.objectID) as? CRAttribute
            }
        }
//        }
        //TODO: prefetch string sub deletes
    }
    override func renderOperations(_ operations: [CDOperation]) {
        prefetchContainedEntities()
    }

    override func getStorageContainedObjects() -> [CREntity] {
        print("CRObject.getStorageContainedObjects: l:\(self.operationID?.lamport ?? -1) virtual:\(self.is_virtual)")
        var crResults:[CREntity] = []
//        print("context.name: \(context.name)")

        context.performAndWait { // do we still need context.performAndWait if we are @MainActor?
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            if let operation = operation {
                request.predicate = NSPredicate(format: "container == %@ AND hasTombstone == false", argumentArray: [operation])
            } else { // I'm a virtualRoot
                request.predicate = NSPredicate(format: "container == nil AND rawType == %@ AND rawObjectType == %@ AND hasTombstone == false", argumentArray: [CDOperationType.object.rawValue, objectType.rawValue])
            }

            let cdResults:[CDOperation] = try! context.fetch(request)
            
            for cd in cdResults {
                if let cr = CREntity.getOrCreateCREntity(context: context, objectID: cd.objectID) {
                    crResults.append(cr)
                }
            }
        }
        return crResults
    }
    
}

