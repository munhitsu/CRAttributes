//
//  utils.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 12/01/2021.
//

import Foundation
import CoreData

public func fatalNotImplemented() {
    fatalError("Not Implemented")
}



public func flushAllCoreData(container: NSPersistentContainer) {
    let context = container.viewContext
    // get all entities and loop over them

    // now the batch flush
    let entityNames = container.managedObjectModel.entities.map({ $0.name!})
    entityNames.forEach { entityName in
    print("Flushing \(entityName)")
    let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)

    do {
            try context.execute(deleteRequest)
            try context.save()
        } catch let error as NSError {
            fatalError("Unresolved error \(error), \(error.userInfo)")
        }
    }
}
