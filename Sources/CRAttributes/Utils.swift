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


public func fatalNotImplemented(_ text: String = "") {
    fatalError("Not Implemented: \(text)")
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


extension Array {
    mutating func replaceElements(in range: NSRange, with elements: [Element]) {
        if range.length == 0 {
            self.insert(contentsOf: elements, at: range.location)
        } else {
            self.replaceSubrange(range.location...(range.location+range.length-1), with: elements)
        }
    }
}

extension String {
    mutating func replaceCharacters(in range: NSRange, with characters: String) {
        let locationIndex = self.index(self.startIndex, offsetBy: String.IndexDistance(range.location))

        if range.length == 0 {
            self.insert(contentsOf: characters, at: locationIndex)
        } else {
            let endIndex = self.index(locationIndex, offsetBy: String.IndexDistance(range.length-1))
            self.replaceSubrange(locationIndex...endIndex, with: characters)
        }
    }
}
