//
//  ReplcatedOperationPack.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(ReplicatedOperationPack)
public class ReplicatedOperationPack: NSManagedObject {
    
}

extension ReplicatedOperationPack {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReplicatedOperationPack> {
        return NSFetchRequest<ReplicatedOperationPack>(entityName: "ReplicatedOperationPack")
    }
    
    @NSManaged public var version: Int16
    @NSManaged public var attributeLamport: Int64 // 0 means null
    @NSManaged public var attributePeerID: Int64 // 0 means null
    @NSManaged public var rawPack: Data?
}

extension ReplicatedOperationPack : Identifiable {

}
