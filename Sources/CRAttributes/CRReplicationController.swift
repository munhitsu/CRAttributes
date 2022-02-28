//
//  ReplicationController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/11/2021.
//

import Foundation
import CoreData
import Combine

public class CRReplicationController {
    let localContext: NSManagedObjectContext
    let replicationContext: NSManagedObjectContext
    
    private var observers: [AnyCancellable] = []
    
    var lastReplicationHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
//            print("ReplicationController.\(#function): start")
            guard let token = lastReplicationHistoryToken, let data = try? NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true) else { return }
            do {
                try data.write(to: replicationHistoryTokenFile)
            } catch {
                print("###\(#function): Could not write token data: \(error)")
            }
        }
    }
    
    lazy var replicationHistoryTokenFile: URL = {
//        print("ReplicationController.\(#function): tokenFile start")
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CRAttributes", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Could not create persistent container URL: \(error)")
            }
        }
        let fileURL = url.appendingPathComponent("historyToken.data", isDirectory: false)
//        print("got the token URL: \(fileURL)")
        return fileURL
    }()
    
    public init(localContext: NSManagedObjectContext,
         replicationContext: NSManagedObjectContext,
         processLocalChanges: Bool = true,
         processRemoteChanges: Bool = true) {
        self.localContext = localContext
        self.replicationContext = replicationContext
        loadHistoryToken()
        
        if processLocalChanges {
            observers.append(Publishers.timer(interval: .seconds(1), times: .unlimited).sink { [weak self] time in //TODO: ensure only one operation at the time, stop at the end of the test
                guard let self = self else { return }
                Task {
                    await self.processUpstreamOperationsQueue()
                }
            })
        }

        if processRemoteChanges {
            observers.append(NotificationCenter.default.publisher(for: .NSPersistentStoreRemoteChange, object: replicationContext.persistentStoreCoordinator).sink { [weak self] notification in
                guard let self = self else { return }
                Task {
                    await self.processDownstreamHistory()
                }
                })
            Task {
                await self.processDownstreamHistory()
            }
        }
    }
}

//MARK: - Token
extension CRReplicationController {
    private func loadHistoryToken() {
      do {
        let tokenData = try Data(contentsOf: replicationHistoryTokenFile)
        lastReplicationHistoryToken = try NSKeyedUnarchiver
          .unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
      } catch {
        // log any errors
      }
    }
}


//MARK: - Upstream
extension CRReplicationController {
    public func processUpstreamOperationsQueue() async {
        //TODO: implement transactions as current form is unsafe
        
        let localBackgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        localBackgroundContext.parent = localContext


        // so we are spawnig a new subcontext to annotate objects that we are migrating them
        // when done we will save
        var forests:[ProtoOperationsForest] = []
        localBackgroundContext.performAndWait { //TODO: task is started inside of the funciton so no need for performAndWait
            forests.append(contentsOf: self.protoOperationsForests(context: localBackgroundContext))
        }

        self.replicationContext.performAndWait {
            for protoForest in forests {
                print("Processing Upstream Queue (forest)")
                let _ = CDOperationsForest(context: self.replicationContext, from:protoForest)
            }
            try! self.replicationContext.save()
            //TODO: move triggering update on the localContext after this save is done (async)??
        }

        localBackgroundContext.performAndWait {
            try! localBackgroundContext.save()
        }

    }

//    func processUpstreamOperationsQueueAsync() {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            self.processUpsteamOperationsQueue()
//        }
//    }
    
    
    /**
     returns a list of ProtoOperationsForest ready for serialisation for further replication
     */
    func protoOperationsForests(context: NSManagedObjectContext) -> [ProtoOperationsForest] {
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
extension CRReplicationController {
    // TODO: (later) maybe introduce RGA Split and consolidate operations here, this will solve the recursion risk

    /**
     start me when the application starts
     */
    //TODO: (optimise) filterout local changes based on the author/context...
    public func processDownstreamHistory() async {
//        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        let remoteContext = replicationContext
        await remoteContext.perform {
            print("Fetching history after: \(self.lastReplicationHistoryToken)")
            let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: self.lastReplicationHistoryToken)
            
            guard let historyResult = try? remoteContext.execute(fetchHistoryRequest) as? NSPersistentHistoryResult,
                  let history = historyResult.result as? [NSPersistentHistoryTransaction]
            else {
                fatalError("Could not convert history result to transactions.")
            }
            
            for transaction in history.reversed() {
//                let token = transaction.token
//                let transactionNumber = transaction.transactionNumber
//                let context = transaction.contextName ?? "unknown context"
//                let author = transaction.author ?? "unknown author"
                guard let changes = transaction.changes else { continue }
                
                for change in changes {
                    let objectID = change.changedObjectID
//                    let changeID = change.changeID
//                    let transaction = change.transaction
                    let changeType = change.changeType
                    
                    switch changeType {
                    case .insert:
//                        let insertedObject:CDOperationsForest = remoteContext.object(with: objectID) as! CDOperationsForest
                        Task {
                            await self.processDownstreamForest(forest: objectID)
                        }
                    case .update:
                        fatalError("There shall be no updates")
                    case .delete:
                        fatalError("There shall be no deletions")
                    @unknown default:
                        fatalError("There shall be no unknowns")
                    }
                }
            }
            if let newToken = history.last?.token {
                self.lastReplicationHistoryToken = newToken
            }
        }
    }

    public func processDownstreamForest(forest cdForestObjectID: NSManagedObjectID) async {
        assert(cdForestObjectID.isTemporaryID == false)
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        let localContext = CRStorageController.shared.localContainerBackgroundContext
        
        let protoForest:ProtoOperationsForest = await remoteContext.perform {
            let cdForest = remoteContext.object(with: cdForestObjectID) as! CDOperationsForest
            return cdForest.protoStructure()
        }
        await localContext.perform {
            protoForest.restore(context: localContext)
            try! localContext.save()
        }
    
    }

}
