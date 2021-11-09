//
//  CRStringAddress.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 01/11/2021.
//

import Foundation


//RGA Split Tree Address
public struct CRStringAddress: Comparable, Hashable, Codable {
    var lamport: lamportType
    var peerID: UUID
    var offset: Int32
    
    static var zero: CRStringAddress {
        CRStringAddress(lamport: 0, peerID: UUID.zero, offset: 0)
    }
    
    init() {
        self.peerID = localPeerID
        self.lamport = getLamport()
        self.offset = 0
    }

    init(lamport: lamportType, peerID: UUID, offset: Int32) {
        self.lamport = lamport
        self.peerID = peerID
        self.offset = offset
        newLamportSeen(lamport)
    }

//    public static func ==  (lhs: CRStringAddress, rhs: CRStringAddress) -> Bool {
//        return lhs.lamport == rhs.lamport &&
//        lhs.peerID == rhs.peerID &&
//        lhs.offset == rhs.offset
//    }
    

    public static func < (lhs: CRStringAddress, rhs: CRStringAddress) -> Bool {
        if lhs.lamport == rhs.lamport {
            if lhs.peerID == rhs.peerID {
                return lhs.offset < rhs.offset
            } else {
                return lhs.peerID < rhs.peerID
            }
        } else {
            return lhs.lamport < rhs.lamport
        }
    }
    
    public func equalOrigin(with: CRStringAddress) -> Bool {
        return self.lamport == with.lamport && self.peerID == with.peerID
    }
}


