//
//  CRTextStorage.swift
//  CRTextStorage
//
//  Created by Mateusz Lapsa-Malawski on 05/08/2021.
//

import Foundation
import CoreData
import AppKit
#if os(iOS)
import UIKit
//import XCTest
#endif



let stringOptimiseQueueLengthMax = 11111


class CRAttributeMutableString: CRAttribute {
    var textStorage: CRTextStorage? = nil

    init(container:CRObject, name:String) {
        super.init(container: container, name: name, type: .mutableString)
        let context = CRStorageController.shared.localContainer.viewContext
        context.performAndWait {
            let attributeOp = context.object(with: operationObjectID!) as? CDAttributeOp
            textStorage = CRTextStorage(attributeOp: attributeOp!)
        }
    }

    // Remember to execute within context.perform {}
    override init(from:CDAttributeOp, container: CRObject) {
        textStorage = CRTextStorage(attributeOp: from)
        super.init(from: from, container: container)
    }
}


//extension NSAttributedString.Key {
//    static let opObjectID = NSAttributedString.Key("CRObjectID")
//    static let opProxy = NSAttributedString.Key("CROpProxy")
//    static let opLamport = NSAttributedString.Key("CRLamport")
//    static let opPeerID = NSAttributedString.Key("CRPeerID")
//}


 


/**
 not thread safe - purely for use from the ViewContext
 */
class CRTextStorage: NSTextStorage {
//    let container: CRObject
//    let attributeName: String
    var attributeOp: CDAttributeOp
    var attributedString: NSMutableAttributedString = NSMutableAttributedString(string:"")
    var addressesArray: [CRStringAddress] = []
    
    var stringOptimiseCountDown = stringOptimiseQueueLengthMax
    
    var knownOperationForAddress: [CRStringAddress:CDStringInsertOp] = [:]
    var context: NSManagedObjectContext
    
    
    // TODO: try later to use the self=NSTextStorage internal storage
    
    //Execute within context.perform of viewContext
    init(attributeOp: CDAttributeOp) {
        self.attributeOp = attributeOp
        context = CRStorageController.shared.localContainer.viewContext
//        attributedString = NSMutableAttributedString(string:"")
        super.init()
        
        //TODO: deserialise string
        //process the local queue

        //start background queue doing:
        //- merge downstream linked lists (steating op log)
        
        //start another background queue:
        //- serialising the String and removing operations from op log
        
        
        prebuildStringBundleFromRenderedString(attributeOp: attributeOp)
//        prebuildAttributedStringFromOperations(attributeOp: attributeOp)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
        context = CRStorageController.shared.localContainer.viewContext
        attributeOp = CDAttributeOp()
        super.init(coder: aDecoder)
    }

    // subclasses should implement it to execute in O(1) time.
    // source https://developer.apple.com/documentation/foundation/nsattributedstring/1412616-string
    public override var string: String {
        get {
            return attributedString.string
        }
    }

    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return attributedString.attributes(at: location, effectiveRange: range)
    }

    public override func replaceCharacters(in range: NSRange, with strContent: String) {
        beginEditing()
        //TODO: - we may need a hash to track deleted operations


        // TODO: delete operations in the range
        // TODO: - save once every 60 objects

        // create a string to insert with all linked operatations
        var strAddresses: [CRStringAddress] = [] //TODO: - prealocate the right size / maybe us map?
                

        // create insert operation
        let newOp:CDStringInsertOp = CDStringInsertOp(context: context, parent: nil, container: attributeOp, contribution: strContent)
        let opAddress = newOp.stringAddress()
        var charAddress = opAddress
        // TODO: link the operation in linked list and with parent
        try! context.save()
        
        for (index, _ ) in strContent.enumerated() {
            charAddress.offset = opAddress.offset + Int64(index)
            strAddresses.append(charAddress)
        }
        
        // insert
        attributedString.replaceCharacters(in: range, with: strContent)
        addressesArray.replaceElements(in: range, with: strAddresses)
        
        _ = CDRenderedStringOp(context: context, containerOp: attributeOp, in: range, operationString: strContent, operationAddresses: strAddresses)
        try! context.save() // TODO: - make it save once a 60 objects
        considerSnapshotingStringBundle()

        edited(.editedCharacters,
               range: range,
               changeInLength: (strContent as NSString).length - range.length)
        endEditing()
        
        // TODO: how to fire save() on the last endEditing? do we have to?
        // maybe we could listen to: didProcessEditingNotification
    }
    
  
    // each setAttributes shall be a CRDT operation with range mapped to CRDT address space
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        //TODO: each attribute set/delete will be an operation (TBD about the parent ID, I think it's string insert one except for deleted operations
//        beginEditing()
//        attributedString.setAttributes(attrs, range: range)
//        edited(.editedAttributes, range: range, changeInLength: 0)
//        endEditing()
    }

    
    private func prebuildStringBundleFromRenderedString(attributeOp: CDAttributeOp) {
        let context = CRStorageController.shared.localContainer.viewContext
        var tempString:String? = nil
        (tempString, addressesArray) = CDRenderedStringOp.stringBundleFor(context: context, container: attributeOp)
        self.attributedString = NSMutableAttributedString(string: tempString!)
    }
    
    /**
     getsLamport synchronously on the main thread
     saves string bundle in background
     will only execute once stringOptimiseQueueLengthMax
     */
    func considerSnapshotingStringBundle(force: Bool=false) {
        stringOptimiseCountDown -= 1
        if force != true && stringOptimiseCountDown != 0 {
            return
        }
        let lamport = getLamport()
        print("scheduling snapshot with lamport: \(lamport)")
        stringOptimiseCountDown = stringOptimiseQueueLengthMax

        //TODO: should it be context per save?
        let context = CRStorageController.shared.localContainer.newBackgroundContext()

        let attributeObjectID = self.attributeOp.objectID
        let stringSnapshot = attributedString.string
        let addressesSnapshot = addressesArray
        context.perform {
            let attributeOp:CDAttributeOp = (context.object(with: attributeObjectID) as? CDAttributeOp)!
            _ = CDRenderedStringOp(context: context, containerOp: attributeOp, lamport: lamport, stringSnapshot: stringSnapshot, addressesSnapshot: addressesSnapshot)
            try! context.save()
        }
    }
    
    
    // MARK: - rebuild me
    
//    private func prebuildAttributedStringFromOperations(attributeOp: CDAttributeOp) {
//        let context = CRStorageController.shared.localContainer.viewContext
////        fatalNotImplemented() //TODO - now mix the rendered string snapshots and remote operations
//
//        // let's prefetch
//        // there is no need to prefetch delete operations as we have the hasTombstone attribute
//        var request:NSFetchRequest<CDStringInsertOp> = CDStringInsertOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        request.predicate = NSPredicate(format: "container == %@", attributeOp)
//        let _ = try! context.fetch(request)
//
//        // let's get the first operation
//        request = CDStringInsertOp.fetchRequest()
//        request.returnsObjectsAsFaults = false
//        request.predicate = NSPredicate(format: "container == %@ and prev == nil", attributeOp)
//        let head:CDStringInsertOp? = try? context.fetch(request).first
//
//        // build the attributedString
//        attributedString = NSMutableAttributedString(string:"")
//        var node:CDStringInsertOp? = head
//        while node != nil {
//            if node!.hasTombstone == false {
//                let contribution = NSMutableAttributedString(string:node!.contribution)
//                contribution.setAttributes([.opProxy: node!.opProxy()], range: NSRange(location: 0, length: 1))
//                attributedString!.append(contribution)
//            }
//            node = node!.next
//        }
//    }
    
    
    private func firstOp(context: NSManagedObjectContext, attributeOp: CDAttributeOp) -> CDStringInsertOp? {
        // TODO: - replace with address to operation
        let request:NSFetchRequest<CDStringInsertOp> = CDStringInsertOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and prev == nil", attributeOp)
        return try? context.fetch(request).first
    }
    
    private func operationForPosition(_ position: Int) -> CDStringInsertOp {
        let opAddress = addressesArray[position]
        return operationForAddress(opAddress)
    }
    
    private func operationForAddress(_ address: CRStringAddress) -> CDStringInsertOp {
        fatalNotImplemented()
//        var masterOpAddress = address
//        masterOpAddress.offset = 0
//        
        // how do we preload the dict, and when?
//        masterOp =
        
        
//        let opProxy:CDStringInsertOpProxy = attributedString!.attribute(.opProxy, at: 0  , effectiveRange: nil) as! CDStringInsertOpProxy
        return CDStringInsertOp()

    }
    
    

//    unused
//    func setOperationForPosition(_ operation: CoOpStringInsert, _ position: Int) {
//        attributedString.setAttributes([.opObjectID: operation.objectID], range: NSRange(location: position, length: 1))
//    }
    
    private func markDeleted(_ operation: CDAbstractOp) {
        let _ = CDDeleteOp(context: context, container: operation)
        operation.hasTombstone = true
    }
    
    
}




extension NSMutableAttributedString {
    /**
    based on https://github.com/automerge/automerge-perf
    compare results with https://github.com/dmonad/crdt-benchmarks
     */
    func loadFromJsonIndexDebug(limiter: Int = 1000000, bundle: Bundle = Bundle.main) {
        guard let path = bundle.path(forResource: "test-mk-editing-trace", ofType: "json") else {
            fatalError() }
        
        
        let url = URL(fileURLWithPath: path)
        let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        let json = try? JSONSerialization.jsonObject(with: data!)
        // TODO: migrate to stream to reduce memory footprint (if used in production)

        if let array = json as? [Any] {
            for (arrayIndex, indexOp) in array.enumerated() {
                if arrayIndex >= limiter {
                    break
                }

                if let opArray = indexOp as? [Any],
                   let index = opArray[0] as? Int,
                   let deleteCount = opArray[1] as? Int {

                    if deleteCount > 0 {
                        replaceCharacters(in: NSRange.init(location: index, length: deleteCount), with: "")
                    }

                    if opArray.count > 2 {
                        if let text = opArray[2] as? String {
                            replaceCharacters(in: NSRange.init(location: index, length: 0), with: text)
                        } else {
                            fatalError()
                        }
                    }
                } else {
                    fatalError()
                }
            }
        }
    }
}
