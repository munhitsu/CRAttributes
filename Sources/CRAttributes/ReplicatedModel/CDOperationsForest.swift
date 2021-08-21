//
//  ReplcatedOperationPack.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf

@objc(CDOperationsForest)
public class CDOperationsForest: NSManagedObject {
    
}

extension CDOperationsForest {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDOperationsForest> {
        return NSFetchRequest<CDOperationsForest>(entityName: "CDOperationsForest")
    }
    
    @NSManaged public var version: Int32
    @NSManaged public var lamport: lamportType
    @NSManaged public var peerID: UUID
    @NSManaged public var data: Data? // Peer OperationsForest
}

extension CDOperationsForest : Identifiable {

    convenience init(context:NSManagedObjectContext, from: ProtoOperationsForest) {
        self.init(context: context)
        self.data = try? from.serializedData()
        self.version = 0
        self.lamport = getLamport()
        self.peerID = localPeerID
    }
    
    func protoStructure() -> ProtoOperationsForest {
        var options = BinaryDecodingOptions()
        options.messageDepthLimit = 10000

        return try! ProtoOperationsForest.init(serializedData: data!, extensions: nil, partial: false, options: options)
    }
    
    static func allObjects(context: NSManagedObjectContext) -> [CDOperationsForest] {
        let request:NSFetchRequest<CDOperationsForest> = CDOperationsForest.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: true)]
        return try! context.fetch(request)
    }
}
