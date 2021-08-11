//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRAbstractOp)
public class CRAbstractOp: NSManagedObject {

}

extension CRAbstractOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRAbstractOp> {
        return NSFetchRequest<CRAbstractOp>(entityName: "CRAbstractOp")
    }

    @NSManaged public var version: Int16
    @NSManaged public var lamport: Int64
    @NSManaged public var peerID: UUID
    @NSManaged public var hasTombstone: Bool
    @NSManaged public var parent: CRAbstractOp?
    @NSManaged public var attribute: CRAttributeOp?
    @NSManaged public var subOperations: NSSet?
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
    
    func operationID() -> CROperationID {
        return CROperationID(lamport: lamport, peerID: peerID)
    }
}
