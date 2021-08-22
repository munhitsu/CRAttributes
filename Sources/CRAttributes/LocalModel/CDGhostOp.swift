//
//  CRDelete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CDGhostOp)
public class CDGhostOp: CDAbstractOp {

}

extension CDGhostOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDGhostOp> {
        return NSFetchRequest<CDGhostOp>(entityName: "CDGhostOp")
    }
}

extension CDDeleteOp {
    convenience init(context: NSManagedObjectContext, from protoID: ProtoOperationID) {
        self.init(context: context)
        self.peerID = protoID.peerID.object()
        self.lamport = protoID.lamport
    }
}
