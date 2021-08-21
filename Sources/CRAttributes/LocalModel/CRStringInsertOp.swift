//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData

@objc(CRStringInsertOp)
public class CRStringInsertOp: CRAbstractOp {

}


extension CRStringInsertOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRStringInsertOp> {
        return NSFetchRequest<CRStringInsertOp>(entityName: "CRStringInsertOp")
    }

    @NSManaged public var contribution: String
    @NSManaged public var parent: CRStringInsertOp?
    @NSManaged public var parentLamport: lamportType
    @NSManaged public var parentPeerID: UUID
    @NSManaged public var waitingForParent: Bool
    @NSManaged public var childOperations: NSSet?

    @NSManaged public var next: CRStringInsertOp?
    @NSManaged public var prev: CRStringInsertOp?

}


// MARK: Generated accessors for childOperations
extension CRAttributeOp {

    @objc(addAttributeOperationsObject:)
    @NSManaged public func addToChildOperations(_ value: CRStringInsertOp)

    @objc(removeAttributeOperationsObject:)
    @NSManaged public func removeFromChildOperations(_ value: CRStringInsertOp)

    @objc(addAttributeOperations:)
    @NSManaged public func addToChildOperations(_ values: NSSet)

    @objc(removeAttributeOperations:)
    @NSManaged public func removeFromChildOperations(_ values: NSSet)

}


extension CRStringInsertOp {
    convenience init(context: NSManagedObjectContext, parent: CRStringInsertOp?, container: CRAttributeOp?, contribution: String) {
        self.init(context:context, container: container)
        self.contribution = contribution
        self.parent = parent
        if parent == nil {
            self.parentLamport = 0
            self.parentPeerID = UUID.zero
        } else {
            self.parentPeerID = parent!.peerID
            self.parentLamport = parent!.lamport
        }
    }
    convenience init(context: NSManagedObjectContext, parent: CRStringInsertOp?, container: CRAttributeOp?, contribution: unichar) {
        self.init(context:context, container: container)
        var uc = contribution
        self.contribution = NSString(characters: &uc, length: 1) as String //TODO: migrate to init(utf16CodeUnits: UnsafePointer<unichar>, count: Int)
        self.parent = parent
        if parent == nil {
            self.parentLamport = 0
            self.parentPeerID = UUID.zero
        } else {
            self.parentPeerID = parent!.peerID
            self.parentLamport = parent!.lamport
        }
    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoStringInsertOperation, container: CRAbstractOp?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.contribution = protoForm.contribution
        self.parent = CRStringInsertOp.operation(from: protoForm.parentID, in: context) as? CRStringInsertOp // will be null if parent is not yet with us
        self.parentLamport = protoForm.parentID.lamport
        self.parentPeerID = protoForm.parentID.peerID.object()
        self.container = container
        if container != nil {
            self.containerLamport = container!.lamport
            self.containerPeerID = container!.peerID
        }

        for protoItem in protoForm.deleteOperations {
            _ = CRDeleteOp(context: context, from: protoItem, container: self)
        }
        
        // head of the orphaned branch
        if self.parent == nil && self.parentLamport != 0 {
            self.waitingForContainer = true
        }
    }
    
    static func restoreLinkedList(context: NSManagedObjectContext, from: [ProtoStringInsertOperation], container: CRAttributeOp?) -> CRStringInsertOp {
        var cdOperations:[CRStringInsertOp] = []
        var prevOp:CRStringInsertOp? = nil
        for protoOp in from {
            let op = CRStringInsertOp(context: context, from: protoOp, container: container)
            cdOperations.append(op)
            op.prev = prevOp
            prevOp?.next = op
            prevOp = op
        }
        return cdOperations[0]
    }

//    func protoOperation() -> ProtoStringInsertOperation {
//        return ProtoStringInsertOperation.with {
//            $0.base = super.protoOperation()
//            $0.contribution = contribution
//        }
//    }
}
