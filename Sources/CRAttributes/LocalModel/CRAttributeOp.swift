//
//  CRAttribute.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRAttributeOp)
public class CDAttributeOp: CDAbstractOp {

}

extension CDAttributeOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeOp> {
        return NSFetchRequest<CDAttributeOp>(entityName: "CDAttributeOp")
    }

    @NSManaged public var name: String?
    @NSManaged public var rawType: Int32
}


enum CRAttributeType: Int32 {
    case int = 0
    case float = 1
    case date = 2
    case boolean = 3
    case string = 4
    case mutableString = 5
}


extension CDAttributeOp {
    var type: CRAttributeType {
        get {
            return CRAttributeType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}


extension CDAttributeOp {
    convenience init(context: NSManagedObjectContext, container: CRObjectOp?, type: CRAttributeType, name: String) {
        self.init(context: context, container: container)
        self.type = type
        self.name = name
    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoAttributeOperation, container: CDAbstractOp?, waitingForContainer: Bool=false) {
        print("From protobuf AttributeOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.name = protoForm.name
        self.rawType = protoForm.rawType
        self.container = container
        if container != nil {
            self.containerLamport = container!.lamport
            self.containerPeerID = container!.peerID
        }
        self.waitingForContainer = waitingForContainer
        self.upstreamQueueOperation = false

        
        for protoItem in protoForm.deleteOperations {
            _ = CRDeleteOp(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.lwwOperations {
            _ = CRLWWOp(context: context, from: protoItem, container: self)
        }

        if protoForm.stringInsertOperations.count > 0 {
            _ = CRStringInsertOp.restoreLinkedList(context: context, from: protoForm.stringInsertOperations, container: self)
        }
    }

    static func allObjects() -> [CDAttributeOp]{
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDAttributeOp> = CDAttributeOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try! context.fetch(request)
    }

//    func protoOperation() -> ProtoAttributeOperation {
//        return ProtoAttributeOperation.with {
//            $0.base = super.protoOperation()
//            $0.name = name!
//            $0.rawType = rawType
//        }
//    }
}

