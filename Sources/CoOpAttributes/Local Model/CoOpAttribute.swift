//
//  CoOpAttribute.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CoOpAttribute)
public class CoOpAttribute: CoOpAbstractOperation {

}

enum CoOpAttributeType: Int16 {
    case int = 0
    case mutableString = 1
}

extension CoOpAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpAttribute> {
        return NSFetchRequest<CoOpAttribute>(entityName: "CoOpAttribute")
    }

    @NSManaged public var name: String?
    @NSManaged public var rawType: Int16
    @NSManaged public var attributeOperations: NSSet?
}

// MARK: Generated accessors for attributeOperations
extension CoOpAttribute {

@objc(addAttributeOperationsObject:)
@NSManaged public func addToAttributeOperations(_ value: CoOpAbstractOperation)

@objc(removeAttributeOperationsObject:)
@NSManaged public func removeFromAttributeOperations(_ value: CoOpAbstractOperation)

@objc(addAttributeOperations:)
@NSManaged public func addToAttributeOperations(_ values: NSSet)

@objc(removeAttributeOperations:)
@NSManaged public func removeFromAttributeOperations(_ values: NSSet)

}


extension CoOpAttribute {
    var type: CoOpAttributeType {
        get {
            return CoOpAttributeType(rawValue: self.rawType)!
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}
