//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 04/03/2021.
//


import Foundation
import CoreData

@objc(CoOpMutableStringOperationDelete)
public class CoOpMutableStringOperationDelete: NSManagedObject {
}

extension CoOpMutableStringOperationDelete: Comparable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpMutableStringOperationDelete> {
        return NSFetchRequest<CoOpMutableStringOperationDelete>(entityName: "CoOpMutableStringOperationDelete")
    }
    @NSManaged public var version: Int16

    @NSManaged public var lamport: Int64 // no use but kept for completness
    @NSManaged public var peerID: Int64  // no use but kept for completness

    @NSManaged public var parent: CoOpMutableStringOperationInsert?
    @NSManaged public var attribute: CoOpMutableStringAttribute?
    
    convenience init(parent: CoOpMutableStringOperationInsert, attribute: CoOpMutableStringAttribute, context: NSManagedObjectContext) {
        self.init(context:context)
        self.version = 0
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.parent = parent
        self.attribute = attribute
    }

    public static func < (lhs: CoOpMutableStringOperationDelete, rhs: CoOpMutableStringOperationDelete) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport > rhs.lamport
        }
    }

    public static func == (lhs: CoOpMutableStringOperationDelete, rhs: CoOpMutableStringOperationDelete) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

}
