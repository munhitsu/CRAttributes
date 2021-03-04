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

    @NSManaged public var head: CoOpMutableStringOperationInsert // this should be always a zero element

    @NSManaged public var deletes: NSSet
    @NSManaged public var inserts: NSSet

    
    override public func awakeFromInsert() {
        setPrimitiveValue(CoOpMutableStringOperationInsert(isZero: true, context: self.managedObjectContext!), forKey: "head")
    }
}
