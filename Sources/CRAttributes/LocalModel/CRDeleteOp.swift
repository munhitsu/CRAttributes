//
//  CRDelete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRDeleteOp)
public class CRDeleteOp: CRAbstractOp {

}

extension CRDeleteOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRDeleteOp> {
        return NSFetchRequest<CRDeleteOp>(entityName: "CRDeleteOp")
    }

//    func protoOperation() -> ProtoDeleteOperation {
//        return ProtoDeleteOperation.with {
//            $0.base = super.protoOperation()
//        }
//    }
}

extension CRDeleteOp {
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoDeleteOperation, parent: CRAbstractOp?) {
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.peerID.object()
        self.lamport = protoForm.lamport
        self.parent = parent
        self.parent?.hasTombstone = true
        if parent != nil {
            self.parentLamport = parent!.lamport
            self.parentPeerID = parent!.peerID
        }
    }
}
