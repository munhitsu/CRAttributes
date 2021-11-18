//
//  CRRGAController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 01/11/2021.
//

import Foundation
import CoreData

public class RGAController {
    let localBackgroundContext: NSManagedObjectContext

    init(localBackgroundContext: NSManagedObjectContext) {
        self.localBackgroundContext = localBackgroundContext
    }
    
    
    //TODO: check occasionally for .inUpstreamQueueRendered and retry linking

    func handleContextDidMerge(ids: Set<NSManagedObjectID>, context: NSManagedObjectContext) {
        assert(!Thread.isMainThread)
        assert(context == localBackgroundContext)
        context.performAndWait { // I don't think it's needed
            for objectID in ids {
                //no other CDAbstractOp requires processing in the background queue
                if let op = context.object(with: objectID) as? CDStringOp {
                    guard op.state == .inUpstreamQueueRendered else { continue }
//                    print("linking: '\(op.unicodeScalar)' \(op)")
                    _ = op.linkMe(context: context)
                }
            }
            try? context.save()
        }
    }
    
    func linkUnlinked() {
        localBackgroundContext.performAndWait {
            let request:NSFetchRequest<CDStringOp> = CDStringOp.fetchRequest()
            request.returnsObjectsAsFaults = false
            request.predicate = NSPredicate(format: "rawType == 0 and rawState == 1") // inUpstreamQueueRendered
            let response = try! localBackgroundContext.fetch(request)
            for op in response {
                _ = op.linkMe(context: localBackgroundContext)
            }
        }
    }
    func linkUnlinkedAsync() {
        localBackgroundContext.perform { [weak self] in
            guard let self = self else { return }
            self.linkUnlinked()
        }
    }
}
