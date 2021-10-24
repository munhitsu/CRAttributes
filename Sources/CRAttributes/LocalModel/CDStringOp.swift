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
    case inUpstreamQueueRendered = 1 // waiting to convert ID to references, to be added for synchronisation, but rendered
    case downstreamUnrendered = 2 // linked but not yet rendered
    case processed = 128 // rendered, linked, synced
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
}


extension CDStringOp {
    
    public static func initInsert(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: String, offset: Int32 = 0) {
        
    }
    
    public static func initDelete(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CRStringAddress, length: Int32) -> CDStringOp {
        let op = CDStringOp(context:context, container: container)
        op.parentLamport = parentAddress.lamport
        op.parentPeerID = parentAddress.peerID
        op.parentOffset = parentAddress.offset
        op.deletedLength = length
        op.type = .delete
        return op
    }
    
    public static func initInsert(context: NSManagedObjectContext, container: CDAttributeOp?, parentAddress: CRStringAddress, contribution: String) -> CDStringOp {
        let op = CDStringOp(context:context, container: container)
        op.parentLamport = parentAddress.lamport
        op.parentPeerID = parentAddress.peerID
        op.parentOffset = parentAddress.offset
        op.offset = 0
        op.insertContribution = contribution
        op.type = .insert
        return op
    }
    
    convenience init(context: NSManagedObjectContext, parent: CDStringOp?, container: CDAttributeOp?, contribution: String, offset: Int32 = 0) {
        self.init(context:context, container: container)
        self.insertContribution = contribution
        self.offset = offset
        self.parent = parent
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
    
    func opProxy() -> CDStringOpProxy {
        return CDStringOpProxy(context: managedObjectContext!, object: self)
    }
//    func protoOperation() -> ProtoStringInsertOperation {
//        return ProtoStringInsertOperation.with {
//            $0.base = super.protoOperation()
//            $0.contribution = contribution
//        }
//    }
}
