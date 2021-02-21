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

@objc(CoOpLog)
public class CoOpOperation: NSManagedObject {
    private var operationCache: Operation?

}

extension CoOpOperation: Comparable {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpLog> {
//        return NSFetchRequest<CoOpLog>(entityName: "CoOpLog")
//    }
    @NSManaged public var ckID: String
    @NSManaged public var lamport: Int64 // stored here for ordering and max()
    @NSManaged public var peerID: Int64  // stored here for ordering and max() for LWW
    @NSManaged public var version: Int16
    @NSManaged public var rawOperation: Data
    
    public var operation: Operation {
        if operationCache == nil {
            operationCache = try? Operation(serializedData: rawOperation)
        }
        return operationCache!
    }
    
    public convenience init(in context: NSManagedObjectContext, from decodedOperation: Operation) {
        self.init(context:context)
        
        do {
            rawOperation = try decodedOperation.serializedData()
        } catch {
            fatalError("error serialising operation \(decodedOperation.debugDescription)")
        }
        lamport = decodedOperation.oid.lamport
        peerID = decodedOperation.oid.peerID
        version = 0
    }
    
    public convenience init(in context: NSManagedObjectContext, from record: CKRecord) {
        self.init(context:context)
        
        ckID = record.recordID.recordName as String
        rawOperation = record["rawOperation"] as! Data
        
        lamport = operation.oid.lamport
        peerID = operation.oid.peerID
        version = record["version"] as? Int16 ?? 0
    }
    
    public static func < (lhs: CoOpOperation, rhs: CoOpOperation) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }

    public static func == (lhs: CoOpOperation, rhs: CoOpOperation) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

}
