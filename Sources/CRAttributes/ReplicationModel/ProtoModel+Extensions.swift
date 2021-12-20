//
//  ProtoModel+Extensions.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 03/12/2021.
//

import Foundation
import CoreData



protocol RestorableProtobuf {
    func restore(context: NSManagedObjectContext, container: CDOperation?)
}

extension ProtoOperationsForest: RestorableProtobuf {
    func restore(context: NSManagedObjectContext, container: CDOperation? = nil) {
        for tree in trees {
            print("restoring tree")
            let containerID = CROperationID(from: tree.containerID)
            
            let container:CDOperation?
            if containerID.isZero() {
                // this means independent tree
                container = nil
            } else {
                container = CDOperation.findOperationOrCreateGhost(from: containerID, in: context)
            }
            tree.restore(context: context, container: container)
        }
    }
}

extension ProtoOperationsTree: RestorableProtobuf {
    func restore(context: NSManagedObjectContext, container: CDOperation? = nil) {
        switch value {
        case .some(.attributeOperation(_)):
            print("restoring attribute")
            let _ = CDOperation.findOrCreateOperation(context: context, from: attributeOperation, container: container, type: .attribute)
//            let _ = CDOperation(context: context, from: attributeOperation, container: container)
        case .some(.objectOperation(_)):
            print("restoring object")
            let _ = CDOperation.findOrCreateOperation(context: context, from: objectOperation, container: container, type: .object)
//            let _ = CDOperation(context: context, from: objectOperation, container: container)
        case .some(.deleteOperation(_)):
            print("restoring delete")
            let _ = CDOperation.findOrCreateOperation(context: context, from: deleteOperation, container: container, type: .delete)
//            let _ = CDOperation(context: context, from: deleteOperation, container: container)
        case .some(.lwwOperation(_)):
            print("restoring lww")
            let _ = CDOperation.findOrCreateOperation(context: context, from: lwwOperation, container: container, type: .lwwBool) // we need any lww type here
//            let _ = CDOperation(context: context, from: lwwOperation, container: container)
        case .some(.stringInsertOperations(_)):
            print("restoring [stringInsert]")
//            let _ = CDOperation.findOrCreateOperation(context: context, from: objectOperation, container: container, type: .object)
            stringInsertOperations.restore(context: context, container: container)
        case .none:
            fatalNotImplemented()
        }
    }
}

extension ProtoStringInsertOperationLinkedList: RestorableProtobuf {
    func restore(context: NSManagedObjectContext, container: CDOperation?) {
//        var prevOp:CDOperation? = nil
        //TODO: this is naivly slow
        let headOp:CDOperation? = nil
        for protoOp in stringInsertOperations {
            let op = CDOperation.findOrCreateOperation(context: context, from: protoOp, container: container, type: .stringInsert)
//            if op.prev != nil { // it was already linked, it's a re-restore
//                continue
//            }
//            if headOp == nil {
//                headOp = op
//            }
//            prevOp?.next = op
//            prevOp = op
            op.mergeDownstream(context: context)
        }
        headOp?.mergeDownstream(context: context)
    }
}
