//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 31/01/2021.
//

import Foundation
import SwiftUI
import CloudKit

/**
 CoreData Operation Log is Append only.
 Every recorded operation is immutable
 */

//good impementation: https://github.com/caiyue1993/IceCream


public enum CoOpAttributesKey: String {
    case subscriptionIsLocallyCachedKey
    case databaseChangesTokenKey
    case zoneChangeTokenKey
    var value: String {
        return "coopattributes.keys." + rawValue
    }
}


/** initialise it at the begining of the app
responsibility:
 - downloading from CloudKit
 - uploading to CloudKit
 - performing merge
 */
public class CoOpSyncController {
    public static let shared = CoOpSyncController()
    let database = CKContainer.default().privateCloudDatabase
    private static var configContext:NSManagedObjectContext?
    private let context:NSManagedObjectContext

    func setup(context: NSManagedObjectContext) {
        CoOpSyncController.configContext = context
    }
    

    //context: NSManagedObjectContext
    init() {
        context = CoOpSyncController.configContext!
        registerLocalDatabase()
        setupSubscriptionIfHaveNot()
        guard let _ = CoOpSyncController.configContext else {
            fatalError("Initialise Context 1st")
        }
    }

    
    
//    /** call me from xyz */
//    func setupNotificaitons() {
//
//    }
  
    
    func setupSubscriptionIfHaveNot() {
        guard !subscriptionIsLocallyCached else { return }
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Operation", predicate: predicate, subscriptionID: "private_creations", options: .firesOnRecordCreation)

        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        subscription.notificationInfo = notification
        
        database.save(subscription) { result, error in
            guard error == nil else {
                print("Error subscribing: \(error!)")
                return
            }
            print("Subscribed to Operation")
            self.subscriptionIsLocallyCached = true
        }
    }
    
    
    func fetchChangesInDatabase(_ callback: ((Error?) -> Void)?) {
        // I'm not sure why we evn bother to track database level changes as it's not showing records
        // But ok, this can stay as a boilerplace code
        let changesOperation = CKFetchDatabaseChangesOperation(previousServerChangeToken: databaseChangeToken)
        var changedZoneIDs: [CKRecordZone.ID] = []

        /// Only update the changeToken when fetch process completes
        changesOperation.changeTokenUpdatedBlock = { [weak self] newToken in
            self?.databaseChangeToken = newToken
        }
        
        changesOperation.recordZoneWithIDChangedBlock = { (zoneID) in
            changedZoneIDs.append(zoneID)
        }
        
        changesOperation.fetchDatabaseChangesCompletionBlock = { [weak self] newToken, _, error in
            guard let self = self else { return }
            guard error == nil else {
                if let ckerror = error as? CKError {
                    switch ckerror.code {
                    case .serviceUnavailable,
                         .requestRateLimited,
                         .zoneBusy:
                        let retryInterval = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval
                        let retryTime = DispatchTime.now() + (retryInterval ?? 10)
                        DispatchQueue.main.asyncAfter(deadline: retryTime, execute: {
                            self.fetchChangesInDatabase(callback)
                        })
                    case .changeTokenExpired:
                        self.databaseChangeToken = nil
                        self.fetchChangesInDatabase(callback)
                    default:
                        return
                    }
                }
                return
            }
            self.databaseChangeToken = newToken
            // Fetch the changes in zone level
            
            var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()

            for zoneID in changedZoneIDs {
                let zoneChangeToken = CoOpSyncController.getZoneChangeToken(zoneID: zoneID)
                let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
                options.previousServerChangeToken = zoneChangeToken
                optionsByRecordZoneID[zoneID] = options
            }

            self.fetchChangesInZones(recordZoneIDs: changedZoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID, callback: callback)
        }
        database.add(changesOperation)
    }
    
    
    func fetchChangesInZones(recordZoneIDs: [CKRecordZone.ID],
                             configurationsByRecordZoneID: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration],
                             callback: ((Error?) -> Void)?) {
        let zoneOperation = CKFetchRecordZoneChangesOperation(recordZoneIDs: recordZoneIDs, configurationsByRecordZoneID: configurationsByRecordZoneID)

        zoneOperation.recordZoneChangeTokensUpdatedBlock = { zoneId, token, _ in
            CoOpSyncController.setZoneChangeoken(zoneID: zoneId, newValue: token)
        }
        
        zoneOperation.recordChangedBlock = { [weak self] record in
            /// The Cloud will return the modified record since the last zoneChangesToken, we need to do local cache here.
            /// Handle the record:
            guard let self = self else { return }
            self.UpdateOrCreateRecord(record)
        }
        
        zoneOperation.recordWithIDWasDeletedBlock = { [weak self] recordID, recordType in
            guard let self = self else { return }
            self.deleteRecord(recordType:recordType, recordID: recordID)
        }
        
        zoneOperation.recordZoneFetchCompletionBlock = { [weak self] (zoneId ,token, _, _, error) in
            guard let self = self else { return }
            guard error == nil else {
                if let ckerror = error as? CKError {
                    switch ckerror.code {
                    case .serviceUnavailable,
                         .requestRateLimited,
                         .zoneBusy:
                        let retryInterval = ckerror.userInfo[CKErrorRetryAfterKey] as? TimeInterval
                        let retryTime = DispatchTime.now() + (retryInterval ?? 10)
                        DispatchQueue.main.asyncAfter(deadline: retryTime, execute: {
                            self.fetchChangesInZones(recordZoneIDs: recordZoneIDs, configurationsByRecordZoneID: configurationsByRecordZoneID, callback: callback)
                        })
                    case .changeTokenExpired:
                        CoOpSyncController.setZoneChangeoken(zoneID: zoneId, newValue: nil)
                        self.fetchChangesInZones(recordZoneIDs: recordZoneIDs, configurationsByRecordZoneID: configurationsByRecordZoneID, callback: callback)
                    default:
                        return
                    }
                }
                return
            }
            CoOpSyncController.setZoneChangeoken(zoneID: zoneId, newValue: token)
        }
        
        zoneOperation.fetchRecordZoneChangesCompletionBlock = { error in
            callback?(error)
        }
         
        database.add(zoneOperation)
    }
    
    // where do we group? DO we at all group?
    public func asyncUploadOperation(operation: CoOpOperation) {
        CKContainer.default().accountStatus { accountStatus, error in
            guard accountStatus == .available else {
                return
            }

            let database = CKContainer.default().privateCloudDatabase

            let recordOp = CKRecord(recordType: "Operation")
            recordOp.setValuesForKeys([
                "lamport": 1,
                "rawOperation": "abc"
            ])
            
            
            let ckOp = CKModifyRecordsOperation(recordsToSave: [recordOp])
            
            ckOp.modifyRecordsCompletionBlock = { _, _, error in
                guard error == nil else {
                    guard let ckerror = error as? CKError else {
                        print("Error saving Operation: \(error!)")
                        return
                    }
                    print("Error saving Operation: \(ckerror.userInfo)")
                    if ckerror.code == .partialFailure {
                        print("Partial error")
                    }
                    return
                }
                print("Saved")
            }
            database.add(ckOp)
        }
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


    public func registerLocalDatabase() {
        fatalNotImplemented()
    }

}




// Model operations
//TODO refactor into some metaprogramign/generics....
extension CoOpSyncController {
    func UpdateOrCreateRecord(_ record: CKRecord) {
        
        switch record.recordType {
        case "Container":
            let request = CoOpContainer.fetchRequest()
            request.predicate = NSPredicate(format: "ckID = %@", record.recordID)
            
            let results = try! context.fetch(request) as! [CoOpContainer]
            if let obj = results.first {
                obj.update(from: record)
            } else {
                let _ = CoOpContainer.init(in: context, from: record)
            }
            do {
                try context.save()
            } catch {
                print("Error wile creating Operation: \(error)")
            }
        case "Operation": // Operation should never be updated, consider optimising
            let request = CoOpOperation.fetchRequest()
            request.predicate = NSPredicate(format: "ckID = %@", record.recordID)
            
            let results = try! context.fetch(request) as! [CoOpOperation]
            if let _ = results.first {
                fatalError("Operation should never be updated")
            } else {
                let _ = CoOpOperation.init(in: context, from: record)
            }
            do {
                try context.save()
            } catch {
                print("Error wile creating Operation: \(error)")
            }
        default:
            fatalNotImplemented()
        }
    }
    
    func deleteRecord(recordType: String, recordID: CKRecord.ID) {
        switch recordType {
        case "Container":
            let request = CoOpOperation.fetchRequest()
            request.predicate = NSPredicate(format: "ckID = %@", recordID)
            
            let results = try! context.fetch(request) as! [CoOpOperation]
            if let firstResult = results.first {
                context.delete(firstResult)
                do {
                    try context.save()
                } catch {
                    print("Error wile deleting Container: \(error)")
                }
            }
        case "Operation":
            fatalError("Operation should never be deleted")
        default:
            fatalNotImplemented() // extend when adding another CK object type
        }
    }
}



// Persistent properties
extension CoOpSyncController {
    
    var databaseChangeToken: CKServerChangeToken? {
        get {
            /// For the very first time when launching, the token will be nil and the server will be giving everything on the Cloud to client
            /// In other situation just get the unarchive the data object
            guard let tokenData = UserDefaults.standard.object(forKey: CoOpAttributesKey.databaseChangesTokenKey.value) as? Data else { return nil }
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: tokenData)
        }
        set {
            guard let newValue = newValue else {
                UserDefaults.standard.removeObject(forKey: CoOpAttributesKey.databaseChangesTokenKey.value)
                return
            }
            do {
                let tokenData = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
                UserDefaults.standard.set(tokenData, forKey: CoOpAttributesKey.databaseChangesTokenKey.value)
            } catch {
                fatalNotImplemented() // I'm considering removing the key
            }
        }
    }
    
    static func getZoneChangeToken(zoneID: CKRecordZone.ID) -> CKServerChangeToken? {
        guard let changeTokenData = UserDefaults.standard.object(forKey: "\(CoOpAttributesKey.zoneChangeTokenKey.value).\(zoneID.zoneName)") as? Data else { return nil}
        return try? NSKeyedUnarchiver.unarchivedObject(ofClass: CKServerChangeToken.self, from: changeTokenData)
    }
    
    static func setZoneChangeoken(zoneID: CKRecordZone.ID, newValue: CKServerChangeToken?) {
        guard let newValue = newValue else {
            UserDefaults.standard.removeObject(forKey: "\(CoOpAttributesKey.zoneChangeTokenKey.value).\(zoneID.zoneName)")
            return
        }
        do {
            let tokenData = try NSKeyedArchiver.archivedData(withRootObject: newValue, requiringSecureCoding: false)
            UserDefaults.standard.set(tokenData, forKey: "\(CoOpAttributesKey.zoneChangeTokenKey.value).\(zoneID.zoneName)")
        } catch {
            fatalNotImplemented()
        }
    }
    

    var subscriptionIsLocallyCached: Bool {
        get {
            guard let flag = UserDefaults.standard.object(forKey: CoOpAttributesKey.subscriptionIsLocallyCachedKey.value) as? Bool else { return false }
            return flag
        }
        set {
            UserDefaults.standard.set(newValue, forKey: CoOpAttributesKey.subscriptionIsLocallyCachedKey.value)
        }
    }
    
}


//
//private struct CoOpSyncEnvironmentKey: EnvironmentKey {
//    static let defaultValue: CoOpSyncController = CoOpSyncController.shared
//}
////
////@available(OSX 10.15, *)
////extension EnvironmentValues {
////    public var syncController: CoOpSyncController {
////        get { self[CoOpSyncEnvironmentKey.self] }
////        set { self[CoOpSyncEnvironmentKey.self] = newValue }
////    }
////}
