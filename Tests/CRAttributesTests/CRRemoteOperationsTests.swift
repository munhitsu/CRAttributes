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

    func waitForStringAttributeValue(context: NSManagedObjectContext, operation: CDOperation, value: String) {
        let expPredicate = NSPredicate(block: { operation, _ -> Bool in
            guard let operation = operation as? CDOperation else { return false}
            return operation.stringFromRGAList(context: context).0.string == value
        })
        expectation(for: expPredicate, evaluatedWith: operation)
        waitForExpectations(timeout: 10)
    }
    
    func waitForAllOperationsMergedOrProcessed(context: NSManagedObjectContext) {
        let expPredicate = NSPredicate(block: { _, _ -> Bool in
            var success = true
            context.performAndWait {
                let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
                request.returnsObjectsAsFaults = false
                let operations:[CDOperation] = try! context.fetch(request)
        
                for op in operations {
                    if ![CDOperationState.processed, CDOperationState.inUpstreamQueueRenderedMerged].contains(op.state) {
                        success = false
                        return
                    }
                }
            }
            return success
        })
        expectation(for: expPredicate, evaluatedWith: nil)
        waitForExpectations(timeout: 10)
    }
    
    func dummyLocalData() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext

        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)
        let a1:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        a1.value = 1
        XCTAssertEqual(a1.operationsCount(), 1)
        a1.value = 2
        XCTAssertEqual(a1.operationsCount(), 2)
        XCTAssertEqual(a1.value, 2)
        let a1b:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(a1.value, a1b.value)
        XCTAssertEqual(a1.operation, a1b.operation)

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
        
        let cdOp:CDOperation = a6.operation!
        checkStringOperationsCorrectness(cdOp)

        let operationsLimit = 10
        let string = NSMutableAttributedString()
        string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: Self.self))
        
        let a7:CRAttributeMutableString = n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        a7.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        XCTAssertEqual(string.string, a7.textStorage!.string)
        XCTAssertEqual(a7.operationsCount(), 11) // we don't count deletes anymore as delete container is the deleted operation
        
        try! viewContext.save() // this will force merging
        
        
//        waitForStringAttributeValue(context: viewContext, operation: a7.operation!, value: string.string)
        
//        bgContext.performAndWait {
//            print("Blocking for the merge operations to finish")
//        }
    }

    func appendToDummyLocalData() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext

        let note = CRObject.allObjects(context: viewContext, type: .testNote)[0]

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

        let textOp:CDOperation = text.operation!
        checkStringOperationsCorrectness(textOp)

        try! viewContext.save() // this will force merging
        bgContext.performAndWait {
            print("Blocking for the merge operations to finish")
        }
    }

    func checkStringOperationsCorrectness(_ cdAttribute: CDOperation) {
        var nodesSeen = Set<lamportType>()

        var headStringOperation:CDOperation? = nil
        for operation in cdAttribute.containedOperations() {
            if operation.state == .inDownstreamQueueMergedUnrendered {
                switch operation.type {
                case .delete:
                    print("ignoring Delete")
                case .stringInsert:
//                        print("op(\(op.lamport))=\(op.contribution) prev(\(String(describing: op.prev?.lamport)))")
                    if operation.prev == nil { // it will be only a new string in a new attribute in this scenario
                        assert(headStringOperation == nil)
                        headStringOperation = operation
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
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext
        dummyLocalData()
//        waitForAllOperationsMergedOrProcessed(context: bgContext)
//        waitForAllOperationsMergedOrProcessed(context: viewContext)
//        assertAllOperationsMergedOrProcessed(context: bgContext)
//        assertAllOperationsMergedOrProcessed(context: viewContext)
//        CRStorageController.shared.rgaController.linkUnlinked()
//        waitForAllOperationsMergedOrProcessed(context: bgContext)
//        waitForAllOperationsMergedOrProcessed(context: viewContext)
//        assertAllOperationsMergedOrProcessed(context: bgContext)
//        assertAllOperationsMergedOrProcessed(context: viewContext)

        var forests = CRStorageController.shared.replicationController.protoOperationsForests()
        
        XCTAssertEqual(forests.count, 1) //for now that's truth, will change
        
        let forest = forests[0]
        print(try! forest.jsonString())
  
        XCTAssertEqual(forest.peerID.object(), localPeerID)
        XCTAssertGreaterThan(try! forest.serializedData().count, 1400) // was 1400

        // testing in second run returns empty bundle
        let forests2 = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests2.count, 0, "Consequent forrest building should be empty as no new operations were created")
        
        bgContext.performAndWait {
            bgContext.reset()
        }
        
        let forests3 = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests3.count, 1, "After context reset we should get the previous state") //for now that's truth, will change
        XCTAssertGreaterThan(try! forests3[0].serializedData().count, 1400) // was 1400

        bgContext.performAndWait {
            bgContext.reset()
        }

        CRStorageController.shared.processUpsteamOperationsQueue()
        
        let remoteContext = CRStorageController.shared.replicationContainerBackgroundContext
        var cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 1)

        
        appendToDummyLocalData()

        //let's preview
        forests = CRStorageController.shared.replicationController.protoOperationsForests()
        XCTAssertEqual(forests.count, 1)
        for tree in forests[0].trees{
            print("Tree:")
            print(try! tree.jsonString())
        }
        
        XCTAssertEqual(forests[0].trees.count, 6)
//        print(try! forests[0].jsonString())
        bgContext.performAndWait {
            bgContext.reset()
        }

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
    
    func countUpstreamOps(context: NSManagedObjectContext) -> Int {
        print("countUpstreamOps")
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.predicate = NSPredicate(format: "rawState == %@", argumentArray: [CDOperationState.inUpstreamQueueRenderedMerged.rawValue])

//        let count = try! context.count(for: request)
        let results = try! context.fetch(request)
        for op in results {
            assert(op.state == .inUpstreamQueueRenderedMerged)
            print("op id:\(op.lamport) type:\(op.type) state:\(op.state)")
        }
        return results.count
    }

    
    func opCount(context: NSManagedObjectContext) -> Int {
        print("opCount")
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        
        let count = try! context.count(for: request)
        for op in try! context.fetch(request) {
            print("op id:\(op.lamport) type:\(op.type) state:\(op.state)")
        }
        return count
    }
    
    func assertAllOperationsMergedOrProcessed(context: NSManagedObjectContext) {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        for op in try! context.fetch(request) {
            assert([CDOperationState.processed, CDOperationState.inUpstreamQueueRenderedMerged].contains(op.state))
        }
    }
    
    func countGhosts(context: NSManagedObjectContext) -> Int {
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        request.predicate = NSPredicate(format: "rawType == %@", argumentArray: [CDOperationType.ghost.rawValue])
        return try! context.count(for: request)
    }
    
    func debugPrintOps(context: NSManagedObjectContext) {
        print("debugPrintOps")
        let request:NSFetchRequest<CDOperation> = CDOperation.fetchRequest()
        for op in try! context.fetch(request) {
            print("op id:\(op.lamport) type:\(op.type) state:\(op.state)")
        }
    }
    
    func testBundleRestore() throws {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext
        var ghostCount = 0
        // 1st batch of operations
        dummyLocalData()
        CRStorageController.shared.rgaController.linkUnlinked()
        waitForAllOperationsMergedOrProcessed(context: viewContext)

        let localOpsCount0 = opCount(context: viewContext)
        print("created ops batch 0: \(localOpsCount0)")
        let upstreamOps0 = countUpstreamOps(context: viewContext)
        print("waiting ops upstream 0: \(upstreamOps0)")

        XCTAssertEqual(upstreamOps0, localOpsCount0-2) // we are not shipping head operations

        CRStorageController.shared.processUpsteamOperationsQueue()
        XCTAssertEqual(countUpstreamOps(context: viewContext), 0)

        // 2nd batch of operations
        appendToDummyLocalData()
        CRStorageController.shared.rgaController.linkUnlinked()
        waitForAllOperationsMergedOrProcessed(context: viewContext)
        
        XCTAssertEqual(countUpstreamOps(context: viewContext), 12)
        CRStorageController.shared.processUpsteamOperationsQueue()
        XCTAssertEqual(countUpstreamOps(context: viewContext), 0)

        let localOpsCount1Appended = opCount(context: viewContext)-localOpsCount0
        print("created ops batch 1: \(localOpsCount1Appended)")
        XCTAssertEqual(localOpsCount1Appended, 12)
        
        // let's restore the operations in the inverted order to force issues (e.g. ghost containers)
        let remoteContext = CRStorageController.shared.replicationContainer.viewContext
        let cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 2)
        flushAllCoreData(CRStorageController.shared.localContainer)

        CRStorageController.shared.replicationController.processDownstreamForest(forest: cdForests[1].objectID)
        
        //TODO: test that inverted procesing has no impact
        
        print("bg Count: \(opCount(context: bgContext))")
        print("view Count: \(opCount(context: viewContext))")

        let localCount3 = opCount(context: viewContext)
        print("second batch restored: \(localCount3)")
        XCTAssertEqual(localCount3, localOpsCount1Appended+4) //4 ghosts
        ghostCount = countGhosts(context: viewContext)
        XCTAssertEqual(ghostCount, 4)
//        debugPrintOps(context: viewContext)
        
        print(cdForests[1].protoStructure())
        
        CRStorageController.shared.replicationController.processDownstreamForest(forest: cdForests[0].objectID)

        let localCount4 = opCount(context: viewContext)
        print("1st batch restored: \(localCount4)")
        print(localCount4)
        XCTAssertEqual(localOpsCount0+localOpsCount1Appended, localCount4)
        ghostCount = countGhosts(context: viewContext)
        XCTAssertEqual(ghostCount, 0)
        debugPrintOps(context: viewContext)

        
        
        //validate if operations are properly merged

        let b_n1 = CRObject.allObjects(context: viewContext, type: .testNote)[0]
        
        let b_a1:CRAttributeInt = b_n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(b_a1.value, 4)

        let b_a2:CRAttributeFloat = b_n1.attribute(name: "weight", type: .float) as! CRAttributeFloat
        XCTAssertGreaterThan(Double(b_a2.value!), 0.19)

        let b_a3:CRAttributeBool = b_n1.attribute(name: "active", type: .boolean) as! CRAttributeBool
        XCTAssertEqual(b_a3.value, true)

//        let b_a4:CRAttributeDate = b_n1.attribute(name: "created_on", type: .date) as! CRAttributeDate
//        XCTAssertEqual(b_a4.operationsCount(), 2)
        
        XCTAssertEqual(opCount(context: viewContext), localCount4)

        let b_a5:CRAttributeString = b_n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(b_a5.value, "abc")

        let b_a6:CRAttributeMutableString = b_n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(b_a6.textStorage!.string, "123def###")

    }

}
