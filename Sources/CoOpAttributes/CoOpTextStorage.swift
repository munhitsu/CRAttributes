//
//  CoOpTextStorage.swift
//  CoOpAttributes
//
//  Created by Mateusz Lapsa-Malawski on 08/03/2021.
//

import Foundation
//#if os(macOS)
//import AppKit
//#else
#if os(iOS)
import UIKit
#endif
//#endif

import Combine
import CoreData

public protocol Selectable {
    func setSelection(_ selection: NSRange)
}


// proxy over CoOpMutableStringAttribute
// that takes care of beginEditing, edited and endEditing
// and exposes NSTextStorage

// temporarily implements remote operations
public class CoOpTextStorage: NSTextStorage {
    
    var storage: CoOpMutableStringAttribute?
    public var selectable: Selectable? // it is effectively a delegate pattern
    private var subscriptions: Set<AnyCancellable> = []
    private var container: NSPersistentContainer?

    init(_ storage: CoOpMutableStringAttribute, selectable: Selectable?, container: NSPersistentContainer) {
        self.storage = storage
        self.selectable = selectable
        self.container = container
        super.init()
        NotificationCenter.default
              .publisher(for: .NSPersistentStoreRemoteChange, object: container)
              .sink {
                self.processRemoteStoreChange($0)
              }
              .store(in: &subscriptions)

        if let tokenData = try? Data(contentsOf: tokenFile) {
            do {
                lastHistoryToken = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: tokenData)
            } catch {
                print("###\(#function): Failed to unarchive NSPersistentHistoryToken. Error = \(error)")
            }
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
        self.storage = nil
        self.selectable = nil
//        self.container = nil
        super.init(coder: aDecoder)
    }

    
    // MARK: - remote operations
    /**
     Track the last history token processed for a store, and write its value to file.
     
     The historyQueue reads the token when executing operations, and updates it after processing is complete.
     */
    private var lastHistoryToken: NSPersistentHistoryToken? = nil {
        didSet {
            guard let token = lastHistoryToken,
                let data = try? NSKeyedArchiver.archivedData( withRootObject: token, requiringSecureCoding: true) else { return }
            
            do {
                try data.write(to: tokenFile)
            } catch {
                print("###\(#function): Failed to write token data. Error = \(error)")
            }
        }
    }
    
    /**
     The file URL for persisting the persistent history token.
    */
    private lazy var tokenFile: URL = {
        let url = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("CoOpAttributes", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("###\(#function): Failed to create persistent container URL. Error = \(error)")
            }
        }
        return url.appendingPathComponent("token.data", isDirectory: false)
    }()

    private func processRemoteStoreChange(_ notification: Notification) {
        precondition(notification.name == NSNotification.Name.NSPersistentStoreRemoteChange)
         
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", appTransactionAuthorName)
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        request.fetchRequest = historyFetchRequest

        let result = (try? taskContext.execute(request)) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction],
              !transactions.isEmpty
            else { return }

        // Post transactions relevant to the current view.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .didFindRelevantTransactions, object: self, userInfo: ["transactions": transactions])
        }

        // Deduplicate the new tags.
        var newTagObjectIDs = [NSManagedObjectID]()
        let tagEntityName = Tag.entity().name

        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes!
                where change.changedObjectID.entity.name == tagEntityName && change.changeType == .insert { //TODO: filter my transactions
                    newTagObjectIDs.append(change.changedObjectID)
            }
        }
        if !newTagObjectIDs.isEmpty {
            deduplicateAndWait(tagObjectIDs: newTagObjectIDs)
        }
        
        // Update the history token using the last transaction.
        lastHistoryToken = transactions.last!.token
    }
    

    
    // MARK: - local operations
    
    //TODO: how to properly extend String https://forums.swift.org/t/subclassing-nsstring-in-swift/33143
    //TODO: subclasses should implement it to execute in O(1) time. (source https://developer.apple.com/documentation/foundation/nsattributedstring/1412616-string)
    public override var string: String {
        get {
            return storage!.string
        }
    }
    
    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return storage!.attributes(at: location, effectiveRange: range)
    }

    public override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        storage!.replaceCharacters(in: range, with: str)
        edited(.editedCharacters,
               range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
    }
    
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        beginEditing()
        storage!.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }
    
}
