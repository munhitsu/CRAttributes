//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 24/02/2021.
//

import Foundation
import CoreData

@objc(CoOpMutableStringAttribute)
public class CoOpMutableStringAttribute: NSManagedObject {
}

extension CoOpMutableStringAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpMutableStringAttribute> {
        return NSFetchRequest<CoOpMutableStringAttribute>(entityName: "CoOpMutableStringAttribute")
    }
    @NSManaged public var version: Int16

}
