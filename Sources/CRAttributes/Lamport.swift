
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
import AppKit
#endif


public var lastLamport: lamportType = 0
private let lastLamportQueue = DispatchQueue(label: "io.cr3.lastLamport")


#if !os(macOS)
public let localPeerID: UUID = UIDevice.current.identifierForVendor!
#else
public let localPeerID: UUID = UUID()
// IOPlatformUUID
//FIX me - we need macOS implementation (apparently GUID https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14)
#endif

public typealias lamportType = Int64

//TODO: make me atomic
func getLamport() -> lamportType {
    return lastLamportQueue.sync {
        lastLamport += 1
        return lastLamport
    }
}

/**
 exeute on every incoming message unless you create an Id object
*/
public func newLamportSeen(_ seenLamport: lamportType) {
    lastLamport = max(lastLamport, seenLamport)
}



/**
 call this on the app start
 
 scans alll operation logs for the maximum known lamport
 */
public func updateLastLamportFromCoOpLog(in context: NSManagedObjectContext) {
    //TODO:  deduplicate code through inheritance and maybe even model inheritance to have one query
    let fetchRequestInsert:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
    fetchRequestInsert.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestInsert.fetchLimit = 1
    
    let opsInsert = try? context.fetch(fetchRequestInsert)
    for op in opsInsert ?? [] {
        print("Max insert lamport observed: \(op.lamport)")
        newLamportSeen(op.lamport)
    }
}


