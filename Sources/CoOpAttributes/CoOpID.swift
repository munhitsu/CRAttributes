//
//  ID.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 12/01/2021.
//

import Foundation
#if !os(macOS)
import UIKit
#endif

/**
 hybrid lamport clock
// */
//struct CoOpID: Comparable, Hashable {
//    /// lamport
//    public let lamport: Int
//    /// peer ID
//    public let peerID: Int
//
//    /// global latest used cpun
//    static var lastLamport: Int = 0
//    #if !os(macOS)
//    static let localPeerID: Int64 = UIDevice.current.identifierForVendor!.hashValue
//    #else
//    static let localPeerID: Int64 = 0
//    // IOPlatformUUID
//    //FIX me - we need macOS implementation (aparently GUID https://developer.apple.com/library/archive/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateLocally.html#//apple_ref/doc/uid/TP40010573-CH1-SW14)
//    #endif
//    
//
//    /**
//     If we ask for no lamport it will be given
//     if we receive remote object then network layer shuld initiate the ID and this will increment the global counter
//     */
//    init(lamport: Int = lastLamport+1,
//         peerID: Int = CoOpID.localPeerID) {
//        self.lamport = lamport
//        self.peerID = peerID
//        CoOpID.lastLamport = max(CoOpID.lastLamport, lamport)
//    }
//
//    /**
//     exeute on every incoming message unless you create an Id object
//    */
//    static func newLamportSeen(_ seenLamport: Int) {
//        CoOpID.lastLamport = max(CoOpID.lastLamport, seenLamport)
//    }
//
//    /**
//     comparable implementation
//     comparing offset in "<" makes litte sense but leaving it here for completness
//     */
//    static func < (lhs: CoOpID, rhs: CoOpID) -> Bool {
//        if lhs.lamport == rhs.lamport {
//            return lhs.peerID < rhs.peerID
//        } else {
//            return lhs.lamport < rhs.lamport
//        }
//    }
//
//    static func == (lhs: CoOpID, rhs: CoOpID) -> Bool {
//        return (lhs.lamport == rhs.lamport) && (lhs.peerID == rhs.peerID)
//    }
//
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(lamport)
//        hasher.combine(peerID)
//    }
//
//    public static var zero: CoOpID {
//        return CoOpID(lamport: 0, peerID: 0)
//    }
//}
