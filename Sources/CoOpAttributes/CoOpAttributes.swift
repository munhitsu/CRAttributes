
// OperationID() is zeroID

import CoreData
#if !os(macOS)
import UIKit
#endif


extension OperationID {
    public static var lastLamport: Int64 = 0

    #if !os(macOS)
    static let localPeerID: Int = UIDevice.current.identifierForVendor!.hashValue
    #else
    static let localPeerID: Int = 0
    // IOPlatformUUID
    //FIX me - we need macOS implementation (apparently GUID https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14)
    #endif


    /**
     call this on the app start
     */
    public static func updateLastLamportFromCoOpLog(in context: NSManagedObjectContext) {
        let fetchRequest = CoOpOperation.fetchRequest() as! NSFetchRequest<CoOpOperation>
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
        fetchRequest.fetchLimit = 1
        
        do {
            let ops = try context.fetch(fetchRequest)
            for op in ops {
                print("Max lamport observed: \(op.lamport)")
                OperationID.lastLamport = op.lamport
            }
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    /**
     generates next available OperationID
     let newOp = OperationID.generate()
     */
    public static func generate() -> Self {
        var message = Self()
        message.lamport = OperationID.lastLamport + 1
        OperationID.lastLamport = max(OperationID.lastLamport, message.lamport)
        return message
    }

    
    /**
     exeute on every incoming message unless you create an Id object
    */
    public static func newLamportSeen(_ seenLamport: Int64) {
        OperationID.lastLamport = max(OperationID.lastLamport, seenLamport)
    }


}

extension OperationID: Comparable {

    public static func < (lhs: OperationID, rhs: OperationID) -> Bool {
        if lhs.lamport == rhs.lamport {
            return lhs.peerID < rhs.peerID
        } else {
            return lhs.lamport < rhs.lamport
        }
    }
}
