//
//  utils.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 12/01/2021.
//

import Foundation
import CoreData
import os.signpost

let signpostLogHandler = OSLog(subsystem: "time", category: .pointsOfInterest)


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

public func printTimeElapsedWhenRunningCode(title: StaticString = "", operation:() -> Void) {
    os_signpost(.begin, log: signpostLogHandler, name: title)
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    print("Time elapsed for \(title): \(timeElapsed) s.")
    os_signpost(.end, log: signpostLogHandler, name: title)
}

public func timeElapsedInSecondsWhenRunningCode(title: StaticString = "", operation: () -> Void) -> Double {
    os_signpost(.begin, log: signpostLogHandler, name: title)
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    os_signpost(.end, log: signpostLogHandler, name: title)
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



extension Data {
    func object<T>() -> T { withUnsafeBytes { $0.load(as: T.self) } }
}
