
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
#endif


public var lastLamport: Int64 = 0
private let lastLamportQueue = DispatchQueue(label: "io.cr3.lastLamport")


#if !os(macOS)
public let localPeerID: Int64 = Int64(UIDevice.current.identifierForVendor!.hashValue)
#else
public let localPeerID: Int64 = 0
// IOPlatformUUID
//FIX me - we need macOS implementation (apparently GUID https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14)
#endif


//TODO: make me atomic
func getLamport() -> Int64 {
    return lastLamportQueue.sync {
        lastLamport += 1
        return lastLamport
    }
}

/**
 exeute on every incoming message unless you create an Id object
*/
public func newLamportSeen(_ seenLamport: Int64) {
    lastLamport = max(lastLamport, seenLamport)
}



/**
 call this on the app start
 
 scans alll operation logs for the maximum known lamport
 */
public func updateLastLamportFromCoOpLog(in context: NSManagedObjectContext) {
    //TODO: deduplicate code through inheritance and maybe even model inheritance to have one query
    let fetchRequestInsert:NSFetchRequest<CoOpMutableStringOperationInsert> = CoOpMutableStringOperationInsert.fetchRequest()
    fetchRequestInsert.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestInsert.fetchLimit = 1
    
    let opsInsert = try? context.fetch(fetchRequestInsert)
    for op in opsInsert ?? [] {
        print("Max insert lamport observed: \(op.lamport)")
        newLamportSeen(op.lamport)
    }

    let fetchRequestDelete:NSFetchRequest<CoOpMutableStringOperationDelete> = CoOpMutableStringOperationDelete.fetchRequest()
    fetchRequestDelete.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestDelete.fetchLimit = 1
    
    let opsDelete = try? context.fetch(fetchRequestDelete)
    for op in opsDelete ?? [] {
        print("Max delete lamport observed: \(op.lamport)")
        newLamportSeen(op.lamport)
    }
}



//extension OperationID: Comparable {
//
//    public static func < (lhs: OperationID, rhs: OperationID) -> Bool {
//        if lhs.lamport == rhs.lamport {
//            return lhs.peerID < rhs.peerID
//        } else {
//            return lhs.lamport < rhs.lamport
//        }
//    }
//}
