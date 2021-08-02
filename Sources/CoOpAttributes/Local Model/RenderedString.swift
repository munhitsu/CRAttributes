//
//  RenderedString.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 14/07/2021.
//

import Foundation
import CoreData

@objc(RenderedString)
public class RenderedString: NSManagedObject {
    
}

extension RenderedString {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RenderedString> {
        return NSFetchRequest<RenderedString>(entityName: "RenderedString")
    }

    @NSManaged public var string: Data?
}
