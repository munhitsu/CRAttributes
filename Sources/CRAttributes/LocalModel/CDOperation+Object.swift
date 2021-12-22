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
    func updateObject(from protoForm: ProtoObjectOperation, container: CDOperation?) {
        print("From protobuf ObjectOp(\(protoForm.id.lamport))")
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.rawObjectType = protoForm.rawType
        self.container = container
        self.type = .object
        self.state = .inDownstreamQueueMergedUnrendered

        let context = managedObjectContext!
        
        for protoItem in protoForm.deleteOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .delete)
        }
        
        for protoItem in protoForm.attributeOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .attribute)
        }
        
        for protoItem in protoForm.objectOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .object)
        }
    }
}

extension CDOperation {
    func protoObjectOperationRecurse() -> ProtoObjectOperation {
        assert(self.type == .object)
        var proto = ProtoObjectOperation.with {
            $0.version = self.version
            $0.id.lamport = self.lamport
            $0.id.peerID  = self.peerID.data
            $0.rawType = self.rawType
        }
        for operation in self.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(operation.protoDeleteOperationRecurse())
                case .attribute:
                    proto.attributeOperations.append(operation.protoAttributeOperationRecurse())
                case .object:
                    proto.objectOperations.append(operation.protoObjectOperationRecurse())
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        self.state = .processed
        return proto
    }
}
