//
//  CDOperation+Object.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData

extension CDOperation {
    static func createObject(context: NSManagedObjectContext, container: CDOperation?, type: CRObjectType) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.objectType = type
        op.type = .object
        op.state = .inUpstreamQueueRenderedMerged
        return op
    }
    
    /**
     initialise from the protobuf
     */
    func updateObject(context: NSManagedObjectContext, from protoForm: ProtoObjectOperation, container: CDOperation?) {
        print("From protobuf ObjectOp(\(protoForm.id.lamport))")
//        self.init(context: context)
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.rawObjectType = protoForm.rawType
        self.container = container
        self.type = .object
        self.state = .inDownstreamQueueMergedUnrendered

        
        for protoItem in protoForm.deleteOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .delete)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.attributeOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .attribute)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
        
        for protoItem in protoForm.objectOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .object)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
    }
}



