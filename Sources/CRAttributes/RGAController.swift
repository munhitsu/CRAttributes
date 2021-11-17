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
        context.performAndWait {
            for objectID in ids {
                //no other CDAbstractOp requires processing in the background queue
                if let cdOp = context.object(with: objectID) as? CDStringOp {
                    guard cdOp.state == .inUpstreamQueueRendered else {
    //                    print("skipping linking: \(cdOp)")
                        continue
                    }
                    print("linking: '\(cdOp.unicodeScalar)' \(cdOp)")
                    _ = cdOp.linkMe(context: context)
                }
            }
            try? context.save()
        }
//        print("merged ids: \(ids)")
        // fetch objects for each id
        
        // split based on state
        // for each state group handle it as a batch
    }
    
    
}
