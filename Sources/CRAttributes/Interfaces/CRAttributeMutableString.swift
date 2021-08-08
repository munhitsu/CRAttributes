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
    let textStorage: CRTextStorage

    init(container:CRObject, name:String) {
        textStorage = CRTextStorage()
        super.init(container: container, name: name, type: .mutableString)
        textStorage.attributeOp = self.operation
    }

    override init(from:CRAttributeOp) {
        textStorage = CRTextStorage(attributeOp: from)
        super.init(from: from)
    }
}




extension NSAttributedString.Key {
    static let opObjectID = NSAttributedString.Key("CRObjectID")
}
 


class CRTextStorage: NSTextStorage {
//    let container: CRObject
//    let attributeName: String
    var attributeOp: CRAttributeOp?
    let attributedString: NSMutableAttributedString // TODO: later use the internal storage

    override init() {
//        self.container = container
//        self.attributeName = attributeName
        attributedString = NSMutableAttributedString(string:"")
        attributeOp = nil
        super.init()
    }
    
    init(attributeOp: CRAttributeOp) {
        self.attributeOp = attributeOp
        
        //we can pre-fetch only inserts as deletes are never used here
        let request:NSFetchRequest<CRStringInsertOp> = CRStringInsertOp.fetchRequest()
        request.returnsObjectsAsFaults = false
        request.predicate = NSPredicate(format: "attribute == %@", attributeOp)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CRStringInsertOp.parent, ascending: true)]

        let context = CRStorageController.shared.localContainer.viewContext

        let cdOps:[CRStringInsertOp] = try! context.fetch(request)
        print(cdOps.first)
        //TODO: walk and render
        attributedString = NSMutableAttributedString(string:"")
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalNotImplemented()
//        self.container = CRObject()
//        self.attributeName = ""
        attributedString = NSMutableAttributedString(string:"")
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

    public override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()

        let attributeOp:CRAttributeOp? = nil

        // insertion address
        var parentOp:CRStringInsertOp? = nil
        if range.location > 0 {
            parentOp = operationForPosition(range.location)
        }

        // deleting operations
        for position in range.location...(range.location + range.length) {
            let op = operationForPosition(position)
            markDeleted(op)
        }
                
        let strAttributed = NSMutableAttributedString(string: str)
        
        var prevOp = parentOp
        for position in 0...strAttributed.length {
            let newOp:CRStringInsertOp = CRStringInsertOp(context: CRStorageController.shared.localContainer.viewContext, parent: prevOp, attribute: attributeOp, character: strAttributed.mutableString.character(at: position))
            strAttributed.setAttributes([.opObjectID: newOp.objectID], range: NSRange(location: position, length: 1))
            prevOp?.next = newOp
            newOp.prev = prevOp
            prevOp = newOp
        }
        
        attributedString.replaceCharacters(in: range, with: strAttributed)

        let tailPosition = range.location + strAttributed.length + 1
        if tailPosition <= attributedString.length {
            let tailOp = operationForPosition(tailPosition)
            tailOp.prev = prevOp
            prevOp?.next = tailOp
        }
        
        edited(.editedCharacters,
               range: range,
               changeInLength: (str as NSString).length - range.length)
        endEditing()
        
        // TODO: how to fire it on the last endEditing ?
        // we could listen to: didProcessEditingNotification
        try! CRStorageController.shared.localContainer.viewContext.save()
    }
    
    func operationForPosition(_ position: Int) -> CRStringInsertOp {
        let objectID:NSManagedObjectID = attributedString.attribute(.opObjectID, at: position, effectiveRange: nil) as! NSManagedObjectID
        return CRStorageController.shared.localContainer.viewContext.object(with: objectID) as! CRStringInsertOp
    }

//    unused
//    func setOperationForPosition(_ operation: CoOpStringInsert, _ position: Int) {
//        attributedString.setAttributes([.opObjectID: operation.objectID], range: NSRange(location: position, length: 1))
//    }
    
    func markDeleted(_ operation: CRAbstractOp) {
        let _ = CRDeleteOp(context: CRStorageController.shared.localContainer.viewContext, parent: operation, attribute: operation.attribute)
        operation.hasTombstone = true
    }
    
    
    // each setAttributes shall be a CRDT operation with range mapped to CRDT address space
    public override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
//        beginEditing()
//        attributedString.setAttributes(attrs, range: range)
//        edited(.editedAttributes, range: range, changeInLength: 0)
//        endEditing()
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
                if arrayIndex > limiter {
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
