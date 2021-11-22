//
//  CRRemoteOperationsTests.swift
//  CRRemoteOperationsTests
//
//  Created by Mateusz Lapsa-Malawski on 13/08/2021.
//

import XCTest
@testable import CRAttributes

class CRRemoteOperationsTests: XCTestCase {

    override func setUpWithError() throws {
        try super.setUpWithError()
        CRStorageController.testMode() // in memory db
        // Put setup code here. This method is called before the invocation of each test method in the class.
        flushAllCoreData(CRStorageController.shared.localContainer)
        flushAllCoreData(CRStorageController.shared.replicationContainer)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    
    func dummyLocalData() {
        let n1 = CRObject(type: .testNote, container: nil)
        let a1:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        a1.value = 1
        XCTAssertEqual(a1.operationsCount(), 1)
        a1.value = 2
        XCTAssertEqual(a1.operationsCount(), 2)
        XCTAssertEqual(a1.value, 2)
        let a1b:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(a1.value, a1b.value)
        XCTAssertEqual(a1.operationObjectID, a1b.operationObjectID)

        let a2:CRAttributeFloat = n1.attribute(name: "weight", type: .float) as! CRAttributeFloat
        a2.value = 0.1
        a2.value = 0.2
        XCTAssertGreaterThan(Double(a2.value!), 0.19)

        let a3:CRAttributeBool = n1.attribute(name: "active", type: .boolean) as! CRAttributeBool
        a3.value = false
        a3.value = true
        XCTAssertEqual(a3.value, true)

        // TODO: implement
//        let a4:CRAttributeDate = n1.attribute(name: "created_on", type: .date) as! CRAttributeDate
//        a4.value = Date()
//        a4.value = Date()
//        XCTAssertEqual(a4.operationsCount(), 2)
        
        
        let a5:CRAttributeString = n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(a5.operationsCount(), 0)
        XCTAssertNil(a5.value)
        a5.value = "abc"
        XCTAssertEqual(a5.operationsCount(), 1)
        XCTAssertEqual(a5.value, "abc")

        let a6:CRAttributeMutableString = n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(a6.operationsCount(), 1)
//        XCTAssertNil(a6.value)
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "A")
        XCTAssertEqual(a6.textStorage!.string, "A")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 1, length: 0), with: "BCDEF")
        XCTAssertEqual(a6.textStorage!.string, "ABCDEF")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 3, length: 3), with: "def")
        XCTAssertEqual(a6.textStorage!.string, "ABCdef")
        
        let context = CRStorageController.shared.localContainer.viewContext
        let cdOp:CDAttributeOp = context.object(with: a6.operationObjectID!) as! CDAttributeOp
        checkStringOperationsCorrectness(cdOp)

        let operationsLimit = 10
        let string = NSMutableAttributedString()
        string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: Self.self))
        
        let a7:CRAttributeMutableString = n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        a7.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        XCTAssertEqual(string.string, a7.textStorage!.string)
        XCTAssertEqual(a7.operationsCount(), 11) // we don't count deletes anymore as delete container is the deleted operation
    }

    func appendToDummyLocalData() {
        let note = CRObject.allObjects(type: .testNote)[0]

        let count:CRAttributeInt = note.attribute(name: "count", type: .int) as! CRAttributeInt
        count.value = 4 // operations: 1

        let text:CRAttributeMutableString = note.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(text.textStorage!.string, "ABCdef")
        
        text.textStorage!.replaceCharacters(in: NSRange.init(location: 0, length: 3), with: "123") // operations: 6
        XCTAssertEqual(text.textStorage!.string, "123def")

        text.textStorage!.replaceCharacters(in: NSRange.init(location: 6, length: 0), with: "###") // operations: 3
        XCTAssertEqual(text.textStorage!.string, "123def###")

        text.textStorage!.replaceCharacters(in: NSRange.init(location: 6, length: 2), with: "") // operations: 2
        XCTAssertEqual(text.textStorage!.string, "123def#")

        let context = CRStorageController.shared.localContainer.viewContext
        let textOp:CDAttributeOp = context.object(with: text.operationObjectID!) as! CDAttributeOp
        checkStringOperationsCorrectness(textOp)
    }

    func countUpstreamOps() -> Int {
        let localContext = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        request.predicate = NSPredicate(format: "upstreamQueueOperation == true")

        return try! localContext.count(for: request)
    }
    
    func checkStringOperationsCorrectness(_ cdAttribute: CDAttributeOp) {
        var nodesSeen = Set<lamportType>()

        var headStringOperation:CDStringOp? = nil
        for operation in cdAttribute.containedOperations() {
            if operation.state == .inDownstreamQueueMergedUnrendered {
                switch operation {
                case _ as CDDeleteOp:
                    print("ignoring Delete")
                case let op as CDStringOp:
//                        print("op(\(op.lamport))=\(op.contribution) prev(\(String(describing: op.prev?.lamport)))")
                    if op.prev == nil { // it will be only a new string in a new attribute in this scenario
                        assert(headStringOperation == nil)
                        headStringOperation = op
                    }
                default:
                    fatalError("unsupported subOperation")
                }
            }
        }
        var node = headStringOperation
        while node != nil {
            assert(nodesSeen.contains(node!.lamport) == false)
            nodesSeen.insert(node!.lamport)
            node = node!.next
        }
    }

    func testBundleCreation() throws {
        dummyLocalData()
        
        let context = CRStorageController.shared.localContainer.viewContext
        var forests = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests.count, 1) //for now that's truth, will change
        
        let forest = forests[0]
//        print(try! forest.jsonString())
  
        XCTAssertEqual(forest.peerID.object(), localPeerID)
        XCTAssertGreaterThan(try! forest.serializedData().count, 1400)

        // testing in second run returns empty bundle
        let forests2 = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests2.count,0)
        
        context.reset()
        
        let forests3 = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertGreaterThan(try! forests3[0].serializedData().count, 1400)

        context.reset()
        

        CRStorageController.shared.processUpsteamOperationsQueue()
        
        let remoteContext = CRStorageController.shared.replicationContainer.viewContext
        var cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 1)

        
        appendToDummyLocalData()

        //let's preview
        forests = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests.count, 1)
        XCTAssertEqual(forests[0].trees.count, 6)
//        print(try! forests[0].jsonString())
        context.reset()

        //formal upload
        CRStorageController.shared.processUpsteamOperationsQueue()

        cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 2)
        //TODO: count
        // count trees in the 1nd forest = 1
        // count trees in the 2nd forest = 2
        

        //TODO: count objects in the replication / scan proto form of the forest

//        let protoBundle = CRStorageController.protoOperationsBundle()
//        XCTAssertEqual(protoBundle.objectOperations.count, CDObjectOp.allObjects().count)
//        XCTAssertGreaterThan(protoBundle.attributeOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.lwwOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.stringInsertOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.deleteOperations.count, 0)
    }
    
    func opCount() -> Int {
        let localContext = CRStorageController.shared.localContainer.viewContext
        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
        
        return try! localContext.count(for: request)
    }

    func testBundleRestore() throws {
        // 1st batch of operations
        dummyLocalData()
        let upstreamOps = countUpstreamOps()
        let localCount1 = opCount()
        print("created batch 1: \(localCount1)")
        XCTAssertEqual(upstreamOps, localCount1)

        CRStorageController.shared.processUpsteamOperationsQueue()
        XCTAssertEqual(countUpstreamOps(), 0)

        // 2nd batch of operations
        appendToDummyLocalData()
        XCTAssertEqual(countUpstreamOps(), 12)
        CRStorageController.shared.processUpsteamOperationsQueue()
        XCTAssertEqual(countUpstreamOps(), 0)

        let localCount2 = opCount()-localCount1
        print("created batch 2: \(localCount2)")
        XCTAssertEqual(localCount2, 12)
        
        // let's restore the operations in the inverted order to force issues
        let remoteContext = CRStorageController.shared.replicationContainer.viewContext
        let cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 2)
        flushAllCoreData(CRStorageController.shared.localContainer)
        
        CRStorageController.shared.replicationController.processDownstreamForest(forest: cdForests[1].objectID)
        
        let localCount3 = opCount()
        print("second batch restored: \(localCount3)")
        XCTAssertEqual(localCount3, localCount2)

        print(cdForests[1].protoStructure())
        
        CRStorageController.shared.replicationController.processDownstreamForest(forest: cdForests[0].objectID)

        let localCount4 = opCount()
        print("1st batch restored: \(localCount4)")
        print(localCount4)
        XCTAssertEqual(localCount1+localCount2, localCount4)

        
        
        //validate if operations are properly merged

        let b_n1 = CRObject.allObjects(type: .testNote)[0]
        
        let b_a1:CRAttributeInt = b_n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(b_a1.value, 4)

        let b_a2:CRAttributeFloat = b_n1.attribute(name: "weight", type: .float) as! CRAttributeFloat
        XCTAssertGreaterThan(Double(b_a2.value!), 0.19)

        let b_a3:CRAttributeBool = b_n1.attribute(name: "active", type: .boolean) as! CRAttributeBool
        XCTAssertEqual(b_a3.value, true)

//        let b_a4:CRAttributeDate = b_n1.attribute(name: "created_on", type: .date) as! CRAttributeDate
//        XCTAssertEqual(b_a4.operationsCount(), 2)
        
        XCTAssertEqual(opCount(), localCount4)

        let b_a5:CRAttributeString = b_n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(b_a5.value, "abc")

        let b_a6:CRAttributeMutableString = b_n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(b_a6.textStorage!.string, "123def###")

    }

}
