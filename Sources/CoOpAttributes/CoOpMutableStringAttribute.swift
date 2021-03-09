//
//  File.swift
//  
//
//  Created by Mateusz Lapsa-Malawski on 24/02/2021.
//

import Foundation
import CoreData

@objc(CoOpMutableStringAttribute)
public class CoOpMutableStringAttribute: NSManagedObject {
}

extension CoOpMutableStringAttribute {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoOpMutableStringAttribute> {
        return NSFetchRequest<CoOpMutableStringAttribute>(entityName: "CoOpMutableStringAttribute")
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

extension CoOpMutableStringAttribute: MinimalNSMutableAttributedString {
    
    public var string: String {
        return walk().map({ $0.contribution }).joined()
    }

    public func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        fatalNotImplemented()
        return [:]
    }

    public func replaceCharacters(in range: NSRange, with str: String) {
        let opearationsRange = getOperationsFor(range:range)

        for operation in opearationsRange.operations {
            delete(operation)
        }
        
        var locationOperation = opearationsRange.location
        for c in str {
            let cOperation = CoOpMutableStringOperationInsert(contribution: String(c), parent: locationOperation, attribute: self, context: self.managedObjectContext!)
            locationOperation = cOperation
        }
        
        //TODO implement delete
    }
    
    public func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        fatalNotImplemented()
    }
    
    
    public func getTextStorage() -> CoOpTextStorage {
        return CoOpTextStorage(self)
    }
    
    // returns operation you can insert after (op + len=1 i  split node language)
    // if out of bounds then it will return the last operation
    func getOperationFor(_ location: Int) -> CoOpMutableStringOperationInsert {
        if location == 0 {
            return head
        }
        var position = 0
        var locationOperation: CoOpMutableStringOperationInsert? = nil
        let ops = walk() { operation, escape in
            position += operation.contribution.count
            if position >= location {
                escape = true
                locationOperation = operation
            }
        }
        if locationOperation == nil {
            locationOperation = ops.last
        }
        if locationOperation == nil {
            locationOperation = head
        }
        return locationOperation!
    }

    func getOperationsFor(range: NSRange) -> (location: CoOpMutableStringOperationInsert, operations: [CoOpMutableStringOperationInsert]) {
        var locationOperation: CoOpMutableStringOperationInsert? = nil
        var operations = [CoOpMutableStringOperationInsert]()
        var position = 0

        if range.location == 0 {
            locationOperation = head
        }
        let ops = walk() { operation, escape in
            position += operation.contribution.count
            if position == range.location {
                locationOperation = operation
            } else if position > range.location && position <= range.location + range.length {
                operations.append(operation)
            }
        }
        if locationOperation == nil {
            if ops.last != nil {
                locationOperation = ops.last
            } else {
                locationOperation = head
            }
        }
        return (location: locationOperation!, operations: operations)
    }
    
    
    public func walk(skipDeleted: Bool = true,
                     action: (_ operation: CoOpMutableStringOperationInsert, _ escape: inout Bool) -> Void = {_,_ in }) -> [CoOpMutableStringOperationInsert] {
        var escape = false
        return walk(from: head, escape: &escape, action: action)
    }
    
    func walk(from operation: CoOpMutableStringOperationInsert,
              skipDeleted: Bool = true,
              escape: inout Bool,
              action: (_ operation: CoOpMutableStringOperationInsert, _ escape: inout Bool) -> Void = {_,_ in }) -> [CoOpMutableStringOperationInsert] {
        var ops = [CoOpMutableStringOperationInsert]()

        for operation in operation.orderedInserts() {
            if (skipDeleted == false) || (skipDeleted && !operation.hasDeleteOperation()) {
                ops.append(operation)
                action(operation, &escape)
                if escape {
                    break
                }
            }

            ops.append(contentsOf: walk(from: operation, escape: &escape, action: action))
            if escape {
                break
            }
        }
        return ops
    }
    
    func delete(_ operation: CoOpMutableStringOperationInsert) {
        let _ = CoOpMutableStringOperationDelete(parent: operation, attribute: self, context: self.managedObjectContext!)
//        assert(operation.hasDeleteOperation())
    }
}


extension CoOpMutableStringAttribute {
    public override var description: String {
        var output = ""
        let _ = walk() { operation, escape in
            output += operation.description + "\n"
        }
        return output
    }
}


extension CoOpMutableStringAttribute {
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
