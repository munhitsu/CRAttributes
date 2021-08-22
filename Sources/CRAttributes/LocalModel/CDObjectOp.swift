//
//  CRObject.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CDObjectOp)
public class CDObjectOp: CDAbstractOp {

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

extension CDObjectOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDObjectOp> {
        return NSFetchRequest<CDObjectOp>(entityName: "CDObjectOp")
    }

    @NSManaged public var rawType: Int32

}
 
extension CDObjectOp {
    var type: CRObjectType {
        get {
            return CRObjectType(rawValue: self.rawType)
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}

extension CDObjectOp {

    convenience init(context: NSManagedObjectContext, container: CDAbstractOp?, type: CRObjectType) {
        self.init(context:context, container: container)
        self.type = type
    }
    
    convenience init(context: NSManagedObjectContext, from protoForm: ProtoObjectOperation, container: CDAbstractOp?, waitingForContainer: Bool=false) {
        print("From protobuf ObjectOp(\(protoForm.id.lamport))")
        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.rawType = protoForm.rawType
        self.container = container
        self.upstreamQueueOperation = false

        
        for protoItem in protoForm.deleteOperations {
            _ = CDDeleteOp(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.attributeOperations {
            _ = CDAttributeOp(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.objectOperations {
            _ = CDObjectOp(context: context, from: protoItem, container: self)
        }
    }
    
    static func allObjects() -> [CDObjectOp]{
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDObjectOp> = CDObjectOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try! context.fetch(request)
    }

//    func protoOperation() -> ProtoObjectOperation {
//        return ProtoObjectOperation.with {
//            $0.base = super.protoOperation()
//            $0.rawType = rawType
//        }
//    }
 
    
}


// example usage
extension CRObjectType {
    static let reserved = CRObjectType(rawValue: 1)
}
