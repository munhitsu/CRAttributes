//
//  ReplicationController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/11/2021.
//

import Foundation
import CoreData
import Combine

public class ReplicationController {
    let localContext: NSManagedObjectContext
    let replicationContext: NSManagedObjectContext
    
    private var observers: [AnyCancellable] = []
    
    
    init(localContext: NSManagedObjectContext,
         replicationContext: NSManagedObjectContext,
         skipTimer: Bool = false) {
        self.localContext = localContext
        self.replicationContext = replicationContext
        
        if !skipTimer {
            observers.append(Publishers.timer(interval: .seconds(1), times: .unlimited).sink { time in //TODO: change to 5s, ensure only one operation at the time, stop at the end of the test
                print("Processing merged upstream operations: \(time)")
                self.processUpsteamOperationsQueueAsync()
            })
        }
    }
}


//MARK: - Upstream
extension ReplicationController {
    func processUpsteamOperationsQueue() {
        //TODO: implement transactions as current form is unsafe
 
        localContext.performAndWait {
            let forests = self.protoOperationsForests()
            
            self.replicationContext.performAndWait {
                for protoForest in forests {
                    let _ = CDOperationsForest(context: self.replicationContext, from:protoForest)
                }
                try! self.replicationContext.save()
            }
            try! self.localContext.save()
        }
    }

    func processUpsteamOperationsQueueAsync() {
        localContext.perform { [weak self] in
            guard let self = self else { return }
            self.processUpsteamOperationsQueue()
        }
    }
    
    
    /**
     returns a list of ProtoOperationsForest ready for serialisation for further replication
     */
    func protoOperationsForests() -> [ProtoOperationsForest] {
        //        print("protoOperationsForests()")
        let context = localContext
        var forests:[ProtoOperationsForest] = []
        context.performAndWait {
            let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOpState.inUpstreamQueueRenderedMerged.rawValue])
            let queuedOperations:[CDAbstractOp] = try! context.fetch(request)
            
            var forest = ProtoOperationsForest()
            
            
            for queuedOperation in queuedOperations {
                // we pick operation and build a tree off it
                // as we progress operations are removed
                var branchRoot = queuedOperation
                while branchRoot.container?.state == .inUpstreamQueueRenderedMerged {
                    branchRoot = branchRoot.container!
                }
                if branchRoot.state == .inUpstreamQueueRenderedMerged {
                    var tree = ProtoOperationsTree()
                    if let id = branchRoot.container?.protoOperationID() {
                        tree.containerID = id //TODO: what with the null?
                    } else {
                        tree.containerID = CROperationID.zero.protoForm()
                    }
                    switch branchRoot {
                    case let op as CDObjectOp:
                        tree.objectOperation = ReplicationController.protoObjectOperationRecurse(op)
                    case let op as CDAttributeOp:
                        tree.attributeOperation = ReplicationController.protoAttributeOperationRecurse(op)
                    case let op as CDDeleteOp:
                        tree.deleteOperation = ReplicationController.protoDeleteOperationRecurse(op)
                    case let op as CDLWWOp:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(op)
                    case let op as CDStringOp:
                        //                    if op.contribution == "#" {
                        //                        print("debug")
                        //                    }
                        tree.stringInsertOperations.stringInsertOperations = ReplicationController.protoStringInsertOperationsLinkedList(op)
                    default:
                        fatalNotImplemented()
                    }
                    forest.trees.append(tree)
                }
            }
            if forest.trees.isEmpty == false {
                forest.version = 0
                forest.peerID = localPeerID.data
                forests.append(forest)
            }
            // TODO: split into forests when one is getting too big (2 MB is the CloudKit Operation limit but we can still compress - one forrest is one CloudKit record)
            
            //        print("forests: \(forests)")
            //        for forest in forests {
            //            print("trees: \(forest.trees.count)")
            //        }
        }
        return forests
    }
    
    static func protoObjectOperationRecurse(_ operation: CDObjectOp) -> ProtoObjectOperation {
        var proto = ProtoObjectOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.rawType = operation.rawType
        }
        //        print("ObjectOperation \(proto.id.lamport)")
        
        
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation {
                case let op as CDDeleteOp:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                case let op as CDAttributeOp:
                    proto.attributeOperations.append(protoAttributeOperationRecurse(op))
                case let op as CDObjectOp:
                    proto.objectOperations.append(protoObjectOperationRecurse(op))
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        operation.state = .processed
        return proto
    }
    
    static func protoDeleteOperationRecurse(_ operation: CDDeleteOp) -> ProtoDeleteOperation {
        let proto = ProtoDeleteOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
        }
        //        assert(operation.container?.containedOperations?.contains(operation) ?? false)
        //        print("DeleteOperation \(proto.id.lamport)")
        
        operation.state = .processed
        return proto
    }
    
    static func protoAttributeOperationRecurse(_ operation: CDAttributeOp) -> ProtoAttributeOperation {
        var proto = ProtoAttributeOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.name = operation.name!
            $0.rawType = operation.rawType
        }
        //        print("AttributeOperation \(proto.id.lamport)")
        
        var headStringOperation:CDStringOp? = nil
        
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation {
                case let op as CDDeleteOp:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                case let op as CDLWWOp:
                    proto.lwwOperations.append(protoLWWOperationRecurse(op))
                case let op as CDStringOp:
                    if op.prev == nil { // it will be only a new string in a new attribute in this scenario
                        headStringOperation = op
                    }
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        var node = headStringOperation
        while node != nil {
            if let protoForm = protoStringInsertOperationRecurse(node!) {
                proto.stringInsertOperations.append(protoForm)
            }
            node = node!.next
        }
        operation.state = .processed
        return proto
    }
    
    static func protoLWWOperationRecurse(_ operation: CDLWWOp) -> ProtoLWWOperation {
        var proto = ProtoLWWOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            switch (operation.container as! CDAttributeOp).type {
            case .int:
                $0.int = operation.int
            case .float:
                $0.float = operation.float
            case .date:
                fatalNotImplemented() //TODO: implement Date
            case .boolean:
                $0.boolean = operation.boolean
            case .string:
                $0.string = operation.string!
            case .mutableString:
                fatalNotImplemented()
            }
        }
        //        print("LWWOperation \(proto.id.lamport)")
        
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation {
                case let op as CDDeleteOp:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(op))
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        operation.state = .processed
        return proto
    }
    
    static func protoStringInsertOperationRecurse(_ operation: CDStringOp) -> ProtoStringInsertOperation? {
        guard operation.type != .head else { return nil }
        var proto = ProtoStringInsertOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.contribution = operation.insertContribution
            $0.parentID.lamport = operation.parent?.lamport ?? 0
            $0.parentID.peerID = operation.parent?.peerID.data ?? UUID.zero.data
        }
        //        print("StringInsertOperation \(proto.id.lamport)")
        //        assert(operation.upstreamQueueOperation)
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.childOperations?.allObjects ?? [] {
            guard let operation = operation as? CDStringOp else { continue }
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(protoStringDeleteOperation(operation))
                case .insert:
                    break // we can ignore it as it will be picked up by .next
                default:
                    print(operation)
                    fatalError("unsupported subOperation")
                }
            }
        }
        operation.state = .processed
        return proto
    }

    static func protoStringDeleteOperation(_ operation: CDStringOp) -> ProtoDeleteOperation {
        let proto = ProtoDeleteOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
        }
        //        assert(operation.container?.containedOperations?.contains(operation) ?? false)
        //        print("DeleteOperation \(proto.id.lamport)")
        
        operation.state = .processed
        return proto
    }

    // returns a list of linked string operations (including deletes as sub operations)
    static func protoStringInsertOperationsLinkedList(_ operation: CDStringOp) -> [ProtoStringInsertOperation] {
        assert(operation.state == .inUpstreamQueueRenderedMerged)
        //TODO: don't add head
        var protoOperations:[ProtoStringInsertOperation] = []
        if let protoForm = protoStringInsertOperationRecurse(operation) {
            protoOperations.append(protoForm)
        }
        //        print(protoOperations[0])
        
        //        print("###")
        //        print("prev: \(String(describing: operation.prev))")
        //        print("operation: \(operation)")
        //        print("next: \(String(describing: operation.next))")
        
        // going left
        var node:CDStringOp? = operation.prev
        while node != nil && node!.state == .inUpstreamQueueRenderedMerged {
            if let protoForm = protoStringInsertOperationRecurse(node!) {
                protoOperations.insert(protoForm, at: 0)
            }
            node = node?.prev
        }
        
        // going right
        node = operation.next
        while node != nil && node!.state == .inUpstreamQueueRenderedMerged {
            if let protoForm = protoStringInsertOperationRecurse(node!) {
                protoOperations.append(protoForm)
            }
            node = node?.next
        }
        //        print("string list:")
        //        for item in protoOperations {
        //            try! print(item.jsonString())
        //        }
        return protoOperations
    }
}


//MARK: - Downstream
extension ReplicationController {
    // TODO: (later) introduce RGA Split and consolidate operations here, this will solve the recursion risk
    
    func processDownstreamForest(forest cdForestObjectID: NSManagedObjectID) {
        fatalNotImplemented()
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        let localContext = CRStorageController.shared.localContainerBackgroundContext
        
        let cdForest = remoteContext.object(with: cdForestObjectID) as! CDOperationsForest
        
        localContext.performAndWait {
            let protoForest = cdForest.protoStructure()
            for tree in protoForest.trees {
                let containerID = CROperationID(from: tree.containerID)
                //                let parentID = CROperationID(from: tree.parentID)
                
                var containerOp:CDAbstractOp?
                
                if containerID.isZero() {
                    // this means independent tree
                    containerOp = nil
                } else {
                    guard let containerOp = CDAbstractOp.fetchOperation(from: containerID, in: localContext) else {
                        fatalNotImplemented()
                    }
                    
                }
                
            }
            try? localContext.save()
            fatalNotImplemented()
        }
    }
}
