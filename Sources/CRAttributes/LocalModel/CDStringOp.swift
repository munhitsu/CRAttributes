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

    @NSManaged public var rawState: Int32
    @NSManaged public var rawType: Int32
}


enum CDStringOpState: Int32 {
    case unknown = 0 // should never happen
    case inUpstreamQueueRendered = 1 // waiting to convert ID to references (linked/merged), waiting to be added for synchronisation, but rendered
    case inUpstreamQueueRenderedMerged = 2 // merged, rendered, waiting for synchronisation
    case inDownstreamQueueMergedUnrendered = 16 // merged but not yet rendered
    case processed = 128 // rendered, merged, synced
}

enum CDStringOpType: Int32 {
    case head = 0
    case insert = 1
    case delete = 2
}


extension CDStringOp {
    var state: CDStringOpState {
        get {
            return CDStringOpState(rawValue: self.rawState)!
        }
        set {
            self.rawState = newValue.rawValue
        }
    }
    
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
    

    convenience init(context: NSManagedObjectContext, container: CDAttributeOp?, parent: CDStringOp?, contribution: UnicodeScalar = UnicodeScalar(0), type: CDStringOpType, state: CDStringOpState) {
        self.init(context:context, container: container)
        self.unicodeScalar = contribution
        self.parent = parent
        self.type = type
        self.state = state
    }

    convenience init(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CROperationID, contribution: UnicodeScalar = UnicodeScalar(0), type: CDStringOpType, state: CDStringOpState) {
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
        self.parent = CDStringOp.operation(from: protoForm.parentID, in: context) as? CDStringOp // will be null if parent is not yet with us
        self.container = container
        self.upstreamQueueOperation = false


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
//        if parentAddress.isZero() {
//            //TODO: fix multiple inserts at the start
//            return true
//        }
        guard let container = container else { return false }
        guard let parentOp = CDStringOp.fromStringAddress(context: context, address: parentAddress, container: container) else {
            return false
        }
        print("parent: \(parentOp)")
        assert(parentOp.managedObjectContext == self.managedObjectContext)
        
    mainSwitch: switch self.type {
        case .head:
            return true
        case .insert:
            let children = (parentOp.childOperations?.allObjects as! [CDStringOp]).sorted(by: >)
            self.parent = parentOp

            // if no children then insert after parent
            if children.count == 0 {
                let parentNext = parent?.next
                print("parent: \(parent?.lamport): parent:\(parent?.parent?.lamport) prev:\(parent?.prev?.lamport) next:\(parent?.next?.lamport)")
                print("self: \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
                self.prev = parent
                print("self: \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
                self.next = parent?.next

//                self.next = parentNext // it's weird that I can't just: self.next = parent?.next
                print("self: \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
                parent?.next = self
                print("parent: \(parent?.lamport): parent:\(parent?.parent?.lamport) prev:\(parent?.prev?.lamport) next:\(parent?.next?.lamport)")
                print("self: \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
                break mainSwitch
            }
            
            // let's insert before the 1st older op
            for op: CDStringOp in children {
                if self > op {
                    self.prev = op.prev
                    self.next = op
                    op.prev = self
                    break mainSwitch
                }
            }
            // let's append after the last
            let lastChild = children.last
            self.prev = lastChild
            self.next = lastChild?.next
            lastChild?.next = self
            self.parent = parentOp
        case .delete:
            parentOp.hasTombstone = true
            self.parent = parentOp
        }

        print("parent: \(parent?.lamport): parent:\(parent?.parent?.lamport) prev:\(parent?.prev?.lamport) next:\(parent?.next?.lamport)")
        print("self: \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
        
        printRGADebug(context: context)
        return true
    }
    
    func printRGADebug(context: NSManagedObjectContext) {
        print("rga form debug:")

        // let's get the first operation
        let request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == 0", argumentArray: [container!])
        var response = try! context.fetch(request)
        assert(response.count == 1)
        let head:CDStringOp? = response.first

        // build the attributedString
        var string = ""
        var node:CDStringOp? = head
        node = node?.next // let's skip the head
        while node != nil {
            if node!.hasTombstone == false {
                let contribution = String(Character(node!.unicodeScalar))
                string.append(contribution)
            }
            node = node!.next
        }
        print(" str: \(string)")
        
        request.predicate = NSPredicate(format: "container == %@", argumentArray: [container!])
        response = try! context.fetch(request)
        for op in response {
            print(" op: \(op.lamport): parent:\(op.parent?.lamport) prev:\(op.prev?.lamport) next:\(op.next?.lamport)")
        }
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


//    private func markDeleted() {
//        let _ = CDStringOp.initDelete(context: context, container: self, parentAddress: <#T##CRStringAddress#>, length: <#T##Int32#>)
//        let _ = CDDeleteOp(context: context, container: operation)
//        self.hasTombstone = true
//    }
//
//    func protoOperation() -> ProtoStringInsertOperation {
//        return ProtoStringInsertOperation.with {
//            $0.base = super.protoOperation()
//            $0.contribution = contribution
//        }
//    }
}
