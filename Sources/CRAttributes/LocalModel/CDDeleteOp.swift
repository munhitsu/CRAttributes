//
//  CRDelete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CDDeleteOp)
public class CDDeleteOp: CDAbstractOp {

}

extension CDDeleteOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDDeleteOp> {
        return NSFetchRequest<CDDeleteOp>(entityName: "CDDeleteOp")
    }

//    func protoOperation() -> ProtoDeleteOperation {
//        return ProtoDeleteOperation.with {
//            $0.base = super.protoOperation()
//        }
//    }
}

extension CDDeleteOp {
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoDeleteOperation, container: CDAbstractOp?, waitingForContainer: Bool=false) {
        print("From protobuf DeleteOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.container?.hasTombstone = true
        self.upstreamQueueOperation = false

    }
}
