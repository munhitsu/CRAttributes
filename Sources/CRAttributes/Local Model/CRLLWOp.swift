//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRLWWOp)
public class CRLWWOp: CRAbstractOp {

}

extension CRLWWOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRLWWOp> {
        return NSFetchRequest<CRLWWOp>(entityName: "CRLWWOp")
    }

    @NSManaged public var int: Int64
    @NSManaged public var float: Float
    @NSManaged public var date: Date?
    @NSManaged public var boolean: Bool
    @NSManaged public var string: String?

}

extension CRLWWOp {
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Int) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.int = Int64(value)
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Float) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.float = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Date) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.date = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: Bool) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.boolean = value
        try! context.save()
    }
    convenience init(context: NSManagedObjectContext, attribute: CRAttributeOp?, value: String) {
        self.init(context:context, parent: attribute, attribute: attribute)
        self.string = value
        try! context.save()
    }
}
