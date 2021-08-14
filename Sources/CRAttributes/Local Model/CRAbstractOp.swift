//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf

@objc(CRAbstractOp)
public class CRAbstractOp: NSManagedObject {

}

extension CRAbstractOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRAbstractOp> {
        return NSFetchRequest<CRAbstractOp>(entityName: "CRAbstractOp")
    }

    @NSManaged public var version: Int32
    @NSManaged public var lamport: Int64
    @NSManaged public var peerID: UUID
    @NSManaged public var hasTombstone: Bool
    @NSManaged public var parent: CRAbstractOp?
    @NSManaged public var attribute: CRAttributeOp? // primary use to prefetch all string operations, secondary to get counts of operations per attribute
    @NSManaged public var subOperations: NSSet?

    @NSManaged public var upstreamQueue: Bool
    // TODO: add boolean attributes that it's waiting in pecific queues

}

// MARK: Generated accessors for subOperations
extension CRAbstractOp {

    @objc(addSubOperationsObject:)
    @NSManaged public func addToSubOperations(_ value: CRAbstractOp)

    @objc(removeSubOperationsObject:)
    @NSManaged public func removeFromSubOperations(_ value: CRAbstractOp)

    @objc(addSubOperations:)
    @NSManaged public func addToSubOperations(_ values: NSSet)

    @objc(removeSubOperations:)
    @NSManaged public func removeFromSubOperations(_ values: NSSet)

}

extension CRAbstractOp : Identifiable {

}

extension CRAbstractOp {
    convenience init(context: NSManagedObjectContext, parent: CRAbstractOp?, attribute: CRAttributeOp?) {
        self.init(context:context)
        self.version = 0
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.parent = parent
        self.attribute = attribute
        self.hasTombstone = false
    }
    
    convenience init(context: NSManagedObjectContext, proto:ProtoBaseOperation) {
        self.init(context:context)
        self.version = proto.version
        self.lamport = proto.id.lamport
        self.peerID = proto.id.peerID.object()
        self.parent
        self.attribute
    }
    
    func operationID() -> CROperationID {
        return CROperationID(lamport: lamport, peerID: peerID)
    }
    
    func protoOperationID() -> ProtoOperationID {
        return ProtoOperationID.with {
            $0.lamport = lamport
            $0.peerID = peerID.data
        }
    }
    
    static func upstreamWaitingOperations() -> [CRAbstractOp] {
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "upstreamQueue == true")
        return try! context.fetch(request)
    }
    
    func protoOperation() -> ProtoBaseOperation {
        return ProtoBaseOperation.with {
            $0.version = version
            $0.id = protoOperationID()
            if let parent = parent { //TODO: implementation of null for message is language specific
                $0.parentID = parent.protoOperationID()
            }
            if let attribute = attribute { //TODO: implementation of null for message is language specific
                $0.attributeID = attribute.protoOperationID()
            }
        }
    }
}
