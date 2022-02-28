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
        case .some(.objectOperation(_)):
            print("restoring object")
            let _ = CDOperation.findOrCreateOperation(context: context, from: objectOperation, container: container, type: .object)
        case .some(.deleteOperation(_)):
            print("restoring delete")
            let _ = CDOperation.findOrCreateOperation(context: context, from: deleteOperation, container: container, type: .delete)
        case .some(.lwwOperation(_)):
            print("restoring lww")
            let _ = CDOperation.findOrCreateOperation(context: context, from: lwwOperation, container: container, type: .lwwBool) // we need any lww type here
        case .some(.stringInsertOperationsList(_)):
            print("restoring [stringInsert]")
            stringInsertOperationsList.restore(context: context, container: container)
        case .none:
            fatalNotImplemented()
        }
    }
}

extension ProtoStringInsertOperationLinkedList: RestorableProtobuf {
    func restore(context: NSManagedObjectContext, container: CDOperation?) {
        Task {
    //        var prevOp:CDOperation? = nil
            //TODO: this is naivly slow - e.g. we should leverage that string comes as a linked list
            var headOp:CDOperation? = nil
            var containerObjectID: NSManagedObjectID? = nil
            context.performAndWait {
                for protoOp in stringInsertOperations {
                    let op = CDOperation.findOrCreateOperation(context: context, from: protoOp, container: container, type: .stringInsert)
        //            if op.prev != nil { // it was already linked, it's a re-restore
        //                continue
        //            }
                    if headOp == nil {
                        headOp = op
                    }
        //            prevOp?.next = op
        //            prevOp = op
                    op.mergeFromDownstream(context: context)
                    // it will be ether all rendered or none
                }
    //            headOp?.mergeDownstream(context: context)
                //TODO: when do we check for orphans?
                try! context.save()
                containerObjectID = headOp?.container?.objectID
            }
            var crAttribute:CRAttributeMutableString? = nil
            if containerObjectID != nil {
                // in case string is disconnected from it's parrent, it will be skipped
                await crAttribute = CREntity.getOrCreateCREntity(context: CRStorageController.shared.localContainer.viewContext, objectID: containerObjectID!) as? CRAttributeMutableString
                await crAttribute?.renderOperations([headOp!.objectID])
            }
        }
    }
}

extension ProtoOperationID {
    func crOperationID() -> CROperationID {
        return CROperationID(from: self)
    }
}
