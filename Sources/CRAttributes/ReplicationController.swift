//
//  ReplicationController.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/11/2021.
//

import Foundation
import CoreData

public class ReplicationController {
    let replicatedContainerbackgroundContext: NSManagedObjectContext
    
    init(replicatedContainerbackgroundContext: NSManagedObjectContext) {
        self.replicatedContainerbackgroundContext = replicatedContainerbackgroundContext
    }
}
