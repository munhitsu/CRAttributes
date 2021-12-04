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
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOperationState.inUpstreamQueueRenderedMerged.rawValue])
            let queuedOperations:[CDOperation] = try! context.fetch(request)
            
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
                    switch branchRoot.type {
                    case .object:
                        tree.objectOperation = ReplicationController.protoObjectOperationRecurse(branchRoot)
                    case .attribute:
                        tree.attributeOperation = ReplicationController.protoAttributeOperationRecurse(branchRoot)
                    case .delete:
                        tree.deleteOperation = ReplicationController.protoDeleteOperationRecurse(branchRoot)
                    case .lwwInt:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(branchRoot)
                    case .lwwFloat:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(branchRoot)
                    case .lwwDate:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(branchRoot)
                    case .lwwBool:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(branchRoot)
                    case .lwwString:
                        tree.lwwOperation = ReplicationController.protoLWWOperationRecurse(branchRoot)
                    case .stringInsert:
                        tree.stringInsertOperations.stringInsertOperations = ReplicationController.protoStringInsertOperationsLinkedList(branchRoot)
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
    
    static func protoObjectOperationRecurse(_ operation: CDOperation) -> ProtoObjectOperation {
        assert(operation.type == .object)
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
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(operation))
                case .attribute:
                    proto.attributeOperations.append(protoAttributeOperationRecurse(operation))
                case .object:
                    proto.objectOperations.append(protoObjectOperationRecurse(operation))
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        operation.state = .processed
        return proto
    }
    
    static func protoDeleteOperationRecurse(_ operation: CDOperation) -> ProtoDeleteOperation {
        assert(operation.type == .delete)
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
    
    static func protoAttributeOperationRecurse(_ operation: CDOperation) -> ProtoAttributeOperation {
        assert(operation.type == .attribute)
        var proto = ProtoAttributeOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.name = operation.attributeName!
            $0.rawType = operation.rawAttributeType
        }
        //        print("AttributeOperation \(proto.id.lamport)")
        
        var headStringOperation:CDOperation? = nil
        
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(operation))
                case .lwwInt:
                    proto.lwwOperations.append(protoLWWOperationRecurse(operation))
                case .lwwFloat:
                    proto.lwwOperations.append(protoLWWOperationRecurse(operation))
                case .lwwDate:
                    proto.lwwOperations.append(protoLWWOperationRecurse(operation))
                case .lwwBool:
                    proto.lwwOperations.append(protoLWWOperationRecurse(operation))
                case .lwwString:
                    proto.lwwOperations.append(protoLWWOperationRecurse(operation))
                case .stringInsert:
                    if operation.prev == nil { // it will be only a new string in a new attribute in this scenario
                        headStringOperation = operation
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
    
    static func protoLWWOperationRecurse(_ operation: CDOperation) -> ProtoLWWOperation {
        var proto = ProtoLWWOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            switch operation.type {
            case .lwwInt:
                $0.int = operation.lwwInt
            case .lwwFloat:
                $0.float = operation.lwwFloat
            case .lwwDate:
                fatalNotImplemented() //TODO: implement Date
            case .lwwBool:
                $0.boolean = operation.lwwBool
            case .lwwString:
                $0.string = operation.lwwString!
            default:
                fatalNotImplemented()
            }
        }
        //        print("LWWOperation \(proto.id.lamport)")
        
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.containedOperations() {
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(protoDeleteOperationRecurse(operation))
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        operation.state = .processed
        return proto
    }
    
    static func protoStringInsertOperationRecurse(_ operation: CDOperation) -> ProtoStringInsertOperation? {
        guard operation.type != .stringHead else { return nil }
        var proto = ProtoStringInsertOperation.with {
            $0.version = operation.version
            $0.id.lamport = operation.lamport
            $0.id.peerID  = operation.peerID.data
            $0.contribution = operation.stringInsertContribution
            $0.parentID.lamport = operation.parent?.lamport ?? 0
            $0.parentID.peerID = operation.parent?.peerID.data ?? UUID.zero.data
        }
        //        print("StringInsertOperation \(proto.id.lamport)")
        //        assert(operation.upstreamQueueOperation)
        //        assert(operation.containedOperations as! Set<CDAbstractOp> == Set(operation.containedOps()))
        for operation in operation.childOperations?.allObjects ?? [] {
            guard let operation = operation as? CDOperation else { continue }
            if operation.state == .inUpstreamQueueRenderedMerged {
                switch operation.type {
                case .delete:
                    proto.deleteOperations.append(protoStringDeleteOperation(operation))
                case .stringInsert:
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

    //TODO: merge with delete
    static func protoStringDeleteOperation(_ operation: CDOperation) -> ProtoDeleteOperation {
        assert(operation.type == .delete)
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
    static func protoStringInsertOperationsLinkedList(_ operation: CDOperation) -> [ProtoStringInsertOperation] {
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
        var node:CDOperation? = operation.prev
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
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        let localContext = CRStorageController.shared.localContainerBackgroundContext
        
        let cdForest = remoteContext.object(with: cdForestObjectID) as! CDOperationsForest
        
        localContext.performAndWait {
            let protoForest = cdForest.protoStructure()
            protoForest.restore(context: localContext)
            try! localContext.save()
        }
    }
}
