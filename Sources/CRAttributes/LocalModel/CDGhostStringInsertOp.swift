//
//  CRDelete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CDGhostStringInsertOp)
public class CDGhostStringInsertOp: CDStringInsertOp {

}

extension CDGhostStringInsertOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDGhostStringInsertOp> {
        return NSFetchRequest<CDGhostStringInsertOp>(entityName: "CDGhostStringInsertOp")
    }
}

extension CDGhostStringInsertOp {
    convenience init(context: NSManagedObjectContext, from protoID: ProtoOperationID) {
        self.init(context: context)
        self.peerID = protoID.peerID.object()
        self.lamport = protoID.lamport
    }
}
