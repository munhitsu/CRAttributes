//
//  CRAttribute.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CDAttributeOp)
public class CDAttributeOp: CDAbstractOp {

}

extension CDAttributeOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDAttributeOp> {
        return NSFetchRequest<CDAttributeOp>(entityName: "CDAttributeOp")
    }

    @NSManaged public var name: String?
    @NSManaged public var rawType: Int32
}


enum CRAttributeType: Int32 {
    case int = 0
    case float = 1
    case date = 2
    case boolean = 3
    case string = 4
    case mutableString = 5
}


extension CDAttributeOp {
    var type: CRAttributeType {
        get {
            return CRAttributeType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}


extension CDAttributeOp {
    convenience init(context: NSManagedObjectContext, container: CDObjectOp?, type: CRAttributeType, name: String) {
        self.init(context: context, container: container)
        self.type = type
        self.name = name
        
        if type == .mutableString {
            let headOp = CDStringOp(context: context)
            headOp.lamport = 0
            headOp.peerID = .zero
            headOp.container = self
            headOp.type = .head
            headOp.state = .processed
            headOp.insertContribution = 0
            headOp.hasTombstone = false
            headOp.parentLamport = .zero
            headOp.parentPeerID = .zero
//            self.head = headOp
        }
        
    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoAttributeOperation, container: CDAbstractOp?, waitingForContainer: Bool=false) {
        print("From protobuf AttributeOp(\(protoForm.id.lamport))")
        self.init(context: context, container: container as? CDObjectOp, type: .init(rawValue: protoForm.rawType)!, name: protoForm.name)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.upstreamQueueOperation = false

        
        for protoItem in protoForm.deleteOperations {
            _ = CDDeleteOp(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.lwwOperations {
            _ = CDLWWOp(context: context, from: protoItem, container: self)
        }

        if protoForm.stringInsertOperations.count > 0 {
            _ = CDStringOp.restoreLinkedList(context: context, from: protoForm.stringInsertOperations, container: self)
        }
    }

    static func allObjects() -> [CDAttributeOp]{
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDAttributeOp> = CDAttributeOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try! context.fetch(request)
    }

    
    public func stringFromRGAList(context: NSManagedObjectContext) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString(string:"")
        var addressesArray:[CROperationID] = []

        // let's prefetch
        // BTW: there is no need to prefetch delete operations as we have the hasTombstone attribute
        var request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // let's get the first operation
        request = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == 0", self) // and rawType == 0
//        for op in try! context.fetch(request) {
//            print("would be adding: \(op)")
//        }
        let head:CDStringOp? = try? context.fetch(request).first

        // build the attributedString
        var node:CDStringOp? = head
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
        var request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", self)
        let _ = try! context.fetch(request)

        // let's get the first operation
        request = CDStringOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and rawType == 0", self) // and rawType == 0
        let head:CDStringOp? = try? context.fetch(request).first
        
        guard let head = head else { return (NSMutableAttributedString(string:""), [])}
        return stringFromRGATreeNode(node: head)
    }
    
    
    func stringFromRGATreeNode(node: CDStringOp) -> (NSMutableAttributedString, [CROperationID]) {
        let attributedString = NSMutableAttributedString()
        var addressesArray:[CROperationID] = []
        
        if !node.hasTombstone {
            attributedString.append(NSMutableAttributedString(string:String(node.unicodeScalar)))
            addressesArray.append(node.operationID())
        }

        let children = (node.childOperations?.allObjects as! [CDStringOp]).sorted(by: >)
        for child in children {
            let childString = stringFromRGATreeNode(node: child)
            attributedString.append(childString.0)
            addressesArray.append(contentsOf: childString.1)
        }
        return (attributedString, addressesArray)
    }
    
//    func protoOperation() -> ProtoAttributeOperation {
//        return ProtoAttributeOperation.with {
//            $0.base = super.protoOperation()
//            $0.name = name!
//            $0.rawType = rawType
//        }
//    }
}

