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
    
    @NSManaged public var container: CRAbstractOp?
    @NSManaged public var containedOperations: NSSet?

    @NSManaged public var containerLamport: lamportType
    @NSManaged public var containerPeerID: UUID


    @NSManaged public var upstreamQueueOperation: Bool
    @NSManaged public var downstreamQueueHeadOperation: Bool
    // TODO: add boolean attributes that it's waiting in pecific queues

}

// MARK: Generated accessors for subOperations
extension CRAbstractOp {

    @objc(addSubOperationsObject:)
    @NSManaged public func addToContainedOperations(_ value: CRAbstractOp)

    @objc(removeSubOperationsObject:)
    @NSManaged public func removeFromContainedOperations(_ value: CRAbstractOp)

    @objc(addSubOperations:)
    @NSManaged public func addToContainedOperations(_ values: NSSet)

    @objc(removeSubOperations:)
    @NSManaged public func removeFromContainedOperations(_ values: NSSet)

}

extension CRAbstractOp : Identifiable {

}

extension CRAbstractOp {
    convenience init(context: NSManagedObjectContext, container: CRAbstractOp?) {
        self.init(context:context)
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.container = container
        if container == nil {
            self.containerLamport = 0
            self.containerPeerID = UUID.zero
        } else {
            self.containerLamport = container!.lamport
            self.containerPeerID = container!.peerID
        }
        self.hasTombstone = false
    }
    
//    convenience init(context: NSManagedObjectContext, proto:ProtoBaseOperation) {
//        self.init(context:context)
//        self.version = proto.version
//        self.lamport = proto.id.lamport
//        self.peerID = proto.id.peerID.object()
//        self.parent
//        self.attribute
    //  @objc   }
    
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

    static func operation(fromLamport:Int64, fromPeerID:UUID, in context: NSManagedObjectContext) -> CRAbstractOp? {
        let request:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
        request.predicate = NSPredicate(format: "lamport = %@ and peerID = %@", argumentArray: [fromLamport, fromPeerID])
        return try? context.fetch(request)[0]
    }

    
    static func operation(from protoID:ProtoOperationID, in context: NSManagedObjectContext) -> CRAbstractOp? {
        return operation(fromLamport: protoID.lamport, fromPeerID: protoID.peerID.object(), in: context)
    }

    static func operation(from operationID:CROperationID, in context: NSManagedObjectContext) -> CRAbstractOp? {
        return operation(fromLamport: operationID.lamport, fromPeerID: operationID.peerID, in: context)
    }

//    func protoOperation() -> ProtoBaseOperation {
//        return ProtoBaseOperation.with {
//            $0.version = version
//            $0.id = protoOperationID()
//            if let parent = parent { //TODO: implementation of null for message is language specific
//                $0.parentID = parent.protoOperationID()
//            }
//            if let attribute = attribute { //TODO: implementation of null for message is language specific
//                $0.attributeID = attribute.protoOperationID()
//            }
//        }
//    }
    
}
