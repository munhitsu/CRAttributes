//
//  File.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CoOpAbstractOperation)
public class CoOpAbstractOperation: NSManagedObject {

}

extension CoOpAbstractOperation {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpAbstractOperation> {
        return NSFetchRequest<CoOpAbstractOperation>(entityName: "CoOpAbstractOperation")
    }

    @NSManaged public var version: Int16
    @NSManaged public var lamport: Int64
    @NSManaged public var peerID: Int64
    @NSManaged public var hasTombstone: Bool
    @NSManaged public var perent: CoOpAbstractOperation?
    @NSManaged public var attribute: CoOpAttribute?
    @NSManaged public var subOperations: NSSet?

}

// MARK: Generated accessors for subOperations
extension CoOpAbstractOperation {

    @objc(addSubOperationsObject:)
    @NSManaged public func addToSubOperations(_ value: CoOpAbstractOperation)

    @objc(removeSubOperationsObject:)
    @NSManaged public func removeFromSubOperations(_ value: CoOpAbstractOperation)

    @objc(addSubOperations:)
    @NSManaged public func addToSubOperations(_ values: NSSet)

    @objc(removeSubOperations:)
    @NSManaged public func removeFromSubOperations(_ values: NSSet)

}

extension CoOpAbstractOperation : Identifiable {

}
