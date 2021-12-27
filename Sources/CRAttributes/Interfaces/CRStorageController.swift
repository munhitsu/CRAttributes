//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 07/01/2021.
//

import Foundation
import CoreData

//TODO: follow iwht https://developer.apple.com/documentation/coredata/consuming_relevant_store_changes
public class CRStorageController {
    
    static func testMode() {
        CRStorageController._shared = CRStorageController(inMemory: true, testMode: true)
    }
    
    static var _shared:CRStorageController? = nil
    
    static var shared:CRStorageController {
        CRStorageController._shared = CRStorageController._shared ?? CRStorageController()
        return _shared!
    }

    static var preview: CRStorageController = {
        let result = CRStorageController(inMemory: true, testMode: true)
        return result
    }()
    
    let localContainer: NSPersistentContainer
    let localContainerBackgroundContext: NSManagedObjectContext
    let replicationContainer: NSPersistentContainer
    let replicationContainerBackgroundContext: NSManagedObjectContext
    
    let rgaController: RGAController
    let replicationController: ReplicationController
    
    private static let authorName = "FireballWatch"
    
    init(inMemory: Bool = false, testMode: Bool = false) {
        print("CRStorageController.init")
        
        localContainer = NSPersistentContainer(name: "CRLocalModel", managedObjectModel: CRLocalModel)
        replicationContainer = NSPersistentCloudKitContainer(name: "CRReplicationModel", managedObjectModel: CRReplicationModel)
        
        if inMemory {
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
        
        replicationContainer.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        let replicationDescription  = replicationContainer.persistentStoreDescriptions.first
        replicationDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        replicationDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
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
                                                           skipTimer: testMode,
                                                           skipRemoteChanges: testMode)
    }
        
    func processUpsteamOperationsQueue() {
        replicationController.processUpsteamOperationsQueue()
    }
}
