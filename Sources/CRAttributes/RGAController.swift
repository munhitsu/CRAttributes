//
//  CRRGAController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 01/11/2021.
//

import Foundation
import CoreData
import Combine


/**
 manages the RGA Form
 a placeholder for redered form operations as well
 */
public class RGAController {
    let localContainerBackgroundContext: NSManagedObjectContext

    private var observers: [AnyCancellable] = []
    
    /**
     it will instantly subscribe to the merge events
     */
    init(localContainerBackgroundContext: NSManagedObjectContext) {
        self.localContainerBackgroundContext = localContainerBackgroundContext

        //source: https://www.donnywals.com/observing-changes-to-managed-objects-across-contexts-with-combine/
        observers.append(NotificationCenter.default
            .publisher(for: NSManagedObjectContext.didMergeChangesObjectIDsNotification, object: localContainerBackgroundContext)
            .sink(receiveValue: { [weak self] notification in
            guard let self = self else { return }
            if let inserted_ids = notification.userInfo?[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID> {
                self.handleContextDidMerge(ids: inserted_ids, context: self.localContainerBackgroundContext)
            }
        }))

    }
    
    
    //TODO: check occasionally for .inUpstreamQueueRendered and retry linking

    func handleContextDidMerge(ids: Set<NSManagedObjectID>, context: NSManagedObjectContext) {
        assert(!Thread.isMainThread)
        assert(context == localContainerBackgroundContext)
        context.perform { // if we performAndWait then we can't save - it's relying on the merge save
            for objectID in ids {
                //no other CDAbstractOp requires processing in the background queue
                if let op = context.object(with: objectID) as? CDOperation {
                    guard op.type == .stringInsert || op.type == .delete else { continue }
                    guard op.state == .inUpstreamQueueRendered ||
                            op.state == .inDownstreamQueueMergedUnrendered else { continue }
//                    print("linking: '\(op.unicodeScalar)' \(op)")
                    let success = op.linkMe(context: context)
                    print("linking succeded:\(success)")
                }
            }
            try! context.save()
        }
    }
    
    func linkUnlinked() {
        print("link unlinked")
        localContainerBackgroundContext.performAndWait {
            let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOperationState.inUpstreamQueueRendered.rawValue])
            let response = try! localContainerBackgroundContext.fetch(request)
            for op in response {
                assert(op.state == .inUpstreamQueueRendered)
                let success = op.linkMe(context: localContainerBackgroundContext)
                print("linking succeded:\(success)")
            }
            try! localContainerBackgroundContext.save()
        }
    }
    func linkUnlinkedAsync() {
        localContainerBackgroundContext.perform { [weak self] in
            guard let self = self else { return }
            self.linkUnlinked()
        }
    }
}
