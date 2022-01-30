//
//  CRAttribute.swift
//  CRAttribute
//
//  Created by Mateusz Lapsa-Malawski on 08/08/2021.
//

import Foundation
import CoreData
#if targetEnvironment(macCatalyst)
import AppKit
#endif


//TODO: in a very unlikely event that multiple same name attributes will get crated within the same objects - we should be merging all operations
//TODO: CRAttribute could be a template (generic) for LWWs

public class CRAttribute: CREntity {
    let attributeName: String
    let attributeType: CRAttributeType
    
    init(container: CRObject, name: String, type: CRAttributeType) {
        self.attributeName = name
        self.attributeType = type
        let context = CRStorageController.shared.localContainer.viewContext // we are on MainActor
        var newOperation:CDOperation? = nil
//        self.container = container
        context.performAndWait { //if it's all on mainActor, then this seems redundant
            let containerObject: CDOperation?
            containerObject = container.operation
            newOperation = CDOperation.createAttribute(context: context, container: containerObject, type: type, name: name)
            try! context.save()
        }
        super.init(operation: newOperation, type: .attribute, prefetchContainedEntities: false)
    }

    init(from: CDOperation) {
        assert(from.weakCREntity == nil)
        assert(from.type == .attribute)
        self.attributeName = from.attributeName!
        self.attributeType = from.attributeType
//        super.init(type: .attribute)
        super.init(operation: from)
//        self.container = operation!.container!.getOrCreateCREntity()! as! CRObject
        self.operation?.weakCREntity = self
    }

    /**
     useful for LWW type attributes
     */
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
    public static func factory(context: NSManagedObjectContext, from attributeOperation: CDOperation) -> CRAttribute {
        assert(attributeOperation.type == .attribute)
        //TODO: (low) make it nicer (e.g. store types classes in CRAttributeType
        switch attributeOperation.attributeType {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(from: attributeOperation)
        case .int:
            return CRAttributeInt(from: attributeOperation)
        case .float:
            return CRAttributeFloat(from: attributeOperation)
        case .date:
            return CRAttributeDate(from: attributeOperation)
        case .boolean:
            return CRAttributeBool(from: attributeOperation)
        case .string:
            return CRAttributeString(from: attributeOperation)
        }
    }
    
    /**
     creates a new attribute
     */
    public static func factory(context: NSManagedObjectContext, container: CRObject, name: String, type: CRAttributeType) -> CRAttribute {
        switch type {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(container: container, name: name)
        case CRAttributeType.int:
            return CRAttributeInt(container: container, name: name)
        case .float:
            return CRAttributeFloat(container: container, name: name)
        case .date:
            return CRAttributeDate(container: container, name: name)
        case .boolean:
            return CRAttributeBool(container: container, name: name)
        case .string:
            return CRAttributeString(container: container, name: name)
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

public class CRAttributeInt: CRAttribute {

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .int)
        _value = getStorageValue()
    }

    override init(from: CDOperation) {
        super.init(from: from)
        _value = getStorageValue()
    }
    
    var _value: Int? = nil // this is the default
    
    public var value:Int? {
        get {
            return _value
        }
        set {
            _value = newValue
            setStorageValue(newValue)
        }
    }
    
    func setStorageValue(_ newValue: Int?) {
        context.performAndWait {
            let op = CDOperation.createLWW(context: context, container: operation, value: newValue!) //TODO: why don't we allow to set the value to null in the storage
            op.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }

    func getStorageValue() -> Int? {
        var value:Int?
        context.performAndWait {
            guard let op = getLastOperation() else { return }
            value = Int(op.lwwInt)
        }
        return value
    }

    override func renderOperations(_ operations: [CDOperation]) {
        _value = getStorageValue()
    }
}

public class CRAttributeFloat: CRAttribute {
    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .float)
        _value = getStorageValue()
    }

    override init(from: CDOperation) {
        super.init(from: from)
        _value = getStorageValue()
    }
    
    var _value: Float? = nil // this is the default
    
    public var value:Float? {
        get {
            return _value
        }
        set {
            _value = newValue
            setStorageValue(newValue)
        }
    }
    
    func setStorageValue(_ newValue: Float?) {
        context.performAndWait {
            let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
            op.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }

    func getStorageValue() -> Float? {
        var value:Float?
        context.performAndWait {
            guard let op = getLastOperation() else { return }
            value = op.lwwFloat
        }
        return value
    }

    override func renderOperations(_ operations: [CDOperation]) {
        _value = getStorageValue()
    }
}

public class CRAttributeDate: CRAttribute {
    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .date)
        _value = getStorageValue()
    }

    override init(from: CDOperation) {
        super.init(from: from)
        _value = getStorageValue()
    }

    var _value: Date? = nil // this is the default
    
    public var value:Date? {
        get {
            return _value
        }
        set {
            _value = newValue
            setStorageValue(newValue)
        }
    }
    
    func setStorageValue(_ newValue: Date?) {
        context.performAndWait {
            let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
            op.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }

    func getStorageValue() -> Date? {
        var value:Date?
        context.performAndWait {
            guard let op = getLastOperation() else { return }
            value = op.lwwDate
        }
        return value
    }

    override func renderOperations(_ operations: [CDOperation]) {
        _value = getStorageValue()
    }
}


public class CRAttributeBool: CRAttribute {
    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .boolean)
        _value = getStorageValue()
    }

    override init(from: CDOperation) {
        super.init(from: from)
        _value = getStorageValue()
    }

    var _value: Bool? = nil // this is the default
    
    public var value: Bool? {
        get {
            return _value
        }
        set {
            _value = newValue
            setStorageValue(newValue)
        }
    }
    
    func setStorageValue(_ newValue: Bool?) {
        context.performAndWait {
            let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
            op.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }

    func getStorageValue() -> Bool? {
        var value:Bool?
        context.performAndWait {
            guard let op = getLastOperation() else { return }
            value = op.lwwBool
        }
        return value
    }

    override func renderOperations(_ operations: [CDOperation]) {
        _value = getStorageValue()
    }
}

public class CRAttributeString: CRAttribute {
    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .string)
        _value = getStorageValue()
    }

    override init(from: CDOperation) {
        super.init(from: from)
        _value = getStorageValue()
    }

    var _value: String? = nil // this is the default
    
    public var value:String? {
        get {
            return _value
        }
        set {
            _value = newValue
            setStorageValue(newValue)
        }
    }
    
    func setStorageValue(_ newValue: String?) {
        context.performAndWait {
            let op = CDOperation.createLWW(context: context, container: operation, value: newValue!)
            op.state = .inUpstreamQueueRenderedMerged
            try! context.save()
        }
    }

    func getStorageValue() -> String? {
        var value:String?
        context.performAndWait {
            guard let op = getLastOperation() else { return }
            value = op.lwwString
        }
        return value
    }

    override func renderOperations(_ operations: [CDOperation]) {
        _value = getStorageValue()
        prefetchContainedEntities()
    }
}
