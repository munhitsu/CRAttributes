//
//  CDOperation+Delete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData



extension CDOperation { // Delete
    
    // container stores the closest Attribute or above - for prefetching
    // parent references to what is deleted
    
    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parent: CDOperation) -> CDOperation {
        return CDOperation(context: context, container: container, parent: parent, type: .delete)
    }

    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parentID: CROperationID) -> CDOperation {
        return CDOperation(context: context, container: container, parentID: parentID, type: .delete)
    }

    /**
     initialise from the protobuf
     */
    func updateObject(from protoForm: ProtoDeleteOperation, container: CDOperation?) {
//        print("From protobuf DeleteOp(\(protoForm.id.lamport))")
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        let parentID = protoForm.parentID.crOperationID()
        self.parent = CDOperation.findOperationOrCreateGhost(from: parentID, in: managedObjectContext!)
        self.parent?.hasTombstone = true
        self.type = .delete
        self.state = .inDownstreamQueueMergedUnrendered // parent has tombstone - we've merged, and it doesn't matter if parent is a ghost
        
//        if lamport == 22 {
//            print(parent)
//            print("foo")
//        }
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

extension CDOperation {
    func protoDeleteOperationRecurse() -> ProtoDeleteOperation {
        assert(self.type == .delete)
        let proto = ProtoDeleteOperation.with {
            $0.version = self.version
            $0.id.lamport = self.lamport
            $0.id.peerID  = self.peerID.data
            $0.parentID.lamport = self.parent?.lamport ?? 0
            $0.parentID.peerID = (self.parent?.peerID ?? UUID.zero).data
        }
        
        self.state = .processed
        return proto
    }
}
