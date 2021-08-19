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

//    func protoOperation() -> ProtoStringInsertOperation {
//        return ProtoStringInsertOperation.with {
//            $0.base = super.protoOperation()
//            $0.contribution = contribution
//        }
//    }
}
