//
//  File.swift
//
//
//  Created by Mateusz Lapsa-Malawski on 04/03/2021.
//


import Foundation
import CoreData

@objc(CoOpMutableStringOperationInsert)
public class CoOpMutableStringOperationInsert: NSManagedObject {
}

extension CoOpMutableStringOperationInsert: Comparable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpMutableStringOperationInsert> {
        return NSFetchRequest<CoOpMutableStringOperationInsert>(entityName: "CoOpMutableStringOperationInsert")
    }
    @NSManaged public var version: Int16

    @NSManaged public var lamport: Int64 // stored here for ordering
    @NSManaged public var peerID: Int64  // stored here for ordering

    @NSManaged public var contribution: String
    
    @NSManaged public var parent: CoOpMutableStringOperationInsert?
    @NSManaged public var attribute: CoOpMutableStringAttribute?

    @NSManaged public var deletes: NSSet
    @NSManaged public var inserts: NSSet

    
    //TODO: add cached ordered inserts, where cache invalidate on for every parent of new insert operation
    
    public static func < (lhs: CoOpMutableStringOperationInsert, rhs: CoOpMutableStringOperationInsert) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }

    public static func == (lhs: CoOpMutableStringOperationInsert, rhs: CoOpMutableStringOperationInsert) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

    convenience init(isZero:Bool, context: NSManagedObjectContext) {
        self.init(context:context)
        version = 0
        lamport = 0
        peerID = 0
        contribution = ""
    }
}
