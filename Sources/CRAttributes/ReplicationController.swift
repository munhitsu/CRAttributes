//
//  ReplicationController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/11/2021.
//

import Foundation
import CoreData

public class ReplicationController {
    let localContext: NSManagedObjectContext
    let replicationContext: NSManagedObjectContext
    
    init(localContext: NSManagedObjectContext,
         replicationContext: NSManagedObjectContext) {
        self.localContext = localContext
        self.replicationContext = replicationContext
    }
}




// Downstream
extension ReplicationController {
    // TODO: (later) introduce RGA Split and consolidate operations here, this will solve the recursion risk
    
    func processDownstreamForest(forest cdForestObjectID: NSManagedObjectID) {
        fatalNotImplemented()
        let remoteContext = CRStorageController.shared.replicationContainer.viewContext //TODO: move to background
        let localContext = CRStorageController.shared.localContainer.viewContext

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
                    containerOp = CDAbstractOp.operation(from: containerID, in: localContext)
                    if containerOp == nil {
                        containerOp = nil
                    }
                }
                
//                let root = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, container: containerOp, waitingForContainer: true)
//                try? localContext.save()
                
                // let's 1st load it as a branch unless it's self defined as an absolute root
                
                
//
//                if containerID.isZero() {
//                    // this means independent tree
//                    // just load me
//                    _ = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, container: nil)
//                    print("> loaded the absolute root")
//                    try? localContext.save()
//                } else {
//                    if let containerOp = CRAbstractOp.operation(from: containerID, in: localContext) {
//                        // just load me
//                        // but link root op with the correct parent
//                        _ = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, container: containerOp)
//                        print("> loaded and linked a branch")
//                        try? localContext.save()
//                    } else {
//                        // just load me
//                        // but mark root op as in the downstream queue
//                        let root = CRStorageController.rootAfterTreeToOperations(context: localContext, tree: tree, container: nil)
//                        root?.waitingForContainer = true
//                        //record somewhere the containerID
//                        root?.peerID = containerID.peerID
//                        root?.lamport = containerID.lamport
//                        root?.waitingForContainer = true
//                        print("> loaded a wating branch")
//                        try? localContext.save()
//                    }
//                }
            }
            
            // let's pick up all the branches and try to link them
//            let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
//            request.predicate = NSPredicate(format: "waitingForContainer == true")
//            let branches:[CDAbstractOp]? = try? localContext.fetch(request)
//            for branchRoot in branches ?? [] {
////                if let containerOp = CDAbstractOp.operation(fromLamport: branchRoot.containerLamport, fromPeerID: branchRoot.containerPeerID, in: localContext) {
////                    branchRoot.container = containerOp
////                    // maybe we want to perform a funciton on the operation to perform linking
////                }
//            }
            try? localContext.save()
        }
    }
    
    // creates operations
    // returns root CDOperation
    static func rootAfterTreeToOperations(context: NSManagedObjectContext, tree protoTree: ProtoOperationsTree, container: CDAbstractOp?) -> CDAbstractOp? {
        var root:CDAbstractOp?=nil
        
        switch protoTree.value {
        case .some(.objectOperation):
            root = CDObjectOp(context: context, from: protoTree.objectOperation, container: container)
            print("Restored ObjectOp(\(root!.lamport)")
        case .some(.attributeOperation):
            root = CDAttributeOp(context: context, from: protoTree.attributeOperation, container: container)
            print("Restored AttributeOp(\(root!.lamport)")
        case .some(.deleteOperation):
            root = CDDeleteOp(context: context, from: protoTree.deleteOperation, container: container)
            print("Restored DeleteOp(\(root!.lamport)")
        case .some(.lwwOperation):
            root = CDLWWOp(context: context, from: protoTree.lwwOperation, container: container)
            print("Restored LWWOp(\(root!.lamport)")
        case .some(.stringInsertOperations):
            root = CDStringOp.restoreLinkedList(context: context, from: protoTree.stringInsertOperations.stringInsertOperations, container: container as? CDAttributeOp)
            print("Ignoring StringInsertOp(\(root!.lamport)")
        case .none:
            fatalNotImplemented()
        case .some(_):
            fatalNotImplemented()
        }
        return root
    }
    
    
}
 

// Upstream
extension ReplicationController {
    func processUpsteamOperationsQueue() {
        //TODO: how to convert it to context.perform ?
        let contextLocal = CRStorageController.shared.localContainer.viewContext
        let contextRemote = CRStorageController.shared.replicationContainer.viewContext
        
        let forests = protoOperationsForests()
        
        for protoForest in forests {
            let _ = CDOperationsForest(context: contextRemote, from:protoForest)
        }
        do {
            try contextRemote.save()
            try contextLocal.save()
        } catch {
            fatalError("couldn't save")
        }
    }
    
    func protoOperationsForests() -> [ProtoOperationsForest] {
//        print("protoOperationsForests()")
        let context = localContext
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOpState.inDownstreamQueueMergedUnrendered.rawValue])
        let queuedOperations:[CDAbstractOp] = try! context.fetch(request)
        
        var forests:[ProtoOperationsForest] = []
        var forest = ProtoOperationsForest()
        
        
        for queuedOperation in queuedOperations {
            // we pick operation and build a tree off it
            // as we progress operations are removed
            var branchRoot = queuedOperation
            while branchRoot.container?.state == .inDownstreamQueueMergedUnrendered {
                branchRoot = branchRoot.container!
            }
            if branchRoot.state == .inDownstreamQueueMergedUnrendered {
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
            if operation.state == .inDownstreamQueueMergedUnrendered {
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
            if operation.state == .inDownstreamQueueMergedUnrendered {
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
            proto.stringInsertOperations.append(protoStringInsertOperationRecurse(node!))
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
            if operation.state == .inDownstreamQueueMergedUnrendered {
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
    
    static func protoStringInsertOperationRecurse(_ operation: CDStringOp) -> ProtoStringInsertOperation {
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
        for operation in operation.containedOperations() {
            if operation.state == .inDownstreamQueueMergedUnrendered {
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

    // returns a list of linked string operations (including deletes as sub operations)
    static func protoStringInsertOperationsLinkedList(_ operation: CDStringOp) -> [ProtoStringInsertOperation] {
        assert(operation.state == .inDownstreamQueueMergedUnrendered)
        var protoOperations:[ProtoStringInsertOperation] = [protoStringInsertOperationRecurse(operation)]
//        print(protoOperations[0])

//        print("###")
//        print("prev: \(String(describing: operation.prev))")
//        print("operation: \(operation)")
//        print("next: \(String(describing: operation.next))")

        // going left
        var node:CDStringOp? = operation.prev
        while node != nil && node!.state == .inDownstreamQueueMergedUnrendered {
            let protoForm = protoStringInsertOperationRecurse(node!)
//            print(protoForm)
            protoOperations.insert(protoForm, at: 0)
            node = node?.prev
        }

        // going right
        node = operation.next
        while node != nil && node!.state == .inDownstreamQueueMergedUnrendered {
            let protoForm = protoStringInsertOperationRecurse(node!)
//            print(protoForm)
            protoOperations.append(protoForm)
            node = node?.next
        }
//        print("string list:")
//        for item in protoOperations {
//            try! print(item.jsonString())
//        }
        return protoOperations
    }
}
