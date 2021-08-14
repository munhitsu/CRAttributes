//
//  CRObject.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRObjectOp)
public class CRObjectOp: CRAbstractOp {

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

extension CRObjectOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRObjectOp> {
        return NSFetchRequest<CRObjectOp>(entityName: "CRObjectOp")
    }

    @NSManaged public var rawType: Int32

}
 
extension CRObjectOp {
    var type: CRObjectType {
        get {
            return CRObjectType(rawValue: self.rawType)
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}

extension CRObjectOp {

    convenience init(context: NSManagedObjectContext, container: CRAbstractOp?, type: CRObjectType) {
        self.init(context:context, parent: container, attribute: nil)
        self.type = type
    }
    
    static func allObjects() -> [CRObjectOp]{
        let context = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CRObjectOp> = CRObjectOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        return try! context.fetch(request)
    }

    func protoOperation() -> ProtoObjectOperation {
        return ProtoObjectOperation.with {
            $0.base = super.protoOperation()
            $0.rawType = rawType
        }
    }
}


// example usage
extension CRObjectType {
    static let reserved = CRObjectType(rawValue: 1)
}
