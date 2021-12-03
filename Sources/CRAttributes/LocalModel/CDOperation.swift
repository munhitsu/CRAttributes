//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData


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
    case inDownstreamQueueMergedUnrendered = 16 // merged, but not yet rendered
    case processed = 128 // rendered, merged, synced
}

enum CDOperationType: Int32 {
    case ghost = 0
    case delete = 1
    case object = 2
    case attribute = 3
    case lwwInt = 16
    case lwwFloat = 17
    case lwwBool = 18
    case lwwString = 19
    case lwwDate = 20

    case stringHead = 32
    case stringInsert = 33
}

// example extansion of CRObjectType
extension CRObjectType {
    static let reserved = CRObjectType(rawValue: 1)
}


@objc(CDStringOp)
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

    static func fetchOperation(fromLamport:lamportType, fromPeerID:UUID, in context: NSManagedObjectContext) -> CDOperation? {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.predicate = NSPredicate(format: "lamport = %@ and peerID = %@", argumentArray: [fromLamport, fromPeerID])
        let ops = try? context.fetch(request)
        return ops?.first
    }

    static func fetchOperation(from protoID:ProtoOperationID, in context: NSManagedObjectContext) -> CDOperation? {
        return fetchOperation(fromLamport: protoID.lamport, fromPeerID: protoID.peerID.object(), in: context)
    }

    static func fetchOperation(from operationID:CROperationID, in context: NSManagedObjectContext) -> CDOperation? {
        return fetchOperation(fromLamport: operationID.lamport, fromPeerID: operationID.peerID, in: context)
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
}

// MARK: - LWW
extension CDOperation {
 
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Int) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwInt = Int64(value)
        op.type = .lwwInt
        return op
    }

    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Float) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwFloat = value
        op.type = .lwwFloat
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Date) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwDate = value
        op.type = .lwwDate
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Bool) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwBool = value
        op.type = .lwwBool
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: String) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwString = value
        op.type = .lwwString
        return op
    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoLWWOperation, container: CDOperation?) {
        print("From protobuf LLWOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.state = .inDownstreamQueueMergedUnrendered


        switch protoForm.value {
        case .some(.int):
            self.type = .lwwInt
            self.lwwInt = protoForm.int
        case .some(.float):
            self.type = .lwwFloat
            self.lwwFloat = protoForm.float
        case .some(.date):
            //TODO: implement me
            self.type = .lwwDate
            fatalNotImplemented()
//            self.date = protoForm.date
        case .some(.boolean):
            self.type = .lwwBool
            self.lwwBool = protoForm.boolean
        case .some(.string):
            self.type = .lwwString
            self.lwwString = protoForm.string
        case .none:
            fatalError("unknown LWW type")
        }
        
        for protoItem in protoForm.deleteOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
    }
    
    func lwwValue() -> Int64 {
        return lwwInt
    }

    func lwwValue() -> Float {
        return lwwFloat
    }

    func lwwValue() -> Date {
        return lwwDate!
    }
    
    func lwwValue() -> Bool {
        return lwwBool
    }

    func lwwValue() -> String {
        return lwwString!
    }
}

// MARK: - Attribute
extension CDOperation {
    static func createAttribute(context: NSManagedObjectContext, container: CDOperation?, type: CRAttributeType, name: String) -> CDOperation {
        let op = CDOperation(context: context, container: container)
        op.attributeType = type
        op.attributeName = name
        op.type = .attribute
        op.state = .inUpstreamQueueRenderedMerged

        if type == .mutableString {
            let headOp = CDOperation.createStringHead(context: context, container: op)
            headOp.state = .processed
//            self.head = headOp
        }
        return op
    }

    /**
     from protobuf
     */
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoAttributeOperation, container: CDOperation?) {
        print("From protobuf AttributeOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.container = container
        self.attributeType = .init(rawValue: protoForm.rawType)!
        self.attributeName = protoForm.name
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.type = .attribute
        self.state = .inDownstreamQueueMergedUnrendered

        
        for protoItem in protoForm.deleteOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.lwwOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }

        if protoForm.stringInsertOperations.count > 0 {
            _ = CDOperation.restoreLinkedList(context: context, from: protoForm.stringInsertOperations, container: self)
        }
    }

//    static func allObjects() -> [CDAttributeOp]{
//        let context = CRStorageController.shared.localContainer.viewContext
//        let request:NSFetchRequest<CDAttributeOp> = CDAttributeOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        return try! context.fetch(request)
//    }

}

extension CDOperation {
    public func stringFromRGAList(context: NSManagedObjectContext) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString(string:"")
        var addressesArray:[CROperationID] = []

        // let's prefetch
        // BTW: there is no need to prefetch delete operations as we have the hasTombstone attribute
        var request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // let's get the first operation
        request = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == %@", argumentArray: [self, CDOperationType.stringHead.rawValue])
        let head:CDOperation? = try? context.fetch(request).first

        // build the attributedString
        var node:CDOperation? = head
        node = node?.next // let's skip the head
        while node != nil {
            if node!.hasTombstone == false {
                let contribution = NSMutableAttributedString(string:String(Character(node!.unicodeScalar)))
                attributedString.append(contribution)
                addressesArray.append(node!.operationID())
            }
            node = node!.next
        }
        return (attributedString, addressesArray)
    }
    
    public func stringFromRGATree(context: NSManagedObjectContext) -> (NSMutableAttributedString, [CROperationID]) {
        // let's prefetch
        var request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // let's get the first operation
        request = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == %@", argumentArray: [self, CDOperationType.stringHead.rawValue])
        let head:CDOperation? = try? context.fetch(request).first
        
        guard let head = head else { return (NSMutableAttributedString(string:""), [])}
        return stringFromRGATreeNode(node: head)
    }
    
    
    func stringFromRGATreeNode(node: CDOperation) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString()
        var addressesArray:[CROperationID] = []
        
        if !node.hasTombstone && node.type == .stringInsert {
            attributedString.append(NSMutableAttributedString(string:String(node.unicodeScalar)))
            addressesArray.append(node.operationID())
        }

        let children = (node.childOperations?.allObjects as! [CDOperation]).sorted(by: >)
        for child in children {
            let childString = stringFromRGATreeNode(node: child)
            attributedString.append(childString.0)
            addressesArray.append(contentsOf: childString.1)
        }
        return (attributedString, addressesArray)
    }
}

// MARK: - Object
extension CDOperation {
    static func createObject(context: NSManagedObjectContext, container: CDOperation?, type: CRObjectType) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.objectType = type
        op.type = .object
        op.state = .inUpstreamQueueRenderedMerged
        return op
    }
    
    /**
     initialise from the protobuf
     */
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoObjectOperation, container: CDOperation?) {
        print("From protobuf ObjectOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.rawObjectType = protoForm.rawType
        self.container = container
        self.type = .object
        self.state = .inDownstreamQueueMergedUnrendered

        
        for protoItem in protoForm.deleteOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.attributeOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.objectOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
    }
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


// MARK: - String
extension CDOperation {
    
    static func createStringHead(context: NSManagedObjectContext, container: CDOperation?) -> CDOperation {
        let op = CDOperation(context:context)
        op.lamport = 0
        op.peerID = .zero
        op.container = container
        op.parentLamport = 0
        op.parentPeerID = .zero
        op.unicodeScalar = UnicodeScalar(0)
        op.type = .stringHead
        op.state = .inUpstreamQueueRendered
        return op
    }
    
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

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoStringInsertOperation, container: CDOperation?) {
        print("From protobuf StringInsertOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.stringInsertContribution = protoForm.contribution
        self.parent = CDOperation.fetchOperation(from: protoForm.parentID, in: context) // will be null if parent is not yet with us //TODO: create parent
        self.container = container
        self.type = .stringInsert
        self.state = .inDownstreamQueueMergedUnrendered

        for protoItem in protoForm.deleteOperations {
            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
    }
    
    /**
     does not save
     returns if linking was yet possible
     */
    func linkMe(context: NSManagedObjectContext) -> Bool {
        let parentAddress = CROperationID(lamport: parentLamport, peerID: parentPeerID)

        guard let container = container else { return false }
        guard let parentOp = CDOperation.fromStringAddress(context: context, address: parentAddress, container: container) else {
            return false
        }
//        print("pre:")
//        print("parent: '\(parentOp.unicodeScalar)' \(parentOp.lamport): parent:\(parentOp.parent?.lamport) prev:\(parentOp.prev?.lamport) next:\(parentOp.next?.lamport)")
//        print("self: '\(unicodeScalar)' \(lamport): parent:\(parent?.lamport) prev:\(prev?.lamport) next:\(next?.lamport)")
//
//        assert(parentOp.managedObjectContext == self.managedObjectContext)
        
        
    mainSwitch: switch self.type {
        case .stringHead:
            break
        case .stringInsert:
            let children:[CDOperation] = (parentOp.childOperations?.allObjects as? [CDOperation] ?? []).sorted(by: >)
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
            for op: CDOperation in children {
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
        default:
            fatalNotImplemented()
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
        assert(type == .attribute)
        assert(attributeType == .mutableString)

        // let's get the first operation
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == %@", argumentArray: [self, CDOperationType.stringHead.rawValue]) // select head
        var response = try! context.fetch(request)
        assert(response.count == 1)
        let head:CDOperation? = response.first

        // build the attributedString
        var string = ""
        var node:CDOperation? = head
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
        request.predicate = NSPredicate(format: "container == %@ and parent == nil", argumentArray: [self])
        response = try! context.fetch(request)
        for op in response {
            if op.type != .stringHead {
                op.printRGATree(intention: 2)
            }
        }
    }
    
    func printRGATree(intention: Int) {
        print(String(repeating: " ", count: intention) + "[\(lamport)]: '\(unicodeScalar)' prev:\(prev?.lamport) next:\(next?.lamport) state:\(state)")
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
            let op = CDOperation(context: context, from: protoOp, container: container)
            cdOperations.append(op)
            op.prev = prevOp
            prevOp?.next = op
            prevOp = op
        }
        return cdOperations[0]
    }
    
    static func fromStringAddress(context: NSManagedObjectContext, address: CROperationID, container: CDOperation) -> CDOperation? {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "lamport == %@ and peerID == %@ and container == %@", argumentArray: [address.lamport, address.peerID, container])
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }

}


// MARK: - Delete
extension CDOperation {
    
    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parent: CDOperation) -> CDOperation {
        return CDOperation(context: context, container: container, parent: parent, type: .delete)
    }
    
    static func createDelete(context: NSManagedObjectContext, within container: CDOperation?, of parentId: CROperationID) -> CDOperation {
        return CDOperation(context: context, container: container, parentId: parentId, type: .delete)
    }

    /**
     initialise from the protobuf
     */
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoDeleteOperation, container: CDOperation?) {
        print("From protobuf DeleteOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.container?.hasTombstone = true
        self.type = .delete
        self.state = .inDownstreamQueueMergedUnrendered

    }
}


// MARK: - Ghost
extension CDOperation {
    static func createGhost(context: NSManagedObjectContext, id: CROperationID) -> CDOperation {
        let op = CDOperation(context: context)
        op.version = 0
        op.peerID = id.peerID
        op.lamport = id.lamport
        op.type = .ghost
        return op
    }
    
    // there is no protobuf init as protobuf existence makes ghost materialise
}
