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


extension CoOpCache {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpCache> {
        return NSFetchRequest<CoOpCache>(entityName: "CoOpCache")
    }

    @NSManaged public var version: Int16
    @NSManaged public var int: Int64
    @NSManaged public var string: String?
    @NSManaged public var attribute: CoOpAttribute?

}
