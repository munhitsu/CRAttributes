//
//  UUID.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 01/11/2021.
//

import Foundation


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
    
    static var zero:UUID {
        UUID(uuidString: "00000000-0000-0000-0000-000000000000")! //TODO: cast from 2 x Int64
    }
}
