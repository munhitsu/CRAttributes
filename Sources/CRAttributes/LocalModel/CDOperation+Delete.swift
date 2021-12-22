//
//  CDOperation+Delete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData

extension CDOperation {
    
    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parent: CDOperation) -> CDOperation {
        return CDOperation(context: context, container: container, parent: parent, type: .delete)
    }
    
    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parentId: CROperationID) -> CDOperation {
        return CDOperation(context: context, container: container, parentId: parentId, type: .delete)
    }

    /**
     initialise from the protobuf
     */
    func updateObject(from protoForm: ProtoDeleteOperation, container: CDOperation?) {
        print("From protobuf DeleteOp(\(protoForm.id.lamport))")
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.container?.hasTombstone = true
        self.type = .delete
        self.state = .inDownstreamQueueMergedUnrendered // parent has tombstone - we've merged
    }

    func deleteLinking() {
        let context = managedObjectContext!
        guard type == .delete else { fatalError() }
        if parent == nil {
            let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)
            parent = CDOperation.findOperationOrCreateGhost(from: parentAddress, in: context)
        }
        guard let parent = parent else { fatalError() }

        parent.hasTombstone = true
    }
}


