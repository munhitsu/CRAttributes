//
//  CoOpDelete.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 13/07/2021.
//

import Foundation
import CoreData

@objc(CoOpDelete)
public class CoOpDelete: CoOpAbstractOperation {

}

extension CoOpDelete {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpDelete> {
        return NSFetchRequest<CoOpDelete>(entityName: "CoOpDelete")
    }


}
