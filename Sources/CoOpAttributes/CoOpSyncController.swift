//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 31/01/2021.
//

import Foundation
import SwiftUI

/**
 CoreData Operation Log is Append only.
 Every recorded operation is immutable
 */


/** initialise it at the begining of the app
responsibility:
 - downloading from CloudKit
 - uploading to CloudKit
 - performing merge
 */
public class CoOpSyncController {
    public static let shared = CoOpSyncController()
    
    
    
    // where do we group? DO we at all group?
    public func asyncUploadOperation() {
        
    }
    
    /**
     based on local coredata transaction log...
     may not be needed
     */
    public func asyncUploadNewOperations() {
        
    }
    
    /**
     shall not override remote operations
     */
    public func asyncUploadAllOperations() {
        
    }
    
    
    
    public func asyncDownloadNewOperations() {
        
    }
}


private struct CoOpSyncEnvironmentKey: EnvironmentKey {
    static let defaultValue: CoOpSyncController = CoOpSyncController.shared
}

@available(OSX 10.15, *)
extension EnvironmentValues {
    public var syncController: CoOpSyncController {
        get { self[CoOpSyncEnvironmentKey.self] }
        set { self[CoOpSyncEnvironmentKey.self] = newValue }
    }
}
