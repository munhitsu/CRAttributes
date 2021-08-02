
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
#endif



#if !os(macOS)
public let localPeerID: Int64 = Int64(UIDevice.current.identifierForVendor!.hashValue)
#else
public let localPeerID: Int64 = 0
// IOPlatformUUID
//FIX me - we need macOS implementation (apparently GUID https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14)
#endif





actor lamportActor {
    var lastLamport: Int64 = 0
    func get() -> Int64 {
        lastLamport += 1
        return lastLamport
    }
    /**
     exeute on every incoming message unless you create an Id object
    */
    func seen(_ seenLamport: Int64) {
        lastLamport = max(lastLamport, seenLamport)
    }
}


var lamport = lamportActor()


/**
 call this on the app start
 
 scans alll operation logs for the maximum known lamport
 */
@available(macCatalyst 15.0, *)
public func updateLastLamportFromCoOpLog(in context: NSManagedObjectContext) {
    //TODO:  deduplicate code through inheritance and maybe even model inheritance to have one query
    let fetchRequestInsert:NSFetchRequest<CoOpMutableStringOperationInsert> = CoOpMutableStringOperationInsert.fetchRequest()
    fetchRequestInsert.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestInsert.fetchLimit = 1
    
    let opsInsert = try? context.fetch(fetchRequestInsert)
    for op in opsInsert ?? [] {
        print("Max insert lamport observed: \(op.lamport)")
        Task.detached {
            await lamport.seen(op.lamport)
        }
    }

    let fetchRequestDelete:NSFetchRequest<CoOpMutableStringOperationDelete> = CoOpMutableStringOperationDelete.fetchRequest()
    fetchRequestDelete.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    fetchRequestDelete.fetchLimit = 1
    
    let opsDelete = try? context.fetch(fetchRequestDelete)
    for op in opsDelete ?? [] {
        print("Max delete lamport observed: \(op.lamport)")
        Task.detached {
            await lamport.seen(op.lamport)
        }
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
