//
//  CDOperation+String.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData


extension CDOperation {
    static func createStringInsert(context: NSManagedObjectContext, container: CDOperation?, parentAddress: CROperationID, contribution: UnicodeScalar = UnicodeScalar(0)) -> CDOperation  {
        let op = CDOperation(context:context, container: container)
        op.parentLamport = parentAddress.lamport
        op.parentPeerID = parentAddress.peerID
        op.unicodeScalar = UnicodeScalar(0)
        op.type = .stringInsert
        op.state = .inUpstreamQueueRendered
        op.stringInsertContribution = Int32(contribution.value) //TODO: we need a nice reversible casting of uint32 to int32
        return op
    }

    
//    convenience init(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: unichar) {
//        self.init(context:context, container: container)
//        var uc = contribution
//        self.contribution = NSString(characters: &uc, length: 1) as String //TODO: migrate to init(utf16CodeUnits: UnsafePointer<unichar>, count: Int)
//        self.parent = parent
//    }

    func updateObject(context: NSManagedObjectContext, from protoForm: ProtoStringInsertOperation, container: CDOperation?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
//        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.stringInsertContribution = protoForm.contribution
        self.parent = CDOperation.findOperationOrCreateGhost(from: protoForm.parentID, in: context)
        self.container = container
        self.type = .stringInsert
        self.state = .inDownstreamQueue

        for protoItem in protoForm.deleteOperations {
            _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .delete)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
    }
    
    /**
     does not save
     returns if linking was yet possible
     */
    func stringInsertLinking(context: NSManagedObjectContext) {
        guard type == .stringInsert else { fatalError() }
        if parent == nil {
            let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)
            parent = CDOperation.findOperationOrCreateGhost(from: parentAddress, in: context)
        }
        guard let parent = parent else { fatalError() }
        
        
        print("linking:")
        print("pre:")
        print("parent: \(parent.shortDescrption())")
        print("parent: '\(parent.unicodeScalar)' \(parent.lamport): prev:\(String(describing: parent.prev?.lamport)) next:\(String(describing: parent.next?.lamport)) ")
        print("self: \(shortDescrption())")
        print("self: '\(unicodeScalar)' \(lamport): parent:\(parent.lamport) prev:\(String(describing: prev?.lamport)) next:\(String(describing: next?.lamport))")

        assert(parent.managedObjectContext == self.managedObjectContext)
        
        
        // this will include self, but w/o left/right link
        let children:[CDOperation] = (parent.childOperations?.allObjects as? [CDOperation] ?? []).sorted(by: >)
    
        var lastNode = self
        while lastNode.next != nil {
            lastNode = lastNode.next!
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
    
    func printRGADebug(context: NSManagedObjectContext) {
        print("rga form debug:")
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
    
    func printRGATree(intention: Int) {
        print(String(repeating: " ", count: intention) + "[\(lamport)]: '\(unicodeScalar)' prev:\(String(describing: prev?.lamport)) next:\(String(describing: next?.lamport)) type:\(type) state:\(state)")
        for op in self.childOperations?.allObjects as? [CDOperation] ?? [] {
            op.printRGATree(intention: intention+1)
        }
    }
    
    func lastNode() -> CDOperation {
        guard let lastChild = (childOperations?.allObjects as! [CDOperation]).sorted(by: >).last else {
            return self
        }
        return lastChild.lastNode()
    }
    
    static func restoreLinkedList(context: NSManagedObjectContext, from: [ProtoStringInsertOperation], container: CDOperation?) -> CDOperation {
        var cdOperations:[CDOperation] = []
        var prevOp:CDOperation? = nil
        for protoOp in from {
            let op = CDOperation.findOrCreateOperation(context: context, from: protoOp, container: container, type: .stringInsert)
//            let op = CDOperation(context: context, from: protoOp, container: container)
            cdOperations.append(op)
            op.prev = prevOp
            prevOp?.next = op
            prevOp = op
        }
        return cdOperations[0]
    }
    
}

