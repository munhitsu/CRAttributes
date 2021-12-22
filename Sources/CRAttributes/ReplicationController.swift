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
        let context = localContext
        var forests:[ProtoOperationsForest] = []
        context.performAndWait {
            var forest = ProtoOperationsForest()

            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOperationState.inUpstreamQueueRenderedMerged.rawValue])
            let queuedOperations:[CDOperation] = try! context.fetch(request)
                        
            for op in queuedOperations {
                if op.state == .processed { continue } // we will keep finding operations that we processed as a part of previous branches
                assert(op.rawState == CDOperationState.inUpstreamQueueRenderedMerged.rawValue)
                // we pick operation and build a tree off it
                // as we progress operations are removed
                var branchRoot = op
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
                        tree.objectOperation = branchRoot.protoObjectOperationRecurse()
                    case .attribute:
                        tree.attributeOperation = branchRoot.protoAttributeOperationRecurse()
                    case .delete:
                        tree.deleteOperation = branchRoot.protoDeleteOperationRecurse()
                    case .lwwInt:
                        tree.lwwOperation = branchRoot.protoLWWOperationRecurse()
                    case .lwwFloat:
                        tree.lwwOperation = branchRoot.protoLWWOperationRecurse()
                    case .lwwDate:
                        tree.lwwOperation = branchRoot.protoLWWOperationRecurse()
                    case .lwwBool:
                        tree.lwwOperation = branchRoot.protoLWWOperationRecurse()
                    case .lwwString:
                        tree.lwwOperation = branchRoot.protoLWWOperationRecurse()
                    case .stringInsert:
                        tree.stringInsertOperationsList.stringInsertOperations = branchRoot.protoStringInsertOperationsLinkedList()
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
        }
        return forests
    }

}


//MARK: - Downstream
extension ReplicationController {
    // TODO: (later) maybe introduce RGA Split and consolidate operations here, this will solve the recursion risk
    
    func processDownstreamForest(forest cdForestObjectID: NSManagedObjectID) {
        assert(cdForestObjectID.isTemporaryID == false)
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        let localContext = CRStorageController.shared.localContainerBackgroundContext
        
        remoteContext.performAndWait {
            let cdForest = remoteContext.object(with: cdForestObjectID) as! CDOperationsForest
            let protoForest = cdForest.protoStructure()
            localContext.performAndWait {
                protoForest.restore(context: localContext)
                try! localContext.save()
            }
        }
    }
    func processDownstreamForestAsync(forest cdForestObjectID: NSManagedObjectID) {
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        remoteContext.perform { [self] in
            self.processDownstreamForest(forest: cdForestObjectID)
        }
    }
}
