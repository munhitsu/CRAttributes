
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
import AppKit
#endif


public var lastLamport: Int64 = 0
private let lastLamportQueue = DispatchQueue(label: "io.cr3.lastLamport")


#if !os(macOS)
public let localPeerID: UUID = UIDevice.current.identifierForVendor!
#else
public let localPeerID: UUID = UUID()
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
    var peerID: UUID
    
    init() {
        self.peerID = localPeerID
        self.lamport = getLamport()
    }
    
    init(lamport: Int64, peerID: UUID) {
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



extension UUID {
    public static func < (lhs: UUID, rhs: UUID) -> Bool {
        return lhs.uuidString < rhs.uuidString
        //TODO: speed it up!
        // maybe with https://developer.apple.com/documentation/foundation/nsuuid/1411420-getbytes
        // I wonder if I can use https://developer.apple.com/documentation/accelerate/vs128
        // or https://developer.apple.com/documentation/accelerate/vdsp
        // as its a comparision of 2 int128 or 2 vectors
    }
}

public extension UUID {

    var data: Data {
        return withUnsafeBytes(of: self.uuid, { Data($0) })
    }

}
