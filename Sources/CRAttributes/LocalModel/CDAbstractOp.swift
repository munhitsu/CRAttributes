//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData
import SwiftProtobuf

//
//extension CDAbstractOp {
//
//
////    convenience init(context: NSManagedObjectContext, proto:ProtoBaseOperation) {
////        self.init(context:context)
////        self.version = proto.version
////        self.lamport = proto.id.lamport
////        self.peerID = proto.id.peerID.object()
////        self.parent
////        self.attribute
//    //  @objc   }
//
//
//    static func upstreamWaitingOperations() -> [CDAbstractOp] {
//        let context = CRStorageController.shared.localContainer.viewContext
//        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        request.predicate = NSPredicate(format: "upstreamQueue == true")
//        return try! context.fetch(request)
//    }
//
//
//
////    func protoOperation() -> ProtoBaseOperation {
////        return ProtoBaseOperation.with {
////            $0.version = version
////            $0.id = protoOperationID()
////            if let parent = parent { //TODO: implementation of null for message is language specific
////                $0.parentID = parent.protoOperationID()
////            }
////            if let attribute = attribute { //TODO: implementation of null for message is language specific
////                $0.attributeID = attribute.protoOperationID()
////            }
////        }
////    }
//
//}
