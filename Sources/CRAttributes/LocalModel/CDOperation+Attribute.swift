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
    func updateObject(from protoForm: ProtoAttributeOperation, container: CDOperation?) {
        print("From protobuf AttributeOp(\(protoForm.id.lamport))")
        let context = managedObjectContext!
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
        }
        
        for protoItem in protoForm.lwwOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .lwwInt)
        }

        protoForm.stringInsertOperationsList.restore(context: context, container: self)
    }
}


// MARK: - String related
extension CDOperation {
    
    public func stringFromRGAList() -> (NSMutableAttributedString, [CROperationID]) {
        let context = managedObjectContext!

        let attributedString = NSMutableAttributedString(string:"")
        var addressesArray:[CROperationID] = []

        context.performAndWait {
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
        }
        return (attributedString, addressesArray)
    }
    
    public func stringFromRGATree() -> (NSMutableAttributedString, [CROperationID]) {
        let context = managedObjectContext!

        var result:(NSMutableAttributedString, [CROperationID])?
        context.performAndWait {
            // let's prefetch
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == %@", self)
            let _ = try! context.fetch(request)

            // the head is the attribute operation for strings
            let head:CDOperation? = self

            guard let head = head else {
                result = (NSMutableAttributedString(string:""), [])
                return
            }
            result = stringFromRGATreeNode(node: head)
        }
        return result!
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
    
    func printRGADebug() {
        print("rga form debug:")
        let context = managedObjectContext!
        context.performAndWait {
            assert(type == .attribute)
            assert(attributeType == .mutableString)

            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()

            // the head is the attribute operation for strings
            let head:CDOperation? = self

            // build the attributedString
            var string = ""
            var node:CDOperation? = head
            node = node?.next // let's skip the head
            while node != nil {
                if node!.hasTombstone == false {
                    let contribution = String(Character(node!.unicodeScalar))
                    string.append(contribution)
                }
                node = node!.next
            }
            print(" str: \(string)")
                    
            print(" tree:")
            head?.printRGATree(intention:2)
            print(" orphaned:")
            request.predicate = NSPredicate(format: "container == %@ and parent == nil", argumentArray: [self])
            let response = try! context.fetch(request)
            for op in response {
                op.printRGATree(intention: 2)
            }
        }
    }
    
    func printRGATree(intention: Int) {
        print(String(repeating: " ", count: intention) + "[\(lamport)]: '\(unicodeScalar)' prev:\(String(describing: prev?.lamport)) next:\(String(describing: next?.lamport)) type:\(type) state:\(state) del:\(hasTombstone)")
        for op in self.childOperations?.allObjects as? [CDOperation] ?? [] {
            op.printRGATree(intention: intention+1)
        }
    }
}

extension CDOperation {
    func protoAttributeOperationRecurse() -> ProtoAttributeOperation {
        assert(self.type == .attribute)
        var proto = ProtoAttributeOperation.with {
            $0.version = self.version
            $0.id.lamport = self.lamport
            $0.id.peerID  = self.peerID.data
            $0.name = self.attributeName!
            $0.rawType = self.rawAttributeType
        }
        
        var headStringOperation:CDOperation? = nil
        
        for operation in self.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(operation.protoDeleteOperationRecurse())
                case .lwwInt:
                    proto.lwwOperations.append(operation.protoLWWOperationRecurse())
                case .lwwFloat:
                    proto.lwwOperations.append(operation.protoLWWOperationRecurse())
                case .lwwDate:
                    proto.lwwOperations.append(operation.protoLWWOperationRecurse())
                case .lwwBool:
                    proto.lwwOperations.append(operation.protoLWWOperationRecurse())
                case .lwwString:
                    proto.lwwOperations.append(operation.protoLWWOperationRecurse())
                case .stringInsert:
                    if operation.prev == nil { // it will be only a new string in a new attribute in this scenario
                        headStringOperation = operation
                    }
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        var node = headStringOperation
        while node != nil {
            if let protoForm = node!.protoStringInsertOperationRecurse() {
                proto.stringInsertOperationsList.stringInsertOperations.append(protoForm)
            }
            node = node!.next
        }
        self.state = .processed
        return proto
    }
}
