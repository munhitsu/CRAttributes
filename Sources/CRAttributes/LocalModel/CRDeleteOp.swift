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
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoDeleteOperation, container: CRAbstractOp?) {
        print("From protobuf DeleteOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.container?.hasTombstone = true
        if container != nil {
            self.containerLamport = container!.lamport
            self.containerPeerID = container!.peerID
        }
    }
}
