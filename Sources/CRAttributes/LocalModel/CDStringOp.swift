//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData

@objc(CDStringOp)
public class CDStringOp: CDAbstractOp {

}


extension CDStringOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDStringOp> {
        return NSFetchRequest<CDStringOp>(entityName: "CDStringOp")
    }

    @NSManaged public var parentLamport: Int64
    @NSManaged public var parentPeerID: UUID
    @NSManaged public var insertContribution: Int32
    @NSManaged public var parent: CDStringOp?
    @NSManaged public var childOperations: NSSet?

    @NSManaged public var next: CDStringOp?
    @NSManaged public var prev: CDStringOp?

    @NSManaged public var rawType: Int32
}

enum CDStringOpType: Int32 {
    case head = 0
    case insert = 1
    case delete = 2
}


extension CDStringOp {
    var type: CDStringOpType {
        get {
            return CDStringOpType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
    
    var unicodeScalar: UnicodeScalar {
        get {
            UnicodeScalar(UInt32(insertContribution))!
        }
        set {
            insertContribution = Int32(newValue.value) // there will be loss in UInt32 to Int32 conversion eventually
        }
    }
}


extension CDStringOp {
    

    convenience init(context: NSManagedObjectContext, container: CDAttributeOp?, parent: CDStringOp?, contribution: UnicodeScalar = UnicodeScalar(0), type: CDStringOpType, state: CDOpState) {
        self.init(context:context, container: container)
        self.unicodeScalar = contribution
        self.parent = parent
        self.type = type
        self.state = state
    }

    convenience init(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CROperationID, contribution: UnicodeScalar = UnicodeScalar(0), type: CDStringOpType, state: CDOpState) {
        self.init(context:context, container: container)
        self.parentLamport = parentAddress.lamport
        self.parentPeerID = parentAddress.peerID
        self.unicodeScalar = contribution
        self.parent = parent
        self.type = type
        self.state = state
    }

    
//    convenience init(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: unichar) {
//        self.init(context:context, container: container)
//        var uc = contribution
//        self.contribution = NSString(characters: &uc, length: 1) as String //TODO: migrate to init(utf16CodeUnits: UnsafePointer<unichar>, count: Int)
//        self.parent = parent
//    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoStringInsertOperation, container: CDAbstractOp?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.insertContribution = protoForm.contribution
        self.parent = CDStringOp.fetchOperation(from: protoForm.parentID, in: context) as? CDStringOp // will be null if parent is not yet with us
        self.container = container
        self.state = .inDownstreamQueueMergedUnrendered


        for protoItem in protoForm.deleteOperations {
            _ = CDDeleteOp(context: context, from: protoItem, container: self)
        }
        
    }
    
    /**
     does not save
     returns if linking was yet possible
     */
    func linkMe(context: NSManagedObjectContext) -> Bool {
        let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)

        guard let container = container else { return false }
        guard let parentOp = CDStringOp.fromStringAddress(context: context, address: parentAddress, container: container) else {
            return false
        }
//        print("pre:")
//        print("parent: '\(parentOp.unicodeScalar)' \(parentOp.lamport): parent:\(parentOp.parent?.lamport) prev:\(parentOp.prev?.lamport) next:\(parentOp.next?.lamport)")
//        print("self: '\(unicodeScalar)' \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
//
//        assert(parentOp.managedObjectContext == self.managedObjectContext)
        
        
    mainSwitch: switch self.type {
        case .head:
            break
        case .insert:
            let children = (parentOp.childOperations?.allObjects as! [CDStringOp]).sorted(by: >)
            self.parent = parentOp
        
            var lastNode = self
            while lastNode.next != nil {
                lastNode = lastNode.next!
            }


            // if no children then insert after parent
            if children.count == 0 {
                let parentNext = parent?.next
                assert(parent != self)

                self.parent?.next = self
                lastNode.next = parentNext

                assert(self.prev == parent)
                assert(self.parent?.next == self)
                break mainSwitch
            }
            
            // let's insert before the 1st older op
            for op: CDStringOp in children {
                if self > op && op.state != .inUpstreamQueueRendered {
                    let opPrev = op.prev
                    self.prev = opPrev
                    op.prev = lastNode
                    break mainSwitch
                }
            }

            
            let lastChildNode = children.last!.lastNode()
            let lastChildNodeNext = lastChildNode.next
            lastChildNode.next = self
            lastNode.next = lastChildNodeNext

        case .delete:
            parentOp.hasTombstone = true
            self.parent = parentOp
        }

//        print("post:")
//        print("parent: '\(parent?.unicodeScalar)' \(parent!.lamport): parent:\(parent!.parent?.lamport) prev:\(parent!.prev?.lamport) next:\(parent!.next?.lamport)")
//        print("self: '\(unicodeScalar)' \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
        
        switch state {
        case .inUpstreamQueueRendered:
            state = .inUpstreamQueueRenderedMerged
        case .inDownstreamQueueMergedUnrendered:
            state = .processed
        default:
            fatalNotImplemented()
        }
//        printRGADebug(context: context)
        
//        guard let container = container as? CDAttributeOp else {
//            fatalNotImplemented()
//            return false
//        }
//        let listString = container.stringFromRGAList(context: context)
//        let treeString = container.stringFromRGATree(context: context)
//
//        assert(listString.0 == treeString.0)
        
        return true
    }
    
    func printRGADebug(context: NSManagedObjectContext) {
        print("rga form debug:")

        // let's get the first operation
        let request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == 0", argumentArray: [container!]) // select head
        var response = try! context.fetch(request)
        assert(response.count == 1)
        let head:CDStringOp? = response.first

        // build the attributedString
        var string = ""
        var node:CDStringOp? = head
        node = node?.next // let's skip the head
        while node != nil {
            assert(head!.container == node!.container)
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
        request.predicate = NSPredicate(format: "container == %@ and parent == nil", argumentArray: [container!])
        response = try! context.fetch(request)
        for op in response {
            if op.type != .head {
                op.printRGATree(intention: 2)
            }
        }
    }
    
    func printRGATree(intention: Int) {
        print(String(repeating: " ", count: intention) + "[\(lamport)]: '\(unicodeScalar)' prev:\(prev?.lamport) next:\(next?.lamport) state:\(state)")
        for op in self.childOperations?.allObjects as? [CDStringOp] ?? [] {
            op.printRGATree(intention: intention+1)
        }
    }
    
    func lastNode() -> CDStringOp {
        guard let lastChild = (childOperations?.allObjects as! [CDStringOp]).sorted(by: >).last else {
            return self
        }
        return lastChild.lastNode()
    }
    
    static func restoreLinkedList(context: NSManagedObjectContext, from: [ProtoStringInsertOperation], container: CDAttributeOp?) -> CDStringOp {
        var cdOperations:[CDStringOp] = []
        var prevOp:CDStringOp? = nil
        for protoOp in from {
            let op = CDStringOp(context: context, from: protoOp, container: container)
            cdOperations.append(op)
            op.prev = prevOp
            prevOp?.next = op
            prevOp = op
        }
        return cdOperations[0]
    }
    
    static func fromStringAddress(context: NSManagedObjectContext, address: CROperationID, container: CDAbstractOp) -> CDStringOp? {
        let request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "lamport == %@ and peerID == %@ and container == %@", argumentArray: [address.lamport, address.peerID, container])
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

}
