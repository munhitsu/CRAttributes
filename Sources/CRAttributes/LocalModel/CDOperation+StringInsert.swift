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
            print("linking: \(self.shortDescrption())")
            print("rga for self (pre):")
            self.printRGATree(intention: 2)

            guard type == .stringInsert else { fatalError() }
            
            if parent == nil {
                let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)
                let newParent = CDOperation.findOperationOrCreateGhost(from: parentAddress, in: context)
                assert(newParent.assertIfWithChildrenThenNextWithin())
                parent = newParent
            }
            guard let parent = parent else { fatalError() }
            assert(assertIfWithChildrenThenNextWithin())
            
            print("rga for parent (pre):")
            parent.printRGATree(intention: 2)
            
            // this will include self, but w/o left/right link
            let children:[CDOperation] = (parent.childOperations?.allObjects as? [CDOperation] ?? []).filter{$0.type == .stringInsert}.sorted(by: >)

            print("children of parent:")
            for child in children {
                print("  \(child.shortDescrption())")
            }

            var lastNode = self
            while lastNode.next != nil {
//                print("lastNode.next")
                lastNode = lastNode.next!
                if lastNode == self {
                    container!.printRGADebug()
                    assert(false)
                }
            }
            
            if parent.next == nil {
//                print("1st time parent shortcut")
                parent.next = self
                assert(assertIfWithChildrenThenNextWithin())
                return
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
            var childrenIterator = children.makeIterator()
            
            while let op = childrenIterator.next() {
                if op == self {
                    break
                }
                prevOp = op
            }
            if let nextOp:CDOperation = childrenIterator.next() {
//                print("has nextOp: \(nextOp.shortDescrption())")
                // so we have prevOp, self, nextOp? (all being siblings)
                assert(assertIfWithChildrenThenNextWithin())
                let nextOpPrev = nextOp.prev
                assert(assertIfWithChildrenThenNextWithin())
                nextOp.prev = lastNode
                assert(assertIfWithChildrenThenNextWithin())
                self.prev = nextOpPrev
                assert(assertIfWithChildrenThenNextWithin())
            } else {
//                print("no nextOp")
                // so we have prevOp, self and prevOp.lastNode(ignoring: self)
                print("prevOp: \(prevOp.shortDescrption())")
                let prevOpLast = prevOp.lastNode(ignoring: self)
                print("prevOpLast: \(prevOpLast.shortDescrption())")
                let lastOpNext = prevOpLast.next
                print("lastOpNext: \(lastOpNext?.shortDescrption())")
                assert(assertIfWithChildrenThenNextWithin())
                prevOpLast.next = self
                assert(assertIfWithChildrenThenNextWithin())
                lastNode.next = lastOpNext
                assert(assertIfWithChildrenThenNextWithin())
            }
//
            let listString = container!.stringFromRGAList()
            let treeString = container!.stringFromRGATree()
//    
//            if listString.0 != treeString.0 {
//                print("listString: \(listString.0)")
//                print("treeString: \(treeString.0)")
//                print("was linking: \(self.shortDescrption())")
//            }
            assert(listString.0 == treeString.0)

            print("rga for parent (post): ")
            parent.printRGATree(intention: 2)
            print("rga for self (post): ")
            self.printRGATree(intention: 2)
            assert(assertIfWithChildrenThenNextWithin())
            assert(parent.assertIfWithChildrenThenNextWithin())
        }
    }
    /**
     if this node is a start of a branch, then where is the end?
     */
    func lastNode(ignoring: CDOperation? = nil) -> CDOperation {
        var childrenStack = (childOperations?.allObjects as! [CDOperation]).filter{$0.type == .stringInsert}.sorted(by: >)
        var lastChild = childrenStack.popLast()
        
        if lastChild == nil {
            return self
        }
        if lastChild == ignoring {
            lastChild = childrenStack.popLast()
        }
        if lastChild == nil {
            return self
        }
        return lastChild!.lastNode()
    }
    
    func debugListString() -> String {
        var node:CDOperation = self
        var s = ""
        while node.next != nil {
            s.append(contentsOf: String(node.unicodeScalar))
            node = node.next!
        }
        return s
    }
    
    func debugTreeString() -> String {
        var s = "\(unicodeScalar)"
        let children:[CDOperation] = (childOperations?.allObjects as? [CDOperation] ?? []).filter{$0.type == .stringInsert}.sorted(by: >)
        for child in children {
            s.append(contentsOf: child.debugTreeString())
        }
        return s
    }
    
    func assertIfWithChildrenThenNextWithin() -> Bool {
        let children:[CDOperation] = (childOperations?.allObjects as? [CDOperation] ?? []).filter{$0.type == .stringInsert}
        if children.count > 0 {
            for child in children {
                if child == self.next {
                    return true
                }
            }
            return false
        }
        return true
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
