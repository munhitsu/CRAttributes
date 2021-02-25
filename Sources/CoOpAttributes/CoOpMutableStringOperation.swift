//
//  OpLog+CoreDataProperties.swift
//  CRDTNotes
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//  Copyright © 2021 cr3studio. All rights reserved.
//
//

import Foundation
import CoreData

@objc(CoOpMutableStringOperation)
public class CoOpMutableStringOperation: NSManagedObject {
}

extension CoOpMutableStringOperation: Comparable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpMutableStringOperation> {
        return NSFetchRequest<CoOpMutableStringOperation>(entityName: "CoOpMutableStringOperation")
    }
    @NSManaged public var version: Int16

    @NSManaged public var lamport: Int64 // stored here for ordering
    @NSManaged public var peerID: Int64  // stored here for ordering
    @NSManaged public var parentOffset: Int64

    @NSManaged public var type: Int16
    @NSManaged public var length: Int64
    @NSManaged public var contribution: String
    
    public static func < (lhs: CoOpMutableStringOperation, rhs: CoOpMutableStringOperation) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }

    public static func == (lhs: CoOpMutableStringOperation, rhs: CoOpMutableStringOperation) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

}
