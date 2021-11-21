//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf

@objc(CDAbstractOp)
public class CDAbstractOp: NSManagedObject {
}

extension CDAbstractOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAbstractOp> {
        return NSFetchRequest<CDAbstractOp>(entityName: "CDAbstractOp")
    }

//    @nonobjc public static func containedOperationsFetchRequest() -> NSFetchRequest<NSFetchRequestResult> {
//        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDAbstractOp")
//        request.predicate = NSPredicate(format: "container == $FETCH_SOURCE")
//        return request
//    }
        
    @NSManaged public var version: Int32
    @NSManaged public var lamport: Int64
    @NSManaged public var peerID: UUID
    @NSManaged public var hasTombstone: Bool
    
    @NSManaged public var container: CDAbstractOp?
//    @available(*, deprecated, message: "will be removed")
//    @NSManaged public var containedOperations: NSSet?

//    @NSManaged public var upstreamQueueOperation: Bool -> replaced with rawState == inUpstreamQueueRenderedMerged
    @NSManaged public var rawState: Int32

    @nonobjc public func containedOperations() -> [CDAbstractOp] {
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        request.predicate = NSPredicate(format: "container == %@", self)
        return try! self.managedObjectContext?.fetch(request) ?? []
    }
}

enum CDOpState: Int32 {
    case unknown = 0 // should never happen
    case inUpstreamQueueRendered = 1 // rendered, but waiting to convert ID to references (to link/merge), and waiting to be added for synchronisation
    case inUpstreamQueueRenderedMerged = 2 // merged, rendered, but waiting for synchronisation
    case inDownstreamQueueMergedUnrendered = 16 // merged, but not yet rendered
    case processed = 128 // rendered, merged, synced
}

extension CDAbstractOp {
    var state: CDOpState {
        get {
            return CDOpState(rawValue: self.rawState)!
        }
        set {
            self.rawState = newValue.rawValue
        }
    }
}


// MARK: Generated accessors for subOperations
//extension CDAbstractOp {
//
//    @objc(addContainedOperationsObject:)
//    @NSManaged public func addToContainedOperations(_ value: CDAbstractOp)
//
//    @objc(removeContainedOperationsObject:)
//    @NSManaged public func removeFromContainedOperations(_ value: CDAbstractOp)
//
//    @objc(addContainedOperations:)
//    @NSManaged public func addToContainedOperations(_ values: NSSet)
//
//    @objc(removeContainedOperations:)
//    @NSManaged public func removeFromContainedOperations(_ values: NSSet)
//
//}

extension CDAbstractOp : Identifiable {

}

extension CDAbstractOp : Comparable {
    public static func < (lhs: CDAbstractOp, rhs: CDAbstractOp) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }
    
    public static func == (lhs: CDAbstractOp, rhs: CDAbstractOp) -> Bool {
        return lhs.lamport == rhs.lamport && lhs.peerID == rhs.peerID
    }
}

extension CDAbstractOp {
    convenience init(context: NSManagedObjectContext, container: CDAbstractOp?) {
        self.init(context:context)
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.container = container
        self.hasTombstone = false
    }
    
    convenience init(context: NSManagedObjectContext, from: CROperationID) {
        self.init(context:context)
        self.lamport = from.lamport
        self.peerID = from.peerID
        self.container = nil
        self.hasTombstone = false
    }

    convenience init(context: NSManagedObjectContext, from: ProtoOperationID) {
        self.init(context:context)
        self.lamport = from.lamport
        self.peerID = from.peerID.object()
        self.container = nil
        self.hasTombstone = false
    }


//    convenience init(context: NSManagedObjectContext, proto:ProtoBaseOperation) {
//        self.init(context:context)
//        self.version = proto.version
//        self.lamport = proto.id.lamport
//        self.peerID = proto.id.peerID.object()
//        self.parent
//        self.attribute
    //  @objc   }
    
    func operationID() -> CROperationID {
        return CROperationID(lamport: lamport, peerID: peerID)
    }
    
    func protoOperationID() -> ProtoOperationID {
        return ProtoOperationID.with {
            $0.lamport = lamport
            $0.peerID = peerID.data
        }
    }
    
    static func upstreamWaitingOperations() -> [CDAbstractOp] {
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "upstreamQueue == true")
        return try! context.fetch(request)
    }

    static func operation(fromLamport:lamportType, fromPeerID:UUID, in context: NSManagedObjectContext) -> CDAbstractOp? {
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        request.predicate = NSPredicate(format: "lamport = %@ and peerID = %@", argumentArray: [fromLamport, fromPeerID])
        let ops = try? context.fetch(request)
        return ops?.first
    }

    static func operation(from protoID:ProtoOperationID, in context: NSManagedObjectContext) -> CDAbstractOp? {
        return operation(fromLamport: protoID.lamport, fromPeerID: protoID.peerID.object(), in: context)
    }

    static func operation(from operationID:CROperationID, in context: NSManagedObjectContext) -> CDAbstractOp? {
        return operation(fromLamport: operationID.lamport, fromPeerID: operationID.peerID, in: context)
    }

//    func protoOperation() -> ProtoBaseOperation {
//        return ProtoBaseOperation.with {
//            $0.version = version
//            $0.id = protoOperationID()
//            if let parent = parent { //TODO: implementation of null for message is language specific
//                $0.parentID = parent.protoOperationID()
//            }
//            if let attribute = attribute { //TODO: implementation of null for message is language specific
//                $0.attributeID = attribute.protoOperationID()
//            }
//        }
//    }
    
}
