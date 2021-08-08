//
//  CRStringInsert.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 24/07/2021.
//

import Foundation
import CoreData

@objc(CRStringInsertOp)
public class CRStringInsertOp: CRAbstractOp {

}


extension CRStringInsertOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRStringInsertOp> {
        return NSFetchRequest<CRStringInsertOp>(entityName: "CRStringInsertOp")
    }

    @NSManaged public var unicodeScalar: Int32
    @NSManaged public var next: CRStringInsertOp?
    @NSManaged public var prev: CRStringInsertOp?

}

extension CRStringInsertOp {
    convenience init(context: NSManagedObjectContext, parent: CRAbstractOp?, attribute: CRAttributeOp?, character: unichar) {
        self.init(context:context, parent: parent, attribute: attribute)
        self.unicodeScalar = Int32(character)
    }
}
