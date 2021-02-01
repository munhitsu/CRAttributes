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
public class CoOpLog: NSManagedObject {

}

extension CoOpLog: Comparable {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpLog> {
//        return NSFetchRequest<CoOpLog>(entityName: "CoOpLog")
//    }

    @NSManaged public var lamport: Int64 // stored here for ordering and max()
    @NSManaged public var peerID: Int64  // stored here for ordering and max() for LWW
    @NSManaged public var version: Int16
    @NSManaged public var rawOperation: Data
    
    public var operation: Operation? {
        do {
            let operation = try Operation(serializedData: self.rawOperation)
            return operation
        } catch {
            return nil
        }
    }
    
    public convenience init(in context: NSManagedObjectContext, operation: Operation) {
        self.init(context:context)
        
        do {
            self.rawOperation = try operation.serializedData()
        } catch {
            fatalError("error serialising operation \(operation.debugDescription)")
        }
        self.lamport = operation.id.lamport
        self.peerID = operation.id.peerID
        self.version = 0
    }
    
    public static func < (lhs: CoOpLog, rhs: CoOpLog) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }

    public static func == (lhs: CoOpLog, rhs: CoOpLog) -> Bool {
        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
    }

}
