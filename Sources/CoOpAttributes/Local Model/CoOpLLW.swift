//
//  File.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CoOpLWW)
public class CoOpLWW: CoOpAbstractOperation {

}

extension CoOpLWW {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpLWW> {
        return NSFetchRequest<CoOpLWW>(entityName: "CoOpLWW")
    }

    @NSManaged public var int: Int64
    @NSManaged public var float: Float
    @NSManaged public var date: Date?
    @NSManaged public var boolean: Bool
    @NSManaged public var string: String?

}
