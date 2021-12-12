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
                container = CDOperation.fetchOperationOrGhost(from: containerID, in: context)
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
            let _ = CDOperation.findOrCreateOperation(context: context, from: lwwOperation, container: container, type: .lwwInt) // we need any lww type here
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
        for op in stringInsertOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: op, container: container, type: .stringInsert) //TODO: this is naivly slow
//            let _ = CDOperation(context: context, from: op, container: container)
        }
    }
}
