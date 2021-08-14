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

    @NSManaged public var contribution: String
    @NSManaged public var next: CRStringInsertOp?
    @NSManaged public var prev: CRStringInsertOp?

}

extension CRStringInsertOp {
    convenience init(context: NSManagedObjectContext, parent: CRAbstractOp?, attribute: CRAttributeOp?, contribution: String) {
        self.init(context:context, parent: parent, attribute: attribute)
        self.contribution = contribution
    }
    convenience init(context: NSManagedObjectContext, parent: CRAbstractOp?, attribute: CRAttributeOp?, contribution: unichar) {
        self.init(context:context, parent: parent, attribute: attribute)
        var uc = contribution
        self.contribution = NSString(characters: &uc, length: 1) as String
        //TODO: migrate to init(utf16CodeUnits: UnsafePointer<unichar>, count: Int)
    }

    func protoOperation() -> ProtoStringInsertOperation {
        return ProtoStringInsertOperation.with {
            $0.base = super.protoOperation()
            $0.contribution = contribution
        }
    }
}
