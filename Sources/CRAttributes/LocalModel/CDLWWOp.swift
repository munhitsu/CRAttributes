//
//  File.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData


//extension CDLWWOp {
//
//
//    
//    static func allObjects() -> [CDLWWOp]{
//        let context = CRStorageController.shared.localContainer.viewContext
//        let request:NSFetchRequest<CDLWWOp> = CDLWWOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        return try! context.fetch(request)
//    }
//
////    func protoOperation() -> ProtoLWWOperation {
////        return ProtoLWWOperation.with {
////            $0.base = super.protoOperation()
////            switch attribute?.type {
////            case .none:
////                fatalNotImplemented()
////            case .some(.int):
////                $0.int = int
////            case .some(.float):
////                $0.float = float
////            case .some(.date):
////                fatalNotImplemented() //TODO: implement Date
////            case .some(.boolean):
////                $0.boolean = boolean
////            case .some(.string):
////                $0.string = string!
////            case .some(.mutableString):
////                fatalNotImplemented()
////            }
////        }
////    }
//}
