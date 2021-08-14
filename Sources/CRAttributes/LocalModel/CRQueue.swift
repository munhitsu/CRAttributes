//
//  CRObject.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(CRQueue)
public class CRQueue: NSManagedObject {

}

enum QueueType: Int16 {
    case downstream = 0 // external operations to process (e.g. for attributes not visible)
    case upstream = 1 // our user operations we are buffering before packaging
}

extension CRQueue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRQueue> {
        return NSFetchRequest<CRQueue>(entityName: "CRQueue")
    }
    @NSManaged public var rawType: Int16
    @NSManaged public var operation: CRAbstractOp?
    @NSManaged public var attributeLamport: Int64 // 0 means null
    @NSManaged public var attributePeerID: Int64 // 0 means null
}

extension CRQueue {
    var type: QueueType {
        get {
            return QueueType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}
