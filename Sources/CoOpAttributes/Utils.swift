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

public func flushAllCoreData(_ container: NSPersistentContainer) {
    let context = container.viewContext
    // get all entities and loop over them
    let entityNames = container.managedObjectModel.entities.map({ $0.name!})
    entityNames.forEach { entityName in
        // now the batch flush
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

public func printTimeElapsedWhenRunningCode(title: String = "", operation:() -> Void) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
}

public func timeElapsedInSecondsWhenRunningCode(operation: () -> Void) -> Double {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    return Double(timeElapsed)
}

public struct Stack<Element> {
    var items = [Element]()
    mutating func push(_ item: Element) {
        items.append(item)
    }
    mutating func pop() -> Element {
        return items.removeLast()
    }
}
