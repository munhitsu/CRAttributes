//
//  CRDelete.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CRDeleteOp)
public class CRDeleteOp: CRAbstractOp {

}

extension CRDeleteOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CRDeleteOp> {
        return NSFetchRequest<CRDeleteOp>(entityName: "CRDeleteOp")
    }

    func protoOperation() -> ProtoDeleteOperation {
        return ProtoDeleteOperation.with {
            $0.base = super.protoOperation()
        }
    }
}
