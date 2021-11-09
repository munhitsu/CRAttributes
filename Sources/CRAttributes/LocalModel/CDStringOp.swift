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
    @NSManaged public var parentOffset: Int32
    @NSManaged public var offset: Int32
    @NSManaged public var insertContribution: String
    @NSManaged public var deletedLength: Int32
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
    case insert = 0
    case delete = 1
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
    
    var isDerived: Bool {
        self.offset != 0
    }
}


extension CDStringOp {
    
//    public static func initInsert(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: String, offset: Int32 = 0) {
//
//    }
    
    public static func initDelete(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CRStringAddress, length: Int32) -> CDStringOp {
        let op = CDStringOp(context:context, container: container)
        op.parentLamport = parentAddress.lamport
        op.parentPeerID = parentAddress.peerID
        op.parentOffset = parentAddress.offset
        op.deletedLength = length
        op.type = .delete
        return op
    }
    
    public static func initInsert(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CRStringAddress, contribution: String, offset: Int32 = 0) -> CDStringOp {
        let op = CDStringOp(context:context, container: container)
        op.parentLamport = parentAddress.lamport
        op.parentPeerID = parentAddress.peerID
        op.parentOffset = parentAddress.offset
        op.offset = 0
        op.insertContribution = contribution
        op.type = .insert
        return op
    }
    
    public static func initInsert(context: NSManagedObjectContext, container: CDAttributeOp?, parent: CDStringOp?, contribution: String, offset: Int32 = 0) -> CDStringOp {
        let op = CDStringOp(context:context, container: container)
        op.parent = parent
        op.offset = offset
        op.insertContribution = contribution
        op.type = .insert
        return op
    }

    
//    convenience init(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: String, offset: Int32 = 0) {
//        self.init(context:context, container: container)
//        self.insertContribution = contribution
//        self.offset = offset
//        self.parent = parent
//    }
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

    func stringAddress() -> CRStringAddress {
        //TODO: cache me
        return CRStringAddress(lamport: self.lamport, peerID: self.peerID, offset: self.offset)
    }
    
    
    /**
        returns operation that will be previous to the position
        when required it will cut the string
     */
    static func insertionOpFor(operationID: CROperationID, position: Int32) {
        
    }
    
    
    func fromStringAddress(context: NSManagedObjectContext, address: CRStringAddress) -> CDStringOp {
        let request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "lamport == %@ and peerId == %@", argumentArray: [address.lamport, address.peerID, address.offset])
        request.sortDescriptors = [NSSortDescriptor(key: "offset", ascending: true)]
        let ops = (try? context.fetch(request) as [CDStringOp]) ?? []

        var originOp: CDStringOp?
        var nodeToSplit: CDStringOp?
        for op in ops {
            switch op.offset {
            case address.offset:
                return op
            case 0:
                originOp = op
                nodeToSplit = op
            case < address.offset:
                
            default:
                continue
            }
        }
        // we need to split the node - find - the last node to split !!!!!!!!!!
        
        let op = originOp?.splitNodeAt(context: context, offset: address.offset)
        return op
    }
    
    func opProxy() -> CDStringOpProxy {
        return CDStringOpProxy(context: managedObjectContext!, object: self)
    }
    
    /**
    does not save
     */
    func splitNodeAt(context: NSManagedObjectContext, offset nextOffset: Int32) -> CDStringOp? {
        //TODO: ERROR - it should walk over all nodes in the op
        
        let newLength: Int = Int(nextOffset - offset)
        guard newLength > 0 else { return nil }
        guard newLength < insertContribution.count else { return nil }
        
        
        let str0End = insertContribution.index(insertContribution.startIndex, offsetBy: newLength)
        let prevContribution = String(insertContribution[..<str0End])
        let nextContribution = String(insertContribution[str0End...])
        self.insertContribution = prevContribution
        let nextOp = CDStringOp.initInsert(context: context, container: (self.container as! CDAttributeOp), parent: self.parent, contribution: nextContribution, offset: nextOffset)
        nextOp.next = self.next
        nextOp.prev = self
        self.next = nextOp
        if self.hasTombstone {
            next?.hasTombstone = true
            // we are not creating extra delete op as there is no use for it ATM and will complicate sync
            // attribute is enough
        }
        return nextOp
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
