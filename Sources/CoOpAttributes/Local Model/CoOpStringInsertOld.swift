//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 24/02/2021.
//

import Foundation
import CoreData
import UIKit

@objc(CoOpAttributeStringInsert)
public class CoOpAttributeStringInsert: NSManagedObject {
    var renderedString: NSMutableString?
    var textStorageCache: CoOpTextStorage?
    var selectionStartOp: CoOpMutableStringOperationInsert?
    var selectionStartPos: Int = 0
    var selectionEndOp: CoOpMutableStringOperationInsert?
    var selectionEndPos: Int = 0
    deinit {
        print("CoOpAttributeStringInsert.deinit")
    }
}

extension CoOpAttributeStringInsert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpAttributeStringInsert> {
        return NSFetchRequest<CoOpAttributeStringInsert>(entityName: "CoOpAttributeStringInsert")
    }

    @NSManaged public var character: Int32
    @NSManaged public var next: CoOpAttributeStringInsert?
    @NSManaged public var prev: CoOpAttributeStringInsert?

}



extension CoOpAttributeStringInsert {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpAttributeStringInsert> {
        return NSFetchRequest<CoOpAttributeStringInsert>(entityName: "CoOpAttributeStringInsert")
    }
    @NSManaged public var version: Int16

    @NSManaged public var head: CoOpMutableStringOperationInsert // this should be always a zero element

    @NSManaged public var deletes: NSSet
    @NSManaged public var inserts: NSSet

    override public func awakeFromInsert() {
        setPrimitiveValue(CoOpMutableStringOperationInsert(contribution: "", parent: nil, attribute: self, context: self.managedObjectContext!), forKey: "head")
    }
}




protocol MinimalNSMutableAttributedString {
    var string: String { get } //should I expose the subscript somehow?
    func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any]

    func replaceCharacters(in range: NSRange, with str: String)
    func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange)
    
    // These primitives should perform the change, then call edited(_:range:changeInLength:) to let the parent class know what changes were made.
}


extension CoOpAttributeStringInsert: MinimalNSMutableAttributedString {
    
    
    public var textStorage: CoOpTextStorage {
        if textStorageCache == nil {
            textStorageCache = CoOpTextStorage(self)
        }
        return textStorageCache!
    }
    
    
    // Call this function before any search
    public var string: String {
//        print("string")
        if renderedString == nil {
            //we need to link all inserts as remote operaion may be linked to a deleted insert
//            let _ = Array(self.inserts)
//            let _ = Array(self.deletes)

            let request:NSFetchRequest<CoOpAttributeStringInsert> = CoOpAttributeStringInsert.fetchRequest()
            request.relationshipKeyPathsForPrefetching = ["inserts.inserts", "inserts.deletes"]
            request.fetchLimit = 1
            request.returnsObjectsAsFaults = false
            let predicate = NSPredicate(format: "self == %@", self)
            request.predicate = predicate
            
            let _ = try? self.managedObjectContext!.fetch(request)

            
            renderedString = NSMutableString(utf8String: walkTree())

            
//            let elements = walkTreeOld(skipDeleted: false)
//
//            var prev:CoOpMutableStringOperationInsert = head
//            for el in elements {
//                el.prev = prev
//                prev.next = el
//                prev = el
//            }
//            //TODO: why NSMutableString ??
//            renderedString = NSMutableString(utf8String: elements.filter({ $0.hasDeleteOperation() == false }).map({ $0.contribution }).joined())
        }
        return renderedString! as String
    }
    
    func invalidateCache() {
        renderedString = nil
    }
    
    func stringFromList() -> String {
        var text = ""
        var node:CoOpMutableStringOperationInsert? = head
        while node != nil {
            if node!.hasDeleteOperation() == false {
                text.append(node!.contribution)
            }
            node = node!.next
        }
        return text
    }
    

    public func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        //TODO implement
//        print("attributes for location:\(location)")
        let font = UIFont.systemFont(ofSize: 24)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.red,
        ]
        range?.pointee = NSRange(location: 0, length: string.count)
        return attributes
            //[:]
    }

    public func replaceCharacters(in range: NSRange, with str: String) {
        print("replaceCharacters")
//        invalidateCache()
        printTimeElapsedWhenRunningCode(title: "replaceCharacters duration: ") {
            
            let startOperation = getOperationFor(position: range.location)
            var posInRange = 0
            var currentOperation = startOperation
            while posInRange < range.length {
                currentOperation = currentOperation.next!
                posInRange += currentOperation.contribution.count
                markDeleted(currentOperation)
            }
            
            var locationOperation = startOperation
            let initialNext = locationOperation.next
            print("location: \(locationOperation)")
            print("pre insert: \(self)")
            for c in str {
                let cOperation = CoOpMutableStringOperationInsert(contribution: String(c), parent: locationOperation, attribute: self, context: self.managedObjectContext!)
                locationOperation.next = cOperation
                cOperation.prev = locationOperation
                print("new operation: \(cOperation)")
                locationOperation = cOperation
            }
            locationOperation.next = initialNext
            print("post insert: \(self)")

            renderedString?.replaceCharacters(in: range, with: str)
            //if debug:
//            let newString = walk().map({ $0.contribution }).joined()
//            assert(renderedString!.isEqual(to: newString))
//            let linkedString = stringFromList()
//            print("rendered: \(renderedString)")
//            print("linked: \(linkedString)")
//            assert(renderedString!.isEqual(to: linkedString))
        }
        //TODO implement delete
    }
    
    public func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        print("setAttributes")
        //TODO implement
    }
    

    // selection aware operation search
    // will crash if asked for location outside of the storage
    func getOperationFor(position: Int) -> CoOpMutableStringOperationInsert {
        var tempPosition = selectionStartPos
        var tempOperation:CoOpMutableStringOperationInsert
        if tempPosition == 0 { //TODO: this should go to some sort of container init
            tempOperation = head
        } else {
            tempOperation = selectionStartOp!
        }

        if position >= tempPosition {
            while tempPosition < position {
                tempOperation = tempOperation.next!
                tempPosition += tempOperation.contribution.count
            }
            return tempOperation
        } else {
            while tempPosition > position {
                tempPosition -= tempOperation.contribution.count
                tempOperation = tempOperation.prev!
            }
            return tempOperation
        }
    }

    
    public func walkTree() -> String {
        var previous = head
        var str = ""
        // head is empty
        func linkElement(_ operation: CoOpMutableStringOperationInsert) {
            previous.next = operation
            operation.prev = previous
            previous = operation
            if !operation.hasDeleteOperation() {
                str.append(operation.contribution)
            }
        }
        
        // stores all operations that we need to come back
        var stack = [CoOpMutableStringOperationInsert]()
        stack.append(contentsOf: head.reversedInserts())
        
        // we ignore head contribution as it's always ""

        while !stack.isEmpty {
            let operation = stack.popLast()!
            linkElement(operation)
            stack.append(contentsOf: operation.reversedInserts())
        }
        return str
    }
    
    public func walkTreeOld(skipDeleted: Bool = true,
                     action: (_ operation: CoOpMutableStringOperationInsert, _ escape: inout Bool) -> Void = {_,_ in }) -> [CoOpMutableStringOperationInsert] {
        var escape = false
        return walkTreeOld(from: head, escape: &escape, action: action)
    }
    
    //TODO: this will stack overflow - remove recursion
    //TODO: this is too slow on 1st document open
    func walkTreeOld(from operation: CoOpMutableStringOperationInsert,
              skipDeleted: Bool = true,
              escape: inout Bool,
              action: (_ operation: CoOpMutableStringOperationInsert, _ escape: inout Bool) -> Void = {_,_ in }) -> [CoOpMutableStringOperationInsert] {
        var ops = [CoOpMutableStringOperationInsert]()

        for operation in operation.sortedInserts() {
            if (skipDeleted == false) || (skipDeleted && !operation.hasDeleteOperation()) {
                ops.append(operation)
                action(operation, &escape)
                if escape {
                    break
                }
            }

            ops.append(contentsOf: walkTreeOld(from: operation, escape: &escape, action: action))
            if escape {
                break
            }
        }
        return ops
    }
    
    func markDeleted(_ operation: CoOpMutableStringOperationInsert) {
        let _ = CoOpMutableStringOperationDelete(parent: operation, attribute: self, context: self.managedObjectContext!)
//        assert(operation.hasDeleteOperation())
    }
    
    public func updateSelectionFrom(range: NSRange) {
        self.selectionStartOp = getOperationFor(position: range.location)
        self.selectionStartPos = range.location
        self.selectionEndOp = getOperationFor(position: range.location + range.length)
        self.selectionEndPos = range.location + range.length
        print("updated selection to:")
        print(" start: \(selectionStartPos) \(String(describing: selectionStartOp))")
        print("   end: \(selectionEndPos) \(String(describing: selectionEndOp))")
    }
}

// legacy
extension CoOpAttributeStringInsert {
    // returns operation you can insert after (op + len=1 i  split node language)
//    // if out of bounds then it will return the last operation
//    func getTreeOperationFor(_ location: Int) -> CoOpMutableStringOperationInsert {
//        if location == 0 {
//            return head
//        }
//        var position = 0
//        var locationOperation: CoOpMutableStringOperationInsert? = nil
//        let ops = walkTree() { operation, escape in
//            position += operation.contribution.count
//            if position >= location {
//                escape = true
//                locationOperation = operation
//            }
//        }
//        if locationOperation == nil {
//            locationOperation = ops.last
//        }
//        if locationOperation == nil {
//            locationOperation = head
//        }
//        return locationOperation!
//    }
//
//    func getOperationsFor(range: NSRange) -> (location: CoOpMutableStringOperationInsert, operations: [CoOpMutableStringOperationInsert]) {
//        var locationOperation: CoOpMutableStringOperationInsert? = nil
//        var operations = [CoOpMutableStringOperationInsert]()
//        var position = 0
//
//        if range.location == 0 {
//            locationOperation = head
//        }
//        let ops = walkTree() { operation, escape in
//            position += operation.contribution.count
//            if position == range.location {
//                locationOperation = operation
//            } else if position > range.location && position <= range.location + range.length {
//                operations.append(operation)
//            }
//        }
//        if locationOperation == nil {
//            if ops.last != nil {
//                locationOperation = ops.last
//            } else {
//                locationOperation = head
//            }
//        }
//        return (location: locationOperation!, operations: operations)
//    }
}


extension CoOpAttributeStringInsert {
//    public override var description: String {
//        var output = ""
//        let _ = walkTree() { operation, escape in
//            output += operation.description + "\n"
//        }
//        return output
//    }
}


extension CoOpAttributeStringInsert {
    /**
    based on https://github.com/automerge/automerge-perf
    compare results with https://github.com/dmonad/crdt-benchmarks
     */
    func loadFromJsonIndexDebug(limiter: Int = 1000000, bundle: Bundle = Bundle.main) {
        printTimeElapsedWhenRunningCode(title: "loadFromJsonIndexDebug") {
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
}
