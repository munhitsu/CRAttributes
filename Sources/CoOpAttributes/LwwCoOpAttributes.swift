//
//  OpAttribute+CoreDataClass.swift
//  CRDTNotes
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//  Copyright © 2021 cr3studio. All rights reserved.
//
//

import Foundation
import CoreData

// MARK: Int

@objc(IntLwwCoOpAttribute)
public class IntLwwCoOpAttribute: NSManagedObject {

}


extension IntLwwCoOpAttribute {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<IntLwwCoOpAttribute> {
//        return NSFetchRequest<IntLwwCoOpAttribute>(entityName: "IntLwwCoOpAttribute")
//    }

    @NSManaged public var version: Int16
    @NSManaged public var operations: NSSet?
}


extension IntLwwCoOpAttribute {

    @objc(addOperationsObject:)
    @NSManaged public func addToOperations(_ value: CoOpOperation)

    @objc(removeOperationsObject:)
    @NSManaged public func removeFromOperations(_ value: CoOpOperation)

    @objc(addOperations:)
    @NSManaged public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged public func removeFromOperations(_ values: NSSet)

}


// MARK: String

@objc(StringLwwCoOpAttribute)
public class StringLwwCoOpAttribute: NSManagedObject {

}


extension StringLwwCoOpAttribute {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<StringLwwCoOpAttribute> {
//        return NSFetchRequest<StringLwwCoOpAttribute>(entityName: "StringLwwCoOpAttribute")
//    }

    @NSManaged public var version: Int16
    @NSManaged public var operations: NSSet?
}


extension StringLwwCoOpAttribute {

    @objc(addOperationsObject:)
    @NSManaged public func addToOperations(_ value: CoOpOperation)

    @objc(removeOperationsObject:)
    @NSManaged public func removeFromOperations(_ value: CoOpOperation)

    @objc(addOperations:)
    @NSManaged public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged public func removeFromOperations(_ values: NSSet)

}

extension StringLwwCoOpAttribute {

    public var value: String {
        get {
            if let lastOp:CoOpOperation = ((self.operations?.allObjects as? [CoOpOperation])?.max()) {
                print("String.get lamport=\(lastOp.lamport)")
                return lastOp.operation.string
            } else {
                return ""
            }
        }
        set(newValue) {
            let newOperation = Operation.with {
                $0.oid = OperationID.generate()
                $0.string = newValue
            }
            let opLogEntry = CoOpOperation(in: self.managedObjectContext!, from: newOperation)
            for oldOp in (self.operations?.allObjects as! [CoOpOperation]) {
                self.removeFromOperations(oldOp)
                self.managedObjectContext?.delete(oldOp)
            }
            self.addToOperations(opLogEntry)
        }
    }
}

// MARK: Boolean

@objc(BooleanLwwCoOpAttribute)
public class BooleanLwwCoOpAttribute: NSManagedObject {

}


extension BooleanLwwCoOpAttribute {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<BooleanLwwCoOpAttribute> {
//        return NSFetchRequest<BooleanLwwCoOpAttribute>(entityName: "BooleanLwwCoOpAttribute")
//    }

    @NSManaged public var version: Int16
    @NSManaged public var operations: NSSet?
}


extension BooleanLwwCoOpAttribute {

    @objc(addOperationsObject:)
    @NSManaged public func addToOperations(_ value: CoOpOperation)

    @objc(removeOperationsObject:)
    @NSManaged public func removeFromOperations(_ value: CoOpOperation)

    @objc(addOperations:)
    @NSManaged public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged public func removeFromOperations(_ values: NSSet)

}
