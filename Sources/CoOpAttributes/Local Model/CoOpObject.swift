//
//  CoOpObject.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CoOpObject)
public class CoOpObject: CoOpAbstractOperation {

}


struct ObjectType: RawRepresentable, Equatable, Hashable, Comparable {
    typealias RawValue = Int16
    
    var rawValue: Int16
    
    static let unknown = ObjectType(rawValue: 0)
    
    var hashValue: Int {
        return rawValue.hashValue
    }
    
    public static func <(lhs: ObjectType, rhs: ObjectType) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

extension CoOpObject {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpObject> {
        return NSFetchRequest<CoOpObject>(entityName: "CoOpObject")
    }

    @NSManaged public var rawType: Int16

}
 
extension CoOpObject {
    var type: ObjectType {
        get {
            return ObjectType(rawValue: self.rawType)
        }
        set {
            self.rawType = newValue.rawValue
        }
    }
}

// example usage
extension ObjectType {
    static let reserved = ObjectType(rawValue: 1)
}
