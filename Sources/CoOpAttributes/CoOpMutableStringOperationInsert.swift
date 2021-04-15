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
    deinit {
        print("CoOpMutableStringOperationInsert.deinit")
    }
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
            return lhs.lamport > rhs.lamport
        }
    }

    public static func == (lhs: CoOpMutableStringOperationInsert, rhs: CoOpMutableStringOperationInsert) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

    
    //TODO: Maybe zero should have a real lamport and peerID???
//    convenience init(isZero: Bool, attribute: CoOpMutableStringAttribute, context: NSManagedObjectContext) {
//        self.init(context:context)
//        version = 0
//        lamport = 0
//        peerID = 0
//        contribution = ""
//    }
    
    convenience init(contribution: String, parent: CoOpMutableStringOperationInsert?, attribute: CoOpMutableStringAttribute, context: NSManagedObjectContext) {
        self.init(context:context)
        self.version = 0
        self.lamport = getLamport()
        self.peerID = localPeerID
        self.parent = parent
        self.attribute = attribute
        self.contribution = contribution
    }
    
    
    public func orderedInserts() -> [CoOpMutableStringOperationInsert] {
        //TODO: cache on 1st run and invalidate cache on new insert
        return (self.inserts as! Set<CoOpMutableStringOperationInsert>).sorted()
    }
    
    public func hasDeleteOperation() -> Bool {
        return self.deletes.count > 0
    }

    //TODO: when is it really used?
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        lamport = getLamport()
        peerID = localPeerID
    }
}


extension CoOpMutableStringOperationInsert {
    public override var description: String {
        return "Insert(\(contribution):\(self.lamport):\(!hasDeleteOperation()))"
    }

    public var treeDescription: String {
        var str = ">\(contribution)|\(self.lamport)|\(hasDeleteOperation() ? "deleted" : "")\n"
        for op in orderedInserts() {
            str += op.treeDescription.replacingOccurrences(of: "\n", with: "\n ")
        }
        return str
    }

}
