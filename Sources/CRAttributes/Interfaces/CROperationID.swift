//
//  CROperationID.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 01/11/2021.
//

import Foundation
import CoreData


public struct CROperationID: Comparable, Hashable, Codable, CustomStringConvertible {
    public var lamport: lamportType
    public var peerID: UUID
    
    public var description: String {
        "[l:\(lamport), p:\(peerID)]"
    }
    
    init() {
        self.peerID = localPeerID
        self.lamport = getLamport()
    }
    
    init(from protoForm:ProtoOperationID) {
        self.lamport = protoForm.lamport
        self.peerID = protoForm.peerID.object()
    }
    
    init(lamport: lamportType, peerID: UUID) {
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
    
    func protoForm() -> ProtoOperationID {
        return ProtoOperationID.with() {
            $0.lamport = self.lamport
            $0.peerID = self.peerID.data
        }
    }
    
    func isZero() -> Bool {
        return lamport == 0 && peerID == UUID.zero
    }
    
    static var zero:CROperationID {
        get {
            return CROperationID(lamport: 0, peerID: UUID.zero)
        }
    }
    
    // exposing so we can spawn attribute from CDOperation...
    // TODO: make it private
    public func findOperationOrCreateGhost(in context: NSManagedObjectContext) -> CDOperation {
        return CDOperation.findOperationOrCreateGhost(fromLamport: lamport, fromPeerID: peerID, in: context)
    }

}
