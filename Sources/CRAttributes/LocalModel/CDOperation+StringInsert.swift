//
//  CDOperation+String.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData


extension CDOperation { // StringInsert

    static func createStringInsert(context: NSManagedObjectContext, container: CDOperation?, parent: CDOperation?, contribution: UnicodeScalar = UnicodeScalar(0)) -> CDOperation  {
        let op = CDOperation(context:context, container: container)
        op.parent = parent
        op.unicodeScalar = UnicodeScalar(0)
        op.type = .stringInsert
        op.state = .inUpstreamQueueRendered
        op.stringInsertContribution = Int32(contribution.value) //TODO: we need a nice reversible casting of uint32 to int32
        return op
    }

    static func createStringInsert(context: NSManagedObjectContext, container: CDOperation?, parentID: CROperationID, contribution: UnicodeScalar = UnicodeScalar(0)) -> CDOperation  {
        let op = CDOperation(context:context, container: container)
        op.parentLamport = parentID.lamport
        op.parentPeerID = parentID.peerID
        op.unicodeScalar = UnicodeScalar(0)
        op.type = .stringInsert
        op.state = .inUpstreamQueueRendered
        op.stringInsertContribution = Int32(contribution.value) //TODO: we need a nice reversible casting of uint32 to int32
        return op
    }

    func updateObject(from protoForm: ProtoStringInsertOperation, container: CDOperation?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
        let context = managedObjectContext!
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.stringInsertContribution = protoForm.contribution
        self.parent = CDOperation.findOperationOrCreateGhost(from: protoForm.parentID, in: context)
        self.container = container
        self.type = .stringInsert
        self.state = .inDownstreamQueue

        
        for protoItem in protoForm.deleteOperations {
            _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: container, type: .delete)
        }
    }
    
    /**
     does not save
     returns if linking was yet possible
     */
    func stringInsertLinking() {
        let context = managedObjectContext!
        context.performAndWait {
            guard type == .stringInsert else { fatalError() }
            if parent == nil {
                let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)
                parent = CDOperation.findOperationOrCreateGhost(from: parentAddress, in: context)
            }
            guard let parent = parent else { fatalError() }
             
            
//            print("linking:")
//            print("pre:")
//            print("parent: \(parent.shortDescrption())")
//            print("parent: '\(parent.unicodeScalar)' \(parent.lamport): prev:\(String(describing: parent.prev?.lamport)) next:\(String(describing: parent.next?.lamport)) ")
//            print("self: \(shortDescrption())")
//            print("self: '\(unicodeScalar)' \(lamport): parent:\(parent.lamport) prev:\(String(describing: prev?.lamport)) next:\(String(describing: next?.lamport))")
            
            // this will include self, but w/o left/right link
            let children:[CDOperation] = (parent.childOperations?.allObjects as? [CDOperation] ?? []).filter{$0.type == .stringInsert}.sorted(by: >)
        
            var lastNode = self 
            while lastNode.next != nil {
//                print("lastNode.next")
                lastNode = lastNode.next!
                if lastNode == self {
                    container!.printRGADebug()
                    assert(false)
                }
            }

            
    //        if children.count == 1 { // if just one children then it's me so we insert after parent
    //            let parentNext = parent.next
    //            assert(parent != self)
    //
    //            self.parent?.next = self
    //            lastNode.next = parentNext
    //
    //            assert(self.prev == parent)
    //            assert(self.parent?.next == self)
    //        } else { // multiple kids cases
                // let's insert before the 1st older op
                
                var prevOp:CDOperation = parent
                for op: CDOperation in children { //TODO: remove duplicate comparision as we are already at the right place in the array
                    
                    if op == self {
                        let prevNext = prevOp.next
                        prevOp.next = self
                        lastNode.next = prevNext
                        break
                    }
                    prevOp = op
                }
    //        }


    //        print("post:")
    //        print("parent: '\(parent?.unicodeScalar)' \(parent!.lamport): parent:\(parent!.parent?.lamport) prev:\(parent!.prev?.lamport) next:\(parent!.next?.lamport)")
    //        print("self: '\(unicodeScalar)' \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
            
    //        printRGADebug(context: context)
            
    //        guard let container = container as? CDAttributeOp else {
    //            fatalNotImplemented()
    //            return false
    //        }
    //        let listString = container.stringFromRGAList(context: context)
    //        let treeString = container.stringFromRGATree(context: context)
    //
    //        assert(listString.0 == treeString.0)
        }
    }
    /**
     if this node is a start of a branch, then where is the end?
     */
    func lastNode() -> CDOperation {
        guard let lastChild = (childOperations?.allObjects as! [CDOperation]).sorted(by: >).last else {
            return self
        }
        return lastChild.lastNode()
    }
    
}

extension CDOperation {
    // returns a list of linked string operations (including deletes as sub operations)
    func protoStringInsertOperationsLinkedList() -> [ProtoStringInsertOperation] {
        assert(self.state == .inUpstreamQueueRenderedMerged)
        
        var protoOperations:[ProtoStringInsertOperation] = []
        if let protoForm = self.protoStringInsertOperationRecurse() {
            protoOperations.append(protoForm)
        }
        
        // going left
        var node:CDOperation? = self.prev
        while node != nil && node!.state == .inUpstreamQueueRenderedMerged && node!.type == .stringInsert{
            if let protoForm = node!.protoStringInsertOperationRecurse() {
                protoOperations.insert(protoForm, at: 0)
            }
            node = node?.prev
        }
        
        // going right
        node = self.next
        while node != nil && node!.state == .inUpstreamQueueRenderedMerged && node!.type == .stringInsert {
            if let protoForm = node!.protoStringInsertOperationRecurse() {
                protoOperations.append(protoForm)
            }
            node = node?.next
        }
        return protoOperations
    }

    func protoStringInsertOperationRecurse() -> ProtoStringInsertOperation? {
        var proto = ProtoStringInsertOperation.with {
            $0.version = self.version
            $0.id.lamport = self.lamport
            $0.id.peerID  = self.peerID.data
            $0.contribution = self.stringInsertContribution
            $0.parentID.lamport = self.parent?.lamport ?? 0
            $0.parentID.peerID = self.parent?.peerID.data ?? UUID.zero.data
        }

        for operation in self.childOperations?.allObjects ?? [] {
            guard let operation = operation as? CDOperation else { continue }
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(operation.protoDeleteOperationRecurse())
                case .stringInsert:
                    break // we can ignore it as it will be picked up by .next
                default:
                    print(operation)
                    fatalError("unsupported subOperation")
                }
            }
        }
        self.state = .processed
        return proto
    }
}
