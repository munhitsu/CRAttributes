//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData

var cr_test_mode = false

public class CRStorageController {
    
    static func testMode() {
        cr_test_mode = true
//        CRStorageController._shared = CRStorageController(inMemory: true, testMode: true)
    }
    
    public static let shared:CRStorageController = CRStorageController() // globals are lazy
    
//    public static var shared:CRStorageController {
//        CRStorageController._shared = CRStorageController._shared ?? CRStorageController()
//        return _shared!
//    }

    public static let preview: CRStorageController = {
        cr_test_mode = true
        return CRStorageController()
    }()
    
    public let localContainer: NSPersistentContainer
    public let localContainerBackgroundContext: NSManagedObjectContext
    public let replicationContainer: NSPersistentContainer
    public let replicationContainerBackgroundContext: NSManagedObjectContext
    
    public let rgaController: RGAController
    public let replicationController: ReplicationController
    
    init() {
        assert(Thread.current.isMainThread)
//        print("CRStorageController.\(#function) on \(Thread.current)")
        
        localContainer = NSPersistentContainer(name: "CRLocalModel", managedObjectModel: CRLocalModel)
        replicationContainer = NSPersistentCloudKitContainer(name: "CRReplicationModel", managedObjectModel: CRReplicationModel)
        
        if cr_test_mode {
            localContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            replicationContainer.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        print("Container URL: \(String(describing: localContainer.persistentStoreDescriptions.first?.url))")
        
        localContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        localContainer.viewContext.automaticallyMergesChangesFromParent = true
        localContainer.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)

        let replicationDescription  = replicationContainer.persistentStoreDescriptions.first
        replicationDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        replicationDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)

        replicationContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        localContainerBackgroundContext = localContainer.newBackgroundContext()
        localContainerBackgroundContext.automaticallyMergesChangesFromParent = true
        
        localContainer.viewContext.name = "viewContext"
        localContainer.viewContext.transactionAuthor = localPeerID.uuidString
        localContainerBackgroundContext.name = "backgroundContext"
        localContainerBackgroundContext.transactionAuthor = localPeerID.uuidString
        
        replicationContainerBackgroundContext = replicationContainer.newBackgroundContext()
        replicationContainerBackgroundContext.automaticallyMergesChangesFromParent = true //?
        
        replicationContainer.viewContext.name = "viewContext"
        replicationContainer.viewContext.transactionAuthor = localPeerID.uuidString
        replicationContainerBackgroundContext.name = "backgroundContext"
        replicationContainerBackgroundContext.transactionAuthor = localPeerID.uuidString
        
        self.rgaController = RGAController(localContainerBackgroundContext: localContainerBackgroundContext)
        rgaController.linkUnlinkedAsync()
        
        self.replicationController = ReplicationController(localContext: localContainerBackgroundContext,
                                                           replicationContext: replicationContainerBackgroundContext,
                                                           skipTimer: cr_test_mode,
                                                           skipRemoteChanges: cr_test_mode)
        print("CRStorageController.done")
    }
        
    func processUpsteamOperationsQueue() {
        replicationController.processUpsteamOperationsQueue()
    }
}
