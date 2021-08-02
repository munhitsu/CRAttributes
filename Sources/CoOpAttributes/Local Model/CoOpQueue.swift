//
//  CoOpObject.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(CoOpQueue)
public class CoOpQueue: NSManagedObject {

}

enum QueueType: Int16 {
    case downstream = 0 // external operations to process (e.g. for attributes not visible)
    case upstream = 1 // our user operations we are buffering before packaging
}

extension CoOpQueue {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpQueue> {
        return NSFetchRequest<CoOpQueue>(entityName: "CoOpQueue")
    }
    @NSManaged public var rawType: Int16
    @NSManaged public var operation: CoOpAbstractOperation?
    @NSManaged public var attributeLamport: Int64 // 0 means null
    @NSManaged public var attributePeerID: Int64 // 0 means null
}

extension CoOpQueue {
    var type: QueueType {
        get {
            return QueueType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}
