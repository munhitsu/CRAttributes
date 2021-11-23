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
        let result = CRStorageController(inMemory: true)
        //        let viewContext = result.container.viewContext
        //        for _ in 0..<10 {
        //            let newItem = Note(context: viewContext)
        //        }
        //        do {
        //            try viewContext.save()
        //        } catch {
        //            let nsError = error as NSError
        //            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        //        }
        return result
    }()
    
    let localContainer: NSPersistentContainer
    let localContainerBackgroundContext: NSManagedObjectContext
    let replicationContainer: NSPersistentContainer
    let replicationContainerBackgroundContext: NSManagedObjectContext
    
    let rgaController: RGAController
    let replicationController: ReplicationController
    
    init(inMemory: Bool = false, testMode: Bool = false) {
        print("CRStorageController.init")
        print("thread: \(Thread.current)")

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

        replicationContainerBackgroundContext = replicationContainer.newBackgroundContext()
        replicationContainerBackgroundContext.automaticallyMergesChangesFromParent = true //?
        
        self.rgaController = RGAController(localContainerBackgroundContext: localContainerBackgroundContext)
        rgaController.linkUnlinkedAsync()
        
        
        self.replicationController = ReplicationController(localContext: localContainerBackgroundContext,
                                                           replicationContext: replicationContainerBackgroundContext,
                                                           skipTimer: testMode)
    }
    
    
    func processUpsteamOperationsQueue() {
        replicationController.processUpsteamOperationsQueue()
    }

}
