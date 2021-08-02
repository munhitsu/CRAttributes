//
//  CoOpStringInsert.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData

@objc(CoOpStringInsert)
public class CoOpStringInsert: CoOpAbstractOperation {

}


extension CoOpStringInsert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpStringInsert> {
        return NSFetchRequest<CoOpStringInsert>(entityName: "CoOpStringInsert")
    }

    @NSManaged public var character: Int32
    @NSManaged public var next: CoOpStringInsert?
    @NSManaged public var prev: CoOpStringInsert?

}
