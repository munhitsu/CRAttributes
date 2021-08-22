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


extension NSAttributedString.Key {
    static let opObjectID = NSAttributedString.Key("CRObjectID")
}
 

class CRTextStorage: NSTextStorage {
//    let container: CRObject
//    let attributeName: String
    var attributeObjectID: NSManagedObjectID
    var attributedString: NSMutableAttributedString? = nil
    // TODO: try later to use the self=NSTextStorage internal storage

//    override init() {
////        self.container = container
////        self.attributeName = attributeName
//        attributedString = NSMutableAttributedString(string:"")
//        attributeOp = nil
//        super.init()
//    }
    
    //Execute within context.perform
    init(attributeOp: CDAttributeOp) {
        self.attributeObjectID = attributeOp.objectID
        attributedString = NSMutableAttributedString(string:"")
        super.init()
        prebuildAttributedStringFromOperations(attributeOp: attributeOp)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
        attributedString = NSMutableAttributedString(string:"")
        attributeObjectID = NSManagedObjectID()
        super.init(coder: aDecoder)
    }

    // subclasses should implement it to execute in O(1) time.
    // source https://developer.apple.com/documentation/foundation/nsattributedstring/1412616-string
    public override var string: String {
        get {
            return attributedString?.string ?? ""
        }
    }

    public override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return attributedString?.attributes(at: location, effectiveRange: range) ?? [:]
    }

    public override func replaceCharacters(in range: NSRange, with str: String) {
        let context = CRStorageController.shared.localContainer.viewContext
        let attributeOp:CDAttributeOp = (context.object(with: attributeObjectID) as? CDAttributeOp)!
        beginEditing()
        //TODO: - we may need a hash to track deleted operations


        
        // identify the prev and next for the insertion point (link to deleted operations)
        
        let insertHeadOp:CDStringInsertOp?
        let insertTailOp:CDStringInsertOp?
        
        if range.location == 0 {
            insertHeadOp = nil
            insertTailOp = firstOp(context: context, attributeOp: attributeOp)
        } else {
            insertHeadOp = operationForPosition(range.location - 1)
            insertTailOp = insertHeadOp?.next
        }
        
        // deleting operations
        for position in range.location..<(range.location + range.length) {
            let op = operationForPosition(position)
            markDeleted(op)
        }

        // create a string to insert with all linked operatations
        let strAttributed = NSMutableAttributedString(string: str)
        
        var prevOp = insertHeadOp
        for position in 0..<strAttributed.length {
            let newOp:CDStringInsertOp = CDStringInsertOp(context: context, parent: prevOp, container: attributeOp, contribution: strAttributed.mutableString.character(at: position))
            prevOp?.next = newOp
            newOp.prev = prevOp
            try! context.save() // we need to save to obtain the objectID
            strAttributed.setAttributes([.opObjectID: newOp.objectID], range: NSRange(location: position, length: 1))
            prevOp = newOp
        }
        let lastOp = prevOp
        
        attributedString!.replaceCharacters(in: range, with: strAttributed)

        lastOp?.next = insertTailOp
        insertTailOp?.prev = lastOp
        
        try! context.save()

        edited(.editedCharacters,
               range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
        
        // TODO: how to fire save() on the last endEditing? do we have to?
        // we could listen to: didProcessEditingNotification
    }
    
    func firstOp(context: NSManagedObjectContext, attributeOp: CDAttributeOp) -> CDStringInsertOp? {
        let request:NSFetchRequest<CDStringInsertOp> = CDStringInsertOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and prev == nil", attributeOp)
        return try? context.fetch(request).first
    }
    
    func operationForPosition(_ position: Int) -> CDStringInsertOp {
        let objectID:NSManagedObjectID = attributedString!.attribute(.opObjectID, at: position, effectiveRange: nil) as! NSManagedObjectID
        return CRStorageController.shared.localContainer.viewContext.object(with: objectID) as! CDStringInsertOp
    }

//    unused
//    func setOperationForPosition(_ operation: CoOpStringInsert, _ position: Int) {
//        attributedString.setAttributes([.opObjectID: operation.objectID], range: NSRange(location: position, length: 1))
//    }
    
    func markDeleted(_ operation: CDAbstractOp) {
        let context = CRStorageController.shared.localContainer.viewContext
        let _ = CDDeleteOp(context: context, container: operation)
        operation.hasTombstone = true
    }
    
    
    // each setAttributes shall be a CRDT operation with range mapped to CRDT address space
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
//        beginEditing()
//        attributedString.setAttributes(attrs, range: range)
//        edited(.editedAttributes, range: range, changeInLength: 0)
//        endEditing()
    }

    func prebuildAttributedStringFromOperations(attributeOp: CDAttributeOp) {
        let context = CRStorageController.shared.localContainer.viewContext

        // let's prefetch
        // there is no need to prefetch delete operations as we have the hasTombstone attribute
        var request:NSFetchRequest<CDStringInsertOp> = CDStringInsertOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@", attributeOp)
        let _ = try! context.fetch(request)
        
        // let's get the first operation
        request = CDStringInsertOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "container == %@ and prev == nil", attributeOp)
        let head:CDStringInsertOp? = try? context.fetch(request).first
        
        // build the attributedString
        attributedString = NSMutableAttributedString("")
        var node:CDStringInsertOp? = head
        while node != nil {
            if node!.hasTombstone == false {
                let contribution = NSMutableAttributedString(string:node!.contribution)
                contribution.setAttributes([.opObjectID: node!.objectID], range: NSRange(location: 0, length: 1))
                attributedString!.append(contribution)
            }
            node = node!.next
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
