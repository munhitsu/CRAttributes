//
//  CDOperation+Ghost.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 20/12/2021.
//

import Foundation
import CoreData

extension CDOperation {
    static func createGhost(context: NSManagedObjectContext, id: CROperationID) -> CDOperation {
        let op = CDOperation(context: context)
        op.version = 0
        op.peerID = id.peerID
        op.lamport = id.lamport
        op.type = .ghost
        op.state = .inDownstreamQueue
        return op
    }
    
    // there is no protobuf init as protobuf existence makes ghost materialise
}
