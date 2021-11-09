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
    
    func handleContextDidMerge(ids: Set<NSManagedObjectID>, context: NSManagedObjectContext) {
        assert(!Thread.isMainThread)
        for objectID in ids {
            print("merged id: \(objectID)")
            //no other CDAbstractOp requires processing in the background queue
            if let cdOp = context.object(with: objectID) as? CDStringOp {
                print(cdOp)
                if cdOp.state == .inUpstreamQueueRendered {
                    if cdOp.type == .insert {
                    // find or create insertion point
                    // perform insert (link)
                    } else if cdOp.type == .delete {
                        fatalNotImplemented()
                    }
                }
            }
        }
//        print("merged ids: \(ids)")
        // fetch objects for each id
        
        // split based on state
        // for each state group handle it as a batch
    }
    
    
}
