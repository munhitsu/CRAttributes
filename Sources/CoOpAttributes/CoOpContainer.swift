//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 21/02/2021.
//

import Foundation
import CoreData


@objc(CoOpContainer)
public class CoOpContainer: NSManagedObject {

}

extension CoOpContainer {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpLog> {
//        return NSFetchRequest<CoOpLog>(entityName: "CoOpLog")
//    }
    @NSManaged public var ckID: String
    @NSManaged public var version: Int16
    
    public convenience init(in context: NSManagedObjectContext, from record: CKRecord) {
        self.init(context:context)
        
        ckID = record.recordID.recordName as String
        version = record["version"] as? Int16 ?? 0
    }

    public func update(from record: CKRecord) {
        ckID = record.recordID.recordName as String
        version = record["version"] as? Int16 ?? 0
    }
}
