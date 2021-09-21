//
//  RenderedStringOp.swift
//  RenderedStringOp
//
//  Created by Mateusz Lapsa-Malawski on 26/08/2021.
//

import Foundation
import CoreData

@objc(RenderedStringReplaceOp)
public class RenderedStringReplaceOp: NSManagedObject {
}

extension RenderedStringReplaceOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RenderedStringReplaceOp> {
        return NSFetchRequest<RenderedStringReplaceOp>(entityName: "RenderedStringReplaceOp")
    }
        
    @NSManaged public var lamport: Int64
    @NSManaged public var stringPosition: Int64
    @NSManaged public var contribution: String

    @NSManaged public var StringOperations: NSSet?
}

extension RenderedStringReplaceOp {

    @objc(addStringOperationsObject:)
    @NSManaged public func addToStringOperations(_ value: CDAbstractOp)

    @objc(removeContainedOperationsObject:)
    @NSManaged public func removeFromStringOperations(_ value: CDAbstractOp)

    @objc(addStringOperations:)
    @NSManaged public func addToStringOperations(_ values: NSSet)

    @objc(removeStringOperations:)
    @NSManaged public func removeFromStringOperations(_ values: NSSet)

}

extension RenderedStringReplaceOp : Identifiable {

}
