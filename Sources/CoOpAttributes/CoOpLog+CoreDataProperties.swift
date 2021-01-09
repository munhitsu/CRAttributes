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


extension CoOpLog {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpLog> {
        return NSFetchRequest<CoOpLog>(entityName: "CoOpLog")
    }

    @NSManaged public var lamport: Int64
    @NSManaged public var peerId: UUID?
    @NSManaged public var version: Int16
    @NSManaged public var operation: String?
    @NSManaged public var attribute: CoOpAttribute?

}
