//
//  CDOperation+Attribute.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData

extension CDOperation {
    static func createAttribute(context: NSManagedObjectContext, container: CDOperation?, type: CRAttributeType, name: String) -> CDOperation {
        let op = CDOperation(context: context, container: container)
        op.attributeType = type
        op.attributeName = name
        op.type = .attribute
        op.state = .inUpstreamQueueRenderedMerged

        return op
    }

    /**
     from protobuf
     */
    func updateObject(context: NSManagedObjectContext, from protoForm: ProtoAttributeOperation, container: CDOperation?) {
        print("From protobuf AttributeOp(\(protoForm.id.lamport))")
        self.container = container
        self.attributeType = .init(rawValue: protoForm.rawType)!
        self.attributeName = protoForm.name
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.type = .attribute
        self.state = .inDownstreamQueueMergedUnrendered

        
        for protoItem in protoForm.deleteOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .delete)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.lwwOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .lwwInt)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }

        if protoForm.stringInsertOperations.count > 0 {
            _ = CDOperation.restoreLinkedList(context: context, from: protoForm.stringInsertOperations, container: self)
        }
    }

//    static func allObjects() -> [CDAttributeOp]{
//        let context = CRStorageController.shared.localContainer.viewContext
//        let request:NSFetchRequest<CDAttributeOp> = CDAttributeOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        return try! context.fetch(request)
//    }

}


// MARK: - String related
extension CDOperation {
    
    public func stringFromRGAList(context: NSManagedObjectContext) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString(string:"")
        var addressesArray:[CROperationID] = []

        // let's prefetch
        // BTW: there is no need to prefetch delete operations as we have the hasTombstone attribute
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // the head is the attribute operation for strings
        let head:CDOperation? = self

        // build the attributedString
        var node:CDOperation? = head
        node = node?.next // let's skip the head
        while node != nil {
            if node!.hasTombstone == false {
                let contribution = NSMutableAttributedString(string:String(Character(node!.unicodeScalar)))
                attributedString.append(contribution)
                addressesArray.append(node!.operationID())
            }
            node = node!.next
        }
        return (attributedString, addressesArray)
    }
    
    public func stringFromRGATree(context: NSManagedObjectContext) -> (NSMutableAttributedString, [CROperationID]) {
        // let's prefetch
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // the head is the attribute operation for strings
        let head:CDOperation? = self

        guard let head = head else { return (NSMutableAttributedString(string:""), [])}
        return stringFromRGATreeNode(node: head)
    }
    
    
    func stringFromRGATreeNode(node: CDOperation) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString()
        var addressesArray:[CROperationID] = []
        
        if !node.hasTombstone && node.type == .stringInsert {
            attributedString.append(NSMutableAttributedString(string:String(node.unicodeScalar)))
            addressesArray.append(node.operationID())
        }

        let children = (node.childOperations?.allObjects as! [CDOperation]).sorted(by: >)
        for child in children {
            let childString = stringFromRGATreeNode(node: child)
            attributedString.append(childString.0)
            addressesArray.append(contentsOf: childString.1)
        }
        return (attributedString, addressesArray)
    }
}

