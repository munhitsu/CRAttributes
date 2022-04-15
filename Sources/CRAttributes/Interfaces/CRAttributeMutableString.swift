//
//  CRTextStorage.swift
//  CRTextStorage
//
//  Created by Mateusz Lapsa-Malawski on 05/08/2021.
//

import Foundation
import CoreData
#if targetEnvironment(macCatalyst)
import AppKit
#endif
#if os(iOS)
import UIKit
import SwiftProtobuf
//import XCTest
#endif



let stringOptimiseQueueLengthMax = 1234

public class CRAttributeMutableString: CRAttribute {
    public lazy var textStorage:CRTextStorage = {
        _textStorage!
    }()
    var _textStorage: CRTextStorage?

    init(container: CRObject, name: String) {
        super.init(container: container, name: name, type: .mutableString)
        _textStorage = CRTextStorage(attributeOp: operation!)
        assert(operationsCount() == 0)
    }

    // Remember to execute within context.perform {}
    // TODO: make it private
    public override init(from: CDOperation) {
        _textStorage = CRTextStorage(attributeOp: from)
        super.init(from: from)
    }

    func renderOperations(_ operations: [NSManagedObjectID]) {
        context.performAndWait {
            for objectID in operations {
                let op = context.object(with: objectID) as! CDOperation
                if op.state == .inDownstreamQueueMergedUnrendered {
                    renderOperationList(op)
                }
            }
        }
    }

    override func renderOperations(_ operations: [CDOperation]) {
        for op in operations {
            if op.state == .inDownstreamQueueMergedUnrendered {
                renderOperationList(op)
            }
        }
    }
    
    func renderOperationList(_ headOperation: CDOperation) {
        // lets build the addressed string
        var op:CDOperation? = headOperation
        var str = ""
        var addrArray:[CROperationID] = []
        var opArray:[CDOperation] = []
        // going right
        while op?.state == .inDownstreamQueueMergedUnrendered {
            if !(op?.hasTombstone ?? true) {
                str.append(Character((op!.unicodeScalar)))
                addrArray.append(op!.operationID())
                opArray.append(op!)
            }
            op = op!.next
        }
 
        // going left as it's a good moment to render the whole string
        var realHead = headOperation.prev
        while realHead?.state == .inDownstreamQueueMergedUnrendered {
            if !(op?.hasTombstone ?? true) {
                str.insert(Character(realHead!.unicodeScalar), at: str.startIndex)
                addrArray.insert(realHead!.operationID(), at: 0)
                opArray.append(realHead!)
            }
            realHead = realHead!.prev
        }
        let insertionOp = realHead
        // let's insert the string into the rendered form
        var performedInsert = true
        textStorage.insertCharacters(at: insertionOp?.operationID(), strContent: str, addrArray: addrArray, updated: &performedInsert) // saves
        if performedInsert {
            for op in opArray {
                op.state = .inDownstreamQueueMergedRendered
            }
        }
    }
}
 


/**
 not thread safe - purely for use from the ViewContext
 */
public class CRTextStorage: NSTextStorage {
//    let container: CRObject
//    let attributeName: String
    var attributeOp: CDOperation
    var attributedString: NSMutableAttributedString = NSMutableAttributedString(string:"")
    var addressesArray: [CROperationID] = []
    
    var stringOptimiseCountDown = stringOptimiseQueueLengthMax
    
    var knownOperationForAddress: [CROperationID:CDOperation] = [:]
    var context: NSManagedObjectContext?
    
    
    // TODO: try later to use the self=NSTextStorage internal storage
    
    //Execute within context.perform of viewContext
    init(attributeOp: CDOperation) {
        self.attributeOp = attributeOp
        self.context = attributeOp.managedObjectContext
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
        attributeOp = CDOperation()
        super.init(coder: aDecoder)
    }
    
//    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
//        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
//    }
    
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
        replaceCharacters(in: range, with: strContent, saving: true)
    }
    
    public func replaceCharacters(in range: NSRange, with strContent: String, saving: Bool) {
        beginEditing()
        //TODO: - we may need a hash to track deleted operations


        if range.length > 0 {
            // TODO: delete operations in the range
            for address in addressesArray[range.location...(range.location+range.length-1)] {
//                let op = CDOperation.findOperationOrCreateGhost(from: address, in: context) //TODO: consider moving to background
                
                let delete = CDOperation.createDelete(context: context!, within: self.attributeOp, of: address)
                delete.state = .inUpstreamQueueRendered
            }
            if saving { try! context!.save() }
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

            let newOp:CDOperation = CDOperation.createStringInsert(context: context!, container: self.attributeOp, parentID: parentAddress, contribution: us)
            newOp.state = .inUpstreamQueueRendered
            let charAddress = newOp.operationID()
            strAddresses.append(charAddress)
            parentAddress = charAddress
        }
        //TODO: migrate to batch save as we can
        
        // insert
        attributedString.replaceCharacters(in: range, with: strContent)
        addressesArray.replaceElements(in: range, with: strAddresses)
        
        _ = CDRenderedStringOp(context: context!, containerOp: attributeOp, in: range, operationString: strContent, operationAddresses: strAddresses)
        if saving { try! context!.save() } // TODO: - make it save once a 60 objects
        considerSnapshotingStringBundle()

        edited(.editedCharacters,
               range: range,
               changeInLength: (strContent as NSString).length - range.length)
        endEditing()
        
        // TODO: how to fire save() on the last endEditing? do we have to?
        // maybe we could listen to: didProcessEditingNotification
    }
    
    // It's replacingCharacters with a known operations (for downstream rendering usage)
    public func insertCharacters(at insertionAddress: CROperationID?, strContent: String, addrArray: [CROperationID], updated: inout Bool) {

        var insertionPosition: Int? = nil
        if let insertionAddress = insertionAddress {
            insertionPosition = addressesArray.firstIndex(of: insertionAddress) // TODO: optimise (we could record cursors or we could have an address search tree, for now we use native search
            if insertionPosition == nil {
                updated = false
                return
            }
        } else {
            insertionPosition = 0
        }
        let range = NSRange(location: insertionPosition!+1, length: 0)

        beginEditing()
        // insert
        attributedString.replaceCharacters(in: range, with: strContent)
        addressesArray.replaceElements(in: range, with: addrArray)
        
        _ = CDRenderedStringOp(context: context!, containerOp: attributeOp, in: range, operationString: strContent, operationAddresses: addrArray)
        try! context!.save()
        considerSnapshotingStringBundle()

        edited(.editedCharacters,
               range: range,
               changeInLength: (strContent as NSString).length - range.length)
        endEditing()
        updated = true
    }
  
    //TODO: each setAttributes shall be a CRDT operation with range mapped to CRDT address space
    //TODO: allow for markdown driven formatting (subclass or something)
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        //TODO: each attribute set/delete will be an operation (TBD about the parent ID, I think it's string insert one except for deleted operations
        beginEditing()
//        print("setting attributes: \(attrs)")
        attributedString.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    
    private func prebuildStringBundleFromRenderedString(attributeOp: CDOperation) {
//        let context = attributeOp.managedObjectContext
        (attributedString, addressesArray) = CDRenderedStringOp.stringBundleFor(context: context!, container: attributeOp)
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




extension NSTextStorage {
    /**
    based on https://github.com/automerge/automerge-perf
    compare results with https://github.com/dmonad/crdt-benchmarks
     */
    public func loadFromJsonIndexDebug(limiter: Int = 1000000, bundle: Bundle = Bundle.main) {
        guard let path = bundle.path(forResource: "Data Assets/test-mk-editing-trace", ofType: "json") else {
            fatalError()
        }
        
        
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
