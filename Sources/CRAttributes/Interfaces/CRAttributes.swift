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
    var operationObjectID: NSManagedObjectID? = nil
    let container: CRObject
    let name: String
    let type: CRAttributeType
    
    init(container: CRObject, name: String, type: CRAttributeType) {
        let context = CRStorageController.shared.localContainer.viewContext
        self.container = container
        self.name = name
        self.type = type
        context.performAndWait {
            let containerObject: CDObjectOp?
            containerObject = context.object(with: container.operationObjectID!) as? CDObjectOp
            let operation = CDAttributeOp(context: context, container: containerObject, type: type, name: name)
            try! context.save()
            self.operationObjectID = operation.objectID
        }
    }
    
    // Remember to execute within context.perform {}
    init(from: CDAttributeOp, container: CRObject) {
        operationObjectID = from.objectID
        self.container = container
        name = from.name!
        type = from.type
    }
    
    // Remember to execute within context.perform {}
    public static func factory(from attributeOperation: CDAttributeOp, container: CRObject) -> CRAttribute {
        //TODO: (low) make it nicer (e.g. store types classes in CRAttributeType
        switch attributeOperation.type {
        case CRAttributeType.mutableString:
            return CRAttributeMutableString(from: attributeOperation, container: container)
        case .int:
            return CRAttributeInt(from: attributeOperation, container: container)
        case .float:
            return CRAttributeFloat(from: attributeOperation, container: container)
        case .date:
            return CRAttributeDate(from: attributeOperation, container: container)
        case .boolean:
            return CRAttributeBool(from: attributeOperation, container: container)
        case .string:
            return CRAttributeString(from: attributeOperation, container: container)
        }
    }
    
    public static func factory(container: CRObject, name: String, type: CRAttributeType) -> CRAttribute {
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
            let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
            request.predicate = NSPredicate(format: "container == %@", context.object(with: operationObjectID!))
            count = try! context.count(for: request)
        }
        return count
    }
}

class CRAttributeInt: CRAttribute {
    
    var value:Int? {
        get {
            let context = CRStorageController.shared.localContainer.viewContext
            var value:Int?
            context.performAndWait {
                let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "container == %@", context.object(with:operationObjectID!))
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLWWOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CDLWWOp.peerID, ascending: false)]

                let operations:[CDLWWOp] = try! context.fetch(request)
                if operations.isEmpty {
                    value = nil
                } else {
                    value = Int(operations.first!.int)
                }
            }
            return value
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            context.performAndWait {
                _ = CDLWWOp(context: context, container: context.object(with:operationObjectID!) as? CDAttributeOp, value: newValue!)
            }
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .int)
    }

    override init(from: CDAttributeOp, container: CRObject) {
        super.init(from: from, container: container)
    }
}

class CRAttributeFloat: CRAttribute {
    
    var value:Float? {
        get {
            let context = CRStorageController.shared.localContainer.viewContext
            var value:Float?
            context.performAndWait {
                let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "container == %@", context.object(with:operationObjectID!))
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLWWOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CDLWWOp.peerID, ascending: false)]

                let operations:[CDLWWOp] = try! context.fetch(request)
                if operations.isEmpty {
                    value = nil
                } else {
                    value = operations.first!.float
                }
            }
            return value
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            context.performAndWait {
                _ = CDLWWOp(context: context, container: context.object(with: operationObjectID!) as? CDAttributeOp, value: newValue!)
            }
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .float)
    }

    override init(from: CDAttributeOp, container: CRObject) {
        super.init(from: from, container: container)
    }
}

class CRAttributeDate: CRAttribute {
    
    var value:Date? {
        get {
            let context = CRStorageController.shared.localContainer.viewContext
            var value:Date?
            context.performAndWait {
                let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "container == %@", context.object(with:operationObjectID!))
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLWWOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CDLWWOp.peerID, ascending: false)]

                let operations:[CDLWWOp] = try! context.fetch(request)
                if operations.isEmpty {
                    value = nil
                } else {
                    value = operations.first!.date
                }
            }
            return value
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            context.performAndWait {
                _ = CDLWWOp(context: context, container: context.object(with: operationObjectID!) as? CDAttributeOp, value: newValue!)
            }
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .date)
    }

    override init(from: CDAttributeOp, container: CRObject) {
        super.init(from: from, container: container)
    }
}

class CRAttributeBool: CRAttribute {
    
    var value:Bool? {
        get {
            let context = CRStorageController.shared.localContainer.viewContext
            var value:Bool?
            context.performAndWait {
                let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "container == %@", context.object(with:operationObjectID!))
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLWWOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CDLWWOp.peerID, ascending: false)]

                let operations:[CDLWWOp] = try! context.fetch(request)
                if operations.isEmpty {
                    value = nil
                } else {
                    value = operations.first!.boolean
                }
            }
            return value
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            context.performAndWait {
                _ = CDLWWOp(context: context, container: context.object(with: operationObjectID!) as? CDAttributeOp, value: newValue!)
            }
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .boolean)
    }

    override init(from: CDAttributeOp, container: CRObject) {
        super.init(from: from, container: container)
    }
}

class CRAttributeString: CRAttribute {
    
    var value:String? {
        get {
            let context = CRStorageController.shared.localContainer.viewContext
            var value:String?
            context.performAndWait {
                let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
                request.returnsObjectsAsFaults = false
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "container == %@", context.object(with:operationObjectID!))
                request.sortDescriptors = [NSSortDescriptor(keyPath: \CDLWWOp.lamport, ascending: false), NSSortDescriptor(keyPath: \CDLWWOp.peerID, ascending: false)]

                let operations:[CDLWWOp] = try! context.fetch(request)
                if operations.isEmpty {
                    value = nil
                } else {
                    value = operations.first!.string
                }
            }
            return value
        }
        set {
            let context = CRStorageController.shared.localContainer.viewContext
            context.performAndWait {
                _ = CDLWWOp(context: context, container: context.object(with: operationObjectID!) as? CDAttributeOp, value: newValue!)
            }
        }
    }

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .string)
    }

    override init(from: CDAttributeOp, container: CRObject) {
        super.init(from: from, container: container)
    }
}
