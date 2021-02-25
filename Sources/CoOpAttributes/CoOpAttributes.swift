
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
#endif


public var lastLamport: Int64 = 0
private let lastLamportQueue = DispatchQueue(label: "io.cr3.lastLamport")


#if !os(macOS)
public let localPeerID: Int = UIDevice.current.identifierForVendor!.hashValue
#else
public let localPeerID: Int = 0
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
    let fetchRequest:NSFetchRequest<CoOpMutableStringOperation> = CoOpMutableStringOperation.fetchRequest()
    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequest.fetchLimit = 1
    
    do {
        let ops = try context.fetch(fetchRequest)
        for op in ops {
            print("Max lamport observed: \(op.lamport)")
            lastLamport = op.lamport
        }
    } catch let error as NSError {
        print("Could not fetch. \(error), \(error.userInfo)")
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
