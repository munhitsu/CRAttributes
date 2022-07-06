//
//  CDOperation+LWW.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData

extension CDOperation {
 
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Int) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwInt = Int64(value)
        op.type = .lwwInt
        return op
    }

    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Float) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwFloat = value
        op.type = .lwwFloat
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Date) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwDate = value
        op.type = .lwwDate
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Bool) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwBool = value
        op.type = .lwwBool
        return op
    }
    
    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: Data) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwBinaryData = value
        op.type = .lwwBinaryData
        return op
    }

    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: CROperationID) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwLamport = value.lamport
        op.lwwPeerID = value.peerID
        op.type = .lwwOperationID
        return op
    }

    static func createLWW(context: NSManagedObjectContext, container: CDOperation?, value: String) -> CDOperation {
        let op = CDOperation(context:context, container: container)
        op.lwwString = value
        op.type = .lwwString
        return op
    }

    func updateObject(from protoForm: ProtoLWWOperation, container: CDOperation?) {
//        print("From protobuf LLWOp(\(protoForm.id.lamport))")
        self.version = protoForm.version
        self.peerID = protoForm.id.peerID.object()
        self.lamport = protoForm.id.lamport
        self.container = container
        self.state = .inDownstreamQueueMergedUnrendered


        switch protoForm.value {
        case .some(.int):
            self.type = .lwwInt
            self.lwwInt = protoForm.int
        case .some(.float):
            self.type = .lwwFloat
            self.lwwFloat = protoForm.float
        case .some(.date):
            //TODO: implement me
            self.type = .lwwDate
            fatalNotImplemented()
//            self.date = protoForm.date
        case .some(.boolean):
            self.type = .lwwBool
            self.lwwBool = protoForm.boolean
        case .some(.binaryData):
            self.type = .lwwBinaryData
            self.lwwBinaryData = protoForm.binaryData
        case .some(.refID):
            self.type = .lwwOperationID
            self.lwwLamport = protoForm.refID.lamport
            self.lwwPeerID = protoForm.refID.peerID.object()
        case .some(.string):
            self.type = .lwwString
            self.lwwString = protoForm.string
        case .none:
            fatalError("unknown LWW type")
        }
        
        let context = managedObjectContext!
        for protoItem in protoForm.deleteOperations {
            let _ = CDOperation.findOrCreateOperation(context: context, from: protoItem, container: self, type: .delete)
//            _ = CDOperation(context: context, from: protoItem, container: self)
        }
    }
    
    func lwwValue() -> Int64 {
        return lwwInt
    }

    func lwwValue() -> Float {
        return lwwFloat
    }

    func lwwValue() -> Date {
        return lwwDate!
    }
    
    func lwwValue() -> Bool {
        return lwwBool
    }

    func lwwValue() -> Data? {
        return lwwBinaryData
    }

    func lwwValue() -> CROperationID? {
        return CROperationID(lamport: lwwLamport, peerID: lwwPeerID)
    }

    func lwwValue() -> String {
        return lwwString!
    }
}


extension CDOperation {
    func protoLWWOperationRecurse() -> ProtoLWWOperation {
        var proto = ProtoLWWOperation.with {
            $0.version = self.version
            $0.id.lamport = self.lamport
            $0.id.peerID  = self.peerID.data
            switch self.type {
            case .lwwInt:
                $0.int = self.lwwInt
            case .lwwFloat:
                $0.float = self.lwwFloat
            case .lwwDate:
                fatalNotImplemented() //TODO: implement Date
            case .lwwBool:
                $0.boolean = self.lwwBool
            case .lwwBinaryData:
                $0.binaryData = self.lwwBinaryData ?? Data()
            case .lwwString:
                $0.string = self.lwwString!
            case .lwwOperationID:
                $0.refID.lamport = self.lwwLamport
                $0.refID.peerID = self.lwwPeerID.data
            default:
                fatalNotImplemented()
            }
        }

        for operation in self.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(operation.protoDeleteOperationRecurse())
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        self.state = .processed
        return proto
    }
}
