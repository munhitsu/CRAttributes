//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf


public enum CRAttributeType: Int32 {
    case int = 0
    case float = 1
    case date = 2
    case boolean = 3
    case string = 4
    case mutableString = 5
    case binaryData = 6
    case operationID = 7
}

enum CDOperationState: Int32 {
    case unknown = 0 // should never happen
    case inUpstreamQueueRendered = 1 // rendered, but waiting to convert ID to references (to link/merge), and waiting to be added for synchronisation
    case inUpstreamQueueRenderedMerged = 2 // merged, rendered, but waiting for synchronisation
    case inDownstreamQueue = 16 // merged, but not yet rendered
    case inDownstreamQueueMergedUnrendered = 17 // merged, but not yet rendered
    case inDownstreamQueueMergedRendered = 18 // merged, but not yet rendered
    case processed = 128 // rendered, merged, synced
}

public enum CDOperationType: Int32 {
    case ghost = 0
    case delete = 1
    case object = 2
    case attribute = 3 // attribute is a stringHead
    case lwwInt = 16
    case lwwFloat = 17
    case lwwBool = 18
    case lwwString = 19
    case lwwDate = 20
    case lwwBinaryData = 21
    case lwwOperationID = 22
    case stringInsert = 32
}

public struct CRObjectType: RawRepresentable, Equatable, Hashable, Comparable {
    public typealias RawValue = Int32
    
    public var rawValue: Int32
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    
    
    static let unknown = CRObjectType(rawValue: 0)
    
    public var hashValue: Int {
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
    weak var weakCREntity: CREntity? //if we have UI object then it will be refered here
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
    @NSManaged public var lwwBinaryData: Data?
    @NSManaged public var lwwLamport: Int64
    @NSManaged public var lwwPeerID: UUID


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

    convenience init(context: NSManagedObjectContext, container: CDOperation?, parentID: CROperationID, type: CDOperationType, state: CDOperationState = .unknown) {
        self.init(context:context, container: container)
        self.parentLamport = parentID.lamport
        self.parentPeerID = parentID.peerID
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

    /**
     returns operation or a ghost operation for the ID
     */
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
    
    //TODO: replace case with some reasonable inheritance of protostructures (if possible)
    static func findOrCreateOperation(context: NSManagedObjectContext, from protoForm: SwiftProtobuf.Message, container: CDOperation?, type: CDOperationType) -> CDOperation {
        var op:CDOperation?

        context.performAndWait { //TODO: caller will need to have it in context.performAndWait - so do we need to?
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
            case .lwwBinaryData:
                op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
            case .lwwOperationID:
                op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
            case .lwwString:
                op = findOperationOrCreateGhost(from: (protoForm as! ProtoLWWOperation).id, in: context)
            case .object:
                op = findOperationOrCreateGhost(from: (protoForm as! ProtoObjectOperation).id, in: context)
            default:
                fatalNotImplemented()
            }
        }
        
        if op!.type != .ghost {
            return op!
        }
        
        
        switch type {
        case .stringInsert:
            op!.updateObject(from: protoForm as! ProtoStringInsertOperation, container: container)
        case .attribute:
            op!.updateObject(from: protoForm as! ProtoAttributeOperation, container: container)
        case .delete:
            op!.updateObject(from: protoForm as! ProtoDeleteOperation, container: container)
        case .lwwBool:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwDate:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwFloat:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwInt:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwBinaryData:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwOperationID:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .lwwString:
            op!.updateObject(from: protoForm as! ProtoLWWOperation, container: container)
        case .object:
            op!.updateObject(from: protoForm as! ProtoObjectOperation, container: container)
        default:
            fatalNotImplemented()
        }
        
        return op!
    }

    
    static func printTreeOfContainers(context: NSManagedObjectContext) {
        context.performAndWait {
            print("treeOfContainers:")
            print("nil")
            let indent = "  "
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == nil")
            for op in try! context.fetch(request) {
                op.printTreeOfContainers(indent: indent)
            }
        }
    }
    
    func printTreeOfContainers(indent: String) {
        managedObjectContext?.performAndWait {
            print("\(indent)\(self.shortDescrption())")
            if self.type == .attribute && self.attributeType == .mutableString {
                self.printRGADebug()
            }
            let indent = indent + "  "
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "container == %@", self)
            for op in try! managedObjectContext!.fetch(request) {
                op.printTreeOfContainers(indent: indent)
            }
        }
    }
    
    func shortDescrption() -> String {
        //peer=\(peerID),
        switch type {
        case .stringInsert:
            return "op([\(lamport)]: '\(unicodeScalar)' parent=\(String(describing: parent?.lamport)) prev=\(String(describing: prev?.lamport)) next=\(String(describing: next?.lamport)) type=\(type), state:\(state))"
        case .attribute:
            return "op([\(lamport)]: '\(attributeName!) type=\(type), state:\(state))"
        default:
            return "op([\(lamport)]: type=\(type), state:\(state))"
        }
    }
    
    
    var isContainer: Bool {
        switch type {
        case .attribute:
            return true
        case .object:
            return true
        default:
            return false
        }
    }
    
    var hasCREntity: Bool {
        return weakCREntity != nil
    }
    
    /**
     ghost returns nil
     object and attribute will always return CREntity
     lww operation or string operation or delete will return container CREntity but only if container is not a ghost
     */
//    //TODO: messy design - CDOperation should not know about CREntities, migrate away to CREntity
//    @MainActor func getOrCreateCREntity() -> CREntity? {
//        assert(hasTombstone == false)
//        if let weakCREntity = weakCREntity {
//            return weakCREntity
//        } else {
//            var newEntity:CREntity? = nil
//            switch type {
//            case .ghost:
//                break
//            case .attribute:
//                newEntity = CRAttribute.factory(context: self.managedObjectContext!, from: self)
//            case .object:
//                newEntity = CRObject(from: self)
//            default:
//                newEntity = nil
//            }
//            weakCREntity = newEntity
//            return newEntity
//        }
//    }
}



extension CDOperation {
    func mergeFromUpstream(context: NSManagedObjectContext) {
        print("merging Upstream Op \(self.operationID())")
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
            stringInsertLinking()
        case .delete:
            deleteLinking()
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
    
    func mergeFromDownstream(context: NSManagedObjectContext) {
        print("merging Downstream Op \(self.operationID())")
        switch state {
        case .inDownstreamQueue:
            break
        case .processed:
            return
        case .inDownstreamQueueMergedUnrendered:
            return
        default:
            print("skipping already merged: \(self.operationID())")
//            fatalNotImplemented("mergeDownstream with state = \(state)")
        }
        
        switch type {
        case .stringInsert:
            stringInsertLinking() // this updates linked list after tree is connected
            //TODO: IMPLEMENT
//            handle rendering update
//            shoudld we spawn the cRAttribute and perform acitons on it?
//            an attributecould have a queue of operations (and as long as there is something in the queue attribute will be in memory)
//            but UIattribute needs to be on man thread, while all others should be on the background thread - or we don't care for now - an all are on the main thread?
//

        case .delete:
            deleteLinking()
            //TODO: IMPLEMENT
//            handle rendering update
        default:
            break
        }
        
        switch state {
        case .inDownstreamQueue:
            state = .inDownstreamQueueMergedUnrendered
        default:
            print("skipping already merged: \(self.operationID())")
//            fatalNotImplemented()
        }
    }
}
