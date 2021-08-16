//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRLWWOp)
public class CRLWWOp: CRAbstractOp {

}

extension CRLWWOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRLWWOp> {
        return NSFetchRequest<CRLWWOp>(entityName: "CRLWWOp")
    }

    @NSManaged public var int: Int64
    @NSManaged public var float: Float
    @NSManaged public var date: Date?
    @NSManaged public var boolean: Bool
    @NSManaged public var string: String?

}

extension CRLWWOp {
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Int) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.int = Int64(value)
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Float) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.float = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Date) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.date = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Bool) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.boolean = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: String) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.string = value
        try! context.save()
    }

    convenience init(context: NSManagedObjectContext, from protoForm: ProtoLWWOperation, parent: CRAbstractOp?) {
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.peerID.object()
        self.lamport = protoForm.lamport
        self.parent = parent
        if parent != nil {
            self.parentLamport = parent!.lamport
            self.parentPeerID = parent!.peerID
            self.attribute = parent as? CRAttributeOp
        }

        switch protoForm.value {
        case .some(.int):
            self.int = protoForm.int
        case .some(.float):
            self.float = protoForm.float
        case .some(.date):
            //TODO: fix me!!!
            fatalNotImplemented()
//            self.date = protoForm.date
        case .some(.boolean):
            self.boolean = protoForm.boolean
        case .some(.string):
            self.string = protoForm.string
        case .none:
            fatalError("unknown LWW type")
        }
        
        
        for protoItem in protoForm.deleteOperations {
            _ = CRDeleteOp(context: context, from: protoItem, parent: self)
        }
    }
    
    static func allObjects() -> [CRLWWOp]{
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CRLWWOp> = CRLWWOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try! context.fetch(request)
    }

//    func protoOperation() -> ProtoLWWOperation {
//        return ProtoLWWOperation.with {
//            $0.base = super.protoOperation()
//            switch attribute?.type {
//            case .none:
//                fatalNotImplemented()
//            case .some(.int):
//                $0.int = int
//            case .some(.float):
//                $0.float = float
//            case .some(.date):
//                fatalNotImplemented() //TODO: implement Date
//            case .some(.boolean):
//                $0.boolean = boolean
//            case .some(.string):
//                $0.string = string!
//            case .some(.mutableString):
//                fatalNotImplemented()
//            }
//        }
//    }
}
