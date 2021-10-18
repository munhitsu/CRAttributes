//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData

@objc(CDStringInsertOp)
public class CDStringInsertOp: CDAbstractOp {

}


extension CDStringInsertOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStringInsertOp> {
        return NSFetchRequest<CDStringInsertOp>(entityName: "CDStringInsertOp")
    }

    @NSManaged public var contribution: String
    @NSManaged public var offset: Int64
    @NSManaged public var parent: CDStringInsertOp?
    @NSManaged public var childOperations: NSSet?

    @NSManaged public var next: CDStringInsertOp?
    @NSManaged public var prev: CDStringInsertOp?

}


// MARK: Generated accessors for childOperations
extension CDAttributeOp {

    @objc(addAttributeOperationsObject:)
    @NSManaged public func addToChildOperations(_ value: CDStringInsertOp)

    @objc(removeAttributeOperationsObject:)
    @NSManaged public func removeFromChildOperations(_ value: CDStringInsertOp)

    @objc(addAttributeOperations:)
    @NSManaged public func addToChildOperations(_ values: NSSet)

    @objc(removeAttributeOperations:)
    @NSManaged public func removeFromChildOperations(_ values: NSSet)

}


extension CDStringInsertOp {
    convenience init(context: NSManagedObjectContext, parent: CDStringInsertOp?, container: CDAttributeOp?, contribution: String, offset: Int64 = 0) {
        self.init(context:context, container: container)
        self.contribution = contribution
        self.offset = offset
        self.parent = parent
    }
//    convenience init(context: NSManagedObjectContext, parent: CDStringInsertOp?, container: CDAttributeOp?, contribution: unichar) {
//        self.init(context:context, container: container)
//        var uc = contribution
//        self.contribution = NSString(characters: &uc, length: 1) as String //TODO: migrate to init(utf16CodeUnits: UnsafePointer<unichar>, count: Int)
//        self.parent = parent
//    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoStringInsertOperation, container: CDAbstractOp?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.contribution = protoForm.contribution
        self.parent = CDStringInsertOp.operation(from: protoForm.parentID, in: context) as? CDStringInsertOp // will be null if parent is not yet with us
        self.container = container
        self.upstreamQueueOperation = false


        for protoItem in protoForm.deleteOperations {
            _ = CDDeleteOp(context: context, from: protoItem, container: self)
        }
        
    }
    
    static func restoreLinkedList(context: NSManagedObjectContext, from: [ProtoStringInsertOperation], container: CDAttributeOp?) -> CDStringInsertOp {
        var cdOperations:[CDStringInsertOp] = []
        var prevOp:CDStringInsertOp? = nil
        for protoOp in from {
            let op = CDStringInsertOp(context: context, from: protoOp, container: container)
            cdOperations.append(op)
            op.prev = prevOp
            prevOp?.next = op
            prevOp = op
        }
        return cdOperations[0]
    }

    func stringAddress() -> CRStringAddress {
        //TODO: cache me
        return CRStringAddress(lamport: self.lamport, peerID: self.peerID, offset: self.offset)
    }
    
    func opProxy() -> CDStringInsertOpProxy {
        return CDStringInsertOpProxy(context: managedObjectContext!, object: self)
    }
//    func protoOperation() -> ProtoStringInsertOperation {
//        return ProtoStringInsertOperation.with {
//            $0.base = super.protoOperation()
//            $0.contribution = contribution
//        }
//    }
}
