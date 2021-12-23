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
import SwiftProtobuf
//import XCTest
#endif



let stringOptimiseQueueLengthMax = 1234


class CRAttributeMutableString: CRAttribute {
    var textStorage: CRTextStorage? = nil

    init(context: NSManagedObjectContext, container:CRObject, name:String) {
        super.init(context: context, container: container, name: name, type: .mutableString)
        let context = CRStorageController.shared.localContainer.viewContext
        context.performAndWait {
            textStorage = CRTextStorage(attributeOp: operation!)
        }
        assert(operationsCount() == 0)
    }

    // Remember to execute within context.perform {}
    override init(context:NSManagedObjectContext, container: CRObject, from:CDOperation) {
        textStorage = CRTextStorage(attributeOp: from)
        super.init(context: context, container: container, from: from)
    }
}
 


/**
 not thread safe - purely for use from the ViewContext
 */
class CRTextStorage: NSTextStorage {
//    let container: CRObject
//    let attributeName: String
    var attributeOp: CDOperation
    var attributedString: NSMutableAttributedString = NSMutableAttributedString(string:"")
    var addressesArray: [CROperationID] = []
    
    var stringOptimiseCountDown = stringOptimiseQueueLengthMax
    
    var knownOperationForAddress: [CROperationID:CDOperation] = [:]
    var context: NSManagedObjectContext
    
    
    // TODO: try later to use the self=NSTextStorage internal storage
    
    //Execute within context.perform of viewContext
    init(attributeOp: CDOperation) {
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
        //TODO: backfill with RGA operations - for UI we will need async version
//        prebuildAttributedStringFromOperations(attributeOp: attributeOp)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
        context = CRStorageController.shared.localContainer.viewContext
        attributeOp = CDOperation()
        super.init(coder: aDecoder)
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
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


        if range.length > 0 {
            // TODO: delete operations in the range
            for address in addressesArray[range.location...(range.location+range.length-1)] {
//                let op = CDOperation.findOperationOrCreateGhost(from: address, in: context) //TODO: consider moving to background
                let delete = CDOperation.createDelete(context: context, within: self.attributeOp, of: address)
                delete.state = .inUpstreamQueueRendered
            }
            try! context.save()
        }
        // TODO: - save once every 60 objects

        // create the string to insert
        var strAddresses: [CROperationID] = [] //TODO: - prealocate the right size / maybe us map?
                
        // create the operation to insert
        // 1st the parent
        var parentAddress: CROperationID
        if range.location > 0 {
            parentAddress = addressesArray[range.location-1]
        } else {
            parentAddress = self.attributeOp.operationID()
        }
        
        for us in strContent.unicodeScalars {
//            let parent = CDOperation.findOperationOrCreateGhost(from: parentAddress, in: context) //TODO: consider moving to background

            let newOp:CDOperation = CDOperation.createStringInsert(context: context, container: self.attributeOp, parentID: parentAddress, contribution: us)
            newOp.state = .inUpstreamQueueRendered
            let charAddress = newOp.operationID()
            strAddresses.append(charAddress)
            parentAddress = charAddress
        }
        //TODO: migrate to batch save as we can
        
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

    
    private func prebuildStringBundleFromRenderedString(attributeOp: CDOperation) {
        let context = CRStorageController.shared.localContainer.viewContext
        (attributedString, addressesArray) = CDRenderedStringOp.stringBundleFor(context: context, container: attributeOp)
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
        print("Scheduling snapshot with lamport: \(lamport)")
        stringOptimiseCountDown = stringOptimiseQueueLengthMax

        //TODO: should it be context per save?
        let context = CRStorageController.shared.localContainer.newBackgroundContext()

        let attributeObjectID = self.attributeOp.objectID
        let stringSnapshot = attributedString.string
        let addressesSnapshot = addressesArray
        context.perform {
            let attributeOp:CDOperation = (context.object(with: attributeObjectID) as? CDOperation)!
            _ = CDRenderedStringOp(context: context, containerOp: attributeOp, lamport: lamport, stringSnapshot: stringSnapshot, addressesSnapshot: addressesSnapshot)
            try! context.save()
        }
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