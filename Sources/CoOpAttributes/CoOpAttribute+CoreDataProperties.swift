//
//  OpAttribute+CoreDataProperties.swift
//  CRDTNotes
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//  Copyright © 2021 cr3studio. All rights reserved.
//
//

import Foundation
import CoreData


extension CoOpAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpAttribute> {
        return NSFetchRequest<CoOpAttribute>(entityName: "CoOpAttribute")
    }

    @NSManaged public var type: Int16
    @NSManaged public var version: Int16
    @NSManaged public var operations: NSSet?
    @NSManaged public var cache: CoOpCache?

}

// MARK: Generated accessors for operations
extension CoOpAttribute {

    @objc(addOperationsObject:)
    @NSManaged public func addToOperations(_ value: CoOpLog)

    @objc(removeOperationsObject:)
    @NSManaged public func removeFromOperations(_ value: CoOpLog)

    @objc(addOperations:)
    @NSManaged public func addToOperations(_ values: NSSet)

    @objc(removeOperations:)
    @NSManaged public func removeFromOperations(_ values: NSSet)

}
