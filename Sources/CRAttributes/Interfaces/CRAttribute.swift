//
//  CRAttribute.swift
//  CRAttribute
//
//  Created by Mateusz Lapsa-Malawski on 08/08/2021.
//

import Foundation
import CoreData


//TODO: in a very unlikely event that multiple same name attributes will get crated within the same objects - we should be merging all operations
//TODO: CRAttribute should be a template...

class CRAttribute {
    let operation: CRAttributeOp
    let container: CRObject
    let name: String
    let type: CRAttributeType
    
    init(container:CRObject, name:String, type:CRAttributeType) {
        let context = CRStorageController.shared.localContainer.viewContext
        operation = CRAttributeOp(context: context, container: container.operation, type: type)
        self.container = container
        self.name = name
        self.type = type
        try! context.save()
    }
    
    init(from:CRAttributeOp) {
        operation = from
        container = CRObject(from:operation.parent as! CRObjectOp)
        name = operation.name!
        type = operation.type
    }
    
    public static func factory(from: CRAttributeOp) -> CRAttribute {
        //TODO: (low) make it nicer (e.g. store types classes in CRAttributeType
        switch from.type {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(from:from)
        case .int:
            return CRAttributeInt(from: from)
        case .float:
            return CRAttributeFloat(from: from)
        case .date:
            return CRAttributeDate(from: from)
        case .boolean:
            return CRAttributeBool(from: from)
        case .string:
            return CRAttributeString(from: from)
        }
    }
    
    public static func factory(container:CRObject, name:String, type:CRAttributeType) -> CRAttribute {
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
        let request:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
        request.predicate = NSPredicate(format: "attribute == %@", operation)

        let context = CRStorageController.shared.localContainer.viewContext
        return try! context.count(for: request)
    }
}

class CRAttributeInt: CRAttribute {
    
    var value:Int? {
        get {
            let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "attribute == %@", operation)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CRStringInsertOp.peerID, ascending: false)]

            let context = CRStorageController.shared.localContainer.viewContext
            let operations:[CRLWWOp] = try! context.fetch(request)
            if operations.isEmpty {
                return nil
            } else {
                return Int(operations.first!.int)
            }
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            _ = CRLWWOp(context: context, attribute: operation, value: newValue!)
//            try! context.save()
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .int)
    }

    override init(from:CRAttributeOp) {
        super.init(from: from)
    }
}

class CRAttributeFloat: CRAttribute {
    
    var value:Float? {
        get {
            let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "attribute == %@", operation)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CRStringInsertOp.peerID, ascending: false)]

            let context = CRStorageController.shared.localContainer.viewContext
            let operations:[CRLWWOp] = try! context.fetch(request)
            if operations.isEmpty {
                return nil
            } else {
                return operations.first!.float
            }
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            _ = CRLWWOp(context: context, attribute: operation, value: newValue!)
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .float)
    }

    override init(from:CRAttributeOp) {
        super.init(from: from)
    }
}

class CRAttributeDate: CRAttribute {
    
    var value:Date? {
        get {
            let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "attribute == %@", operation)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CRStringInsertOp.peerID, ascending: false)]

            let context = CRStorageController.shared.localContainer.viewContext
            let operations:[CRLWWOp] = try! context.fetch(request)
            if operations.isEmpty {
                return nil
            } else {
                return operations.first!.date
            }
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            _ = CRLWWOp(context: context, attribute: operation, value: newValue!)
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .date)
    }

    override init(from:CRAttributeOp) {
        super.init(from: from)
    }
}

class CRAttributeBool: CRAttribute {
    
    var value:Bool? {
        get {
            let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "attribute == %@", operation)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CRStringInsertOp.peerID, ascending: false)]

            let context = CRStorageController.shared.localContainer.viewContext
            let operations:[CRLWWOp] = try! context.fetch(request)
            if operations.isEmpty {
                return nil
            } else {
                return operations.first!.boolean
            }
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            _ = CRLWWOp(context: context, attribute: operation, value: newValue!)
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .boolean)
    }

    override init(from:CRAttributeOp) {
        super.init(from: from)
    }
}

class CRAttributeString: CRAttribute {
    
    var value:String? {
        get {
            let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            request.predicate = NSPredicate(format: "attribute == %@", operation)
            request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CRStringInsertOp.peerID, ascending: false)]

            let context = CRStorageController.shared.localContainer.viewContext
            let operations:[CRLWWOp] = try! context.fetch(request)
            if operations.isEmpty {
                return nil
            } else {
                return operations.first!.string
            }
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            _ = CRLWWOp(context: context, attribute: operation, value: newValue!)
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .string)
    }

    override init(from:CRAttributeOp) {
        super.init(from: from)
    }
}
