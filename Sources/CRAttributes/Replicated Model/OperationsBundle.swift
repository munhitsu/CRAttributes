//
//  ReplcatedOperationPack.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(OperationsBundle)
public class OperationsBundle: NSManagedObject {
    
}

extension OperationsBundle {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<OperationsBundle> {
        return NSFetchRequest<OperationsBundle>(entityName: "OperationsBundle")
    }
    
    @NSManaged public var version: Int32
    @NSManaged public var peerID: UUID
    @NSManaged public var data: Data?
}

extension OperationsBundle : Identifiable {

    func protoStructure() -> ProtoOperationsBundle {
        return try! ProtoOperationsBundle.init(serializedData: self.data!)
    }
    
    static func allObjects(context: NSManagedObjectContext) -> [OperationsBundle] {
        let request:NSFetchRequest<OperationsBundle> = OperationsBundle.fetchRequest()
        return try! context.fetch(request)
    }
}

