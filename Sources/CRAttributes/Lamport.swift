
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
import AppKit
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
    //TODO:  deduplicate code through inheritance and maybe even model inheritance to have one query
    let fetchRequestInsert:NSFetchRequest<CRAbstractOp> = CRAbstractOp.fetchRequest()
    fetchRequestInsert.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestInsert.fetchLimit = 1
    
    let opsInsert = try? context.fetch(fetchRequestInsert)
    for op in opsInsert ?? [] {
        print("Max insert lamport observed: \(op.lamport)")
        newLamportSeen(op.lamport)
    }
}




struct CROperationID: Comparable {
    var lamport: Int64
    var peerID: Int64
    
    init() {
        self.peerID = localPeerID
        self.lamport = getLamport()
    }
    
    init(lamport: Int64, peerID: Int64) {
        self.lamport = lamport
        self.peerID = peerID
        newLamportSeen(lamport)
    }
    
    public static func < (lhs: CROperationID, rhs: CROperationID) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }
}
