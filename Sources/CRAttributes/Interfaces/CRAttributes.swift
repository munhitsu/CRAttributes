//
//  CRAttribute.swift
//  CRAttribute
//
//  Created by Mateusz Lapsa-Malawski on 08/08/2021.
//

import Foundation
import CoreData
import AppKit


//TODO: in a very unlikely event that multiple same name attributes will get crated within the same objects - we should be merging all operations
//TODO: CRAttribute could be a template (generic) for LWWs

class CRAttribute {
    var operation: CDOperation? = nil
    let container: CRObject
    let name: String
    let type: CRAttributeType
    let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext, container: CRObject, name: String, type: CRAttributeType) {
        self.context = context
        self.container = container
        self.name = name
        self.type = type
        context.performAndWait {
            let containerObject: CDOperation?
            containerObject = container.operation
            self.operation = CDOperation.createAttribute(context: context, container: containerObject, type: type, name: name)
        }
    }
    
    // Remember to execute within context.perform {}
    init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        assert(from.type == .attribute)
        self.context = context
        self.operation = from
        self.container = container
        self.name = from.attributeName!
        self.type = from.attributeType
    }
    
    internal func getLastOperation() -> CDOperation? {
        var operations:[CDOperation] = []
        context.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "container == %@", operation!)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CDOperation.lamport, ascending: false), NSSortDescriptor(keyPath: \CDOperation.peerID, ascending: false)]

            operations = try! context.fetch(request)
        }
        return operations.first
    }
    
    
    // Remember to execute within context.perform {}
    public static func factory(context: NSManagedObjectContext, from attributeOperation: CDOperation, container: CRObject) -> CRAttribute {
        assert(attributeOperation.type == .attribute)
        //TODO: (low) make it nicer (e.g. store types classes in CRAttributeType
        switch attributeOperation.attributeType {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(context: context, container: container, from: attributeOperation)
        case .int:
            return CRAttributeInt(context: context, container: container, from: attributeOperation)
        case .float:
            return CRAttributeFloat(context: context, container: container, from: attributeOperation)
        case .date:
            return CRAttributeDate(context: context, container: container, from: attributeOperation)
        case .boolean:
            return CRAttributeBool(context: context, container: container, from: attributeOperation)
        case .string:
            return CRAttributeString(context: context, container: container, from: attributeOperation)
        }
    }
    
    public static func factory(context: NSManagedObjectContext, container: CRObject, name: String, type: CRAttributeType) -> CRAttribute {
        switch type {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(context: context, container: container, name: name)
        case CRAttributeType.int:
            return CRAttributeInt(context: context, container: container, name: name)
        case .float:
            return CRAttributeFloat(context: context, container: container, name: name)
        case .date:
            return CRAttributeDate(context: context, container: container, name: name)
        case .boolean:
            return CRAttributeBool(context: context, container: container, name: name)
        case .string:
            return CRAttributeString(context: context, container: container, name: name)
        }
    }
    
    public func operationsCount() -> Int {
        let context = CRStorageController.shared.localContainer.viewContext
        var count = 0
        context.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.predicate = NSPredicate(format: "container == %@", operation!)
            count = try! context.count(for: request)
        }
        return count
    }
}

class CRAttributeInt: CRAttribute {
    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .int)
    }

    override init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        super.init(context: context, container: container, from: from)
    }
    
    var value:Int? {
        get {
            var value:Int?
            context.performAndWait {
                guard let op = getLastOperation() else { return }
                value = Int(op.lwwInt)
            }
            return value
        }
        set {
            context.performAndWait {
                let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
                op.state = .inUpstreamQueueRenderedMerged
            }
        }
    }
}

class CRAttributeFloat: CRAttribute {
    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .float)
    }

    override init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        super.init(context: context, container: container, from: from)
    }

    var value:Float? {
        get {
            var value:Float?
            context.performAndWait {
                guard let op = getLastOperation() else { return }
                value = op.lwwFloat
            }
            return value
        }
        set {
            context.performAndWait {
                let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
                op.state = .inUpstreamQueueRenderedMerged
            }
        }
    }
}

class CRAttributeDate: CRAttribute {
    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .date)
    }

    override init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        super.init(context: context, container: container, from: from)
    }

    var value:Date? {
        get {
            var value:Date?
            context.performAndWait {
                guard let op = getLastOperation() else { return }
                value = op.lwwDate
            }
            return value
        }
        set {
            context.performAndWait {
                let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
                op.state = .inUpstreamQueueRenderedMerged
            }
        }
    }
}


class CRAttributeBool: CRAttribute {
    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .boolean)
    }

    override init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        super.init(context: context, container: container, from: from)
    }

    var value:Bool? {
        get {
            var value:Bool?
            context.performAndWait {
                guard let op = getLastOperation() else { return }
                value = op.lwwBool
            }
            return value
        }
        set {
            context.performAndWait {
                let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
                op.state = .inUpstreamQueueRenderedMerged
            }
        }
    }
}

class CRAttributeString: CRAttribute {
    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .string)
    }

    override init(context: NSManagedObjectContext, container: CRObject, from: CDOperation) {
        super.init(context: context, container: container, from: from)
    }

    var value:String? {
        get {
            var value:String?
            context.performAndWait {
                guard let op = getLastOperation() else { return }
                value = op.lwwString
            }
            return value
        }
        set {
            context.performAndWait {
                let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
                op.state = .inUpstreamQueueRenderedMerged
            }
        }
    }
}
