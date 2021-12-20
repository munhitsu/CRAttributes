//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf


enum CRAttributeType: Int32 {
    case int = 0
    case float = 1
    case date = 2
    case boolean = 3
    case string = 4
    case mutableString = 5
}

enum CDOperationState: Int32 {
    case unknown = 0 // should never happen
    case inUpstreamQueueRendered = 1 // rendered, but waiting to convert ID to references (to link/merge), and waiting to be added for synchronisation
    case inUpstreamQueueRenderedMerged = 2 // merged, rendered, but waiting for synchronisation
    case inDownstreamQueue = 16 // merged, but not yet rendered
    case inDownstreamQueueMergedUnrendered = 17 // merged, but not yet rendered
    case processed = 128 // rendered, merged, synced
}

enum CDOperationType: Int32 {
    case ghost = 0
    case delete = 1
    case object = 2
    case attribute = 3 // attribute is a stringHead
    case lwwInt = 16
    case lwwFloat = 17
    case lwwBool = 18
    case lwwString = 19
    case lwwDate = 20

//    case stringHead = 32
    case stringInsert = 33
}

struct CRObjectType: RawRepresentable, Equatable, Hashable, Comparable {
    typealias RawValue = Int32
    
    var rawValue: Int32
    
    static let unknown = CRObjectType(rawValue: 0)
    
    var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func <(lhs: CRObjectType, rhs: CRObjectType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }

}

// example extansion of CRObjectType
extension CRObjectType {
    static let reserved = CRObjectType(rawValue: 1)
}


@objc(CDOperation)
public class CDOperation: NSManagedObject {

}

extension CDOperation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDOperation> {
        return NSFetchRequest<CDOperation>(entityName: "CDOperation")
    }
    @NSManaged public var version: Int32
    @NSManaged public var lamport: Int64
    @NSManaged public var peerID: UUID
    @NSManaged public var hasTombstone: Bool
    
    @NSManaged public var rawState: Int32
    @NSManaged public var rawType: Int32

    //Objecst
    @NSManaged public var rawObjectType: Int32

    //Attribute
    @NSManaged public var attributeName: String?
    @NSManaged public var rawAttributeType: Int32

    //lww
    @NSManaged public var lwwInt: Int64
    @NSManaged public var lwwFloat: Float
    @NSManaged public var lwwDate: Date?
    @NSManaged public var lwwBool: Bool
    @NSManaged public var lwwString: String?

    //StringInsert/Delete
    @NSManaged public var parentLamport: Int64
    @NSManaged public var parentPeerID: UUID
    @NSManaged public var stringInsertContribution: Int32
    
    
    @NSManaged public var container: CDOperation?
    @NSManaged public var parent: CDOperation?
    @NSManaged public var childOperations: NSSet?

    @NSManaged public var next: CDOperation?
    @NSManaged public var prev: CDOperation?

    @nonobjc public func containedOperations() -> [CDOperation] {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.predicate = NSPredicate(format: "container == %@", self)
        return try! self.managedObjectContext?.fetch(request) ?? []
    }

}

extension CDOperation {
    var type: CDOperationType {
        get {
            return CDOperationType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
    
    var unicodeScalar: UnicodeScalar {
        get {
            UnicodeScalar(UInt32(stringInsertContribution))!
        }
        set {
            stringInsertContribution = Int32(newValue.value) // there will be loss in UInt32 to Int32 conversion eventually
        }
    }

    var state: CDOperationState {
        get {
            return CDOperationState(rawValue: self.rawState)!
        }
        set {
            self.rawState = newValue.rawValue
        }
    }

    var objectType: CRObjectType {
        get {
            return CRObjectType(rawValue: self.rawObjectType)
        }
        set {
            self.rawObjectType = newValue.rawValue
        }
    }
    var attributeType: CRAttributeType {
        get {
            return CRAttributeType(rawValue: self.rawAttributeType)!
        }
        set {
            self.rawAttributeType = newValue.rawValue
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

extension CDOperation : Identifiable {

}

extension CDOperation : Comparable {
    public static func < (lhs: CDOperation, rhs: CDOperation) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }
    
    public static func == (lhs: CDOperation, rhs: CDOperation) -> Bool {
        return lhs.lamport == rhs.lamport && lhs.peerID == rhs.peerID
    }
}


extension CDOperation {
    
    convenience init(context: NSManagedObjectContext, container: CDOperation?) {
        self.init(context:context)
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.container = container
    }
    
    convenience init(context: NSManagedObjectContext, from: CROperationID) {
        self.init(context:context)
        self.lamport = from.lamport
        self.peerID = from.peerID
    }

    convenience init(context: NSManagedObjectContext, from: ProtoOperationID) {
        self.init(context:context)
        self.lamport = from.lamport
        self.peerID = from.peerID.object()
    }

    convenience init(context: NSManagedObjectContext, container: CDOperation?, parent: CDOperation?, type: CDOperationType, state: CDOperationState = .unknown) {
        self.init(context:context, container: container)
        self.parent = parent
        self.type = type
        self.state = state
    }
    
    convenience init(context: NSManagedObjectContext, container: CDOperation?, parentId: CROperationID, type: CDOperationType, state: CDOperationState = .unknown) {
        self.init(context:context, container: container)
        self.parentLamport = parentId.lamport
        self.parentPeerID = parentId.peerID
        self.type = type
        self.state = state
    }

    func operationID() -> CROperationID {
        return CROperationID(lamport: lamport, peerID: peerID)
    }
    
    func protoOperationID() -> ProtoOperationID {
        return ProtoOperationID.with {
            $0.lamport = lamport
            $0.peerID = peerID.data
        }
    }

    /** returns operation or a ghost operation for the ID*/
    static func findOperationOrCreateGhost(fromLamport:lamportType, fromPeerID:UUID, in context: NSManagedObjectContext) -> CDOperation {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "lamport = %@ and peerID = %@", argumentArray: [fromLamport, fromPeerID])
        let ops = try? context.fetch(request)
        guard let op = ops?.first else {
            return CDOperation.createGhost(context: context, id: CROperationID.init(lamport: fromLamport, peerID: fromPeerID))
        }
        return op
    }

    static func findOperationOrCreateGhost(from protoID:ProtoOperationID, in context: NSManagedObjectContext) -> CDOperation {
        return findOperationOrCreateGhost(fromLamport: protoID.lamport, fromPeerID: protoID.peerID.object(), in: context)
    }

    static func findOperationOrCreateGhost(from operationID:CROperationID, in context: NSManagedObjectContext) -> CDOperation {
        return findOperationOrCreateGhost(fromLamport: operationID.lamport, fromPeerID: operationID.peerID, in: context)
    }
    
//    static func findOperation(from address: CROperationID, in context: NSManagedObjectContext) -> CDOperation? {
//        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        request.predicate = NSPredicate(format: "lamport == %@ and peerID == %@", argumentArray: [address.lamport, address.peerID])
//        request.fetchLimit = 1
//        return try? context.fetch(request).first
//    }

    //TODO: replace case with some reasonable inheritance of protostructures; if possible
    static func findOrCreateOperation(context: NSManagedObjectContext, from protoForm: SwiftProtobuf.Message, container: CDOperation?, type: CDOperationType) -> CDOperation {
        var op:CDOperation?

        switch type {
        case .stringInsert:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoStringInsertOperation).id, in: context)
        case .attribute:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoAttributeOperation).id, in: context)
        case .delete:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoDeleteOperation).id, in: context)
        case .lwwBool:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
        case .lwwDate:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
        case .lwwFloat:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
        case .lwwInt:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
        case .lwwString:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
        case .object:
            op = findOperationOrCreateGhost(from: (protoForm as! ProtoObjectOperation).id, in: context)
        default:
            fatalNotImplemented()
        }
        
        if op!.type != .ghost {
            return op!
        }
        
        
        switch type {
        case .stringInsert:
            op!.updateObject(context: context, from: protoForm as! ProtoStringInsertOperation, container: container)
        case .attribute:
            op!.updateObject(context: context, from: protoForm as! ProtoAttributeOperation, container: container)
        case .delete:
            op!.updateObject(context: context, from: protoForm as! ProtoDeleteOperation, container: container)
        case .lwwBool:
            op!.updateObject(context: context, from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwDate:
            op!.updateObject(context: context, from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwFloat:
            op!.updateObject(context: context, from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwInt:
            op!.updateObject(context: context, from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwString:
            op!.updateObject(context: context, from: protoForm as! ProtoLWWOperation, container: container)
        case .object:
            op!.updateObject(context: context, from: protoForm as! ProtoObjectOperation, container: container)
        default:
            fatalNotImplemented()
        }
        
        return op!
    }

    
    static func printTreeOfContainers(context: NSManagedObjectContext) {
        print("nil")
        let indent = "  "
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == nil")
        for op in try! context.fetch(request) {
            op.printTreeOfContainers(indent: indent)
        }
    }
    
    func printTreeOfContainers(indent: String) {
        print("\(indent)\(self.shortDescrption())")
        let indent = indent + "  "
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        for op in try! managedObjectContext!.fetch(request) {
            op.printTreeOfContainers(indent: indent)
        }
    }
    
    func shortDescrption() -> String {
//        , state:\(state)
        return "op(peer=\(peerID), lamport=\(lamport), type=\(type))"
    }
}



extension CDOperation {
    func mergeUpstream(context: NSManagedObjectContext) {
        switch state {
        case .inUpstreamQueueRendered:
            break
        case .processed:
            return
        default:
            fatalNotImplemented()
        }
        
        switch type {
        case .stringInsert:
            stringInsertLinking(context: context)
        case .delete:
            deleteLinking(context: context)
        default:
            break
        }
        
        
        switch state {
        case .inUpstreamQueueRendered:
            state = .inUpstreamQueueRenderedMerged
        default:
            fatalNotImplemented()
        }

    }
    
    func mergeDownstream(context: NSManagedObjectContext) {
        switch state {
        case .inDownstreamQueue:
            break
        case .processed:
            return
        default:
            fatalNotImplemented()
        }
        
        switch type {
        case .stringInsert:
            stringInsertLinking(context: context)
        case .delete:
            deleteLinking(context: context)
        default:
            break
        }
    }
}
