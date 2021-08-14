//
//  ReplcatedOperationPack.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(OperationsForest)
public class OperationsForest: NSManagedObject {
    
}

extension OperationsForest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OperationsForest> {
        return NSFetchRequest<OperationsForest>(entityName: "OperationsForest")
    }
    
    @NSManaged public var version: Int32
    @NSManaged public var peerID: UUID
    @NSManaged public var data: Data? // Peer OperationsForest
}

extension OperationsForest : Identifiable {

    convenience init(context:NSManagedObjectContext, from: ProtoOperationsForest) {
        self.init(context: context)
        self.data = try? from.serializedData()
        self.version = 0
        self.peerID = localPeerID
    }
    
    func protoStructure() -> ProtoOperationsForest {
        return try! ProtoOperationsForest.init(serializedData: self.data!)
    }
    
    static func allObjects(context: NSManagedObjectContext) -> [OperationsForest] {
        let request:NSFetchRequest<OperationsForest> = OperationsForest.fetchRequest()
        return try! context.fetch(request)
    }
}
