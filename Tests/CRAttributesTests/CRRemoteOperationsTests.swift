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
        // Put setup code here. This method is called before the invocation of each test method in the class.
        flushAllCoreData(CRStorageController.shared.localContainer)
        flushAllCoreData(CRStorageController.shared.replicatedContainer)
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
        XCTAssertEqual(a6.operationsCount(), 0)
//        XCTAssertNil(a6.value)
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "A")
        XCTAssertEqual(a6.textStorage!.string, "A")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 1, length: 0), with: "BCDEF")
        XCTAssertEqual(a6.textStorage!.string, "ABCDEF")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 3, length: 3), with: "def")
        XCTAssertEqual(a6.textStorage!.string, "ABCdef")

        let operationsLimit = 1000
        let string = NSMutableAttributedString()
        string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: Self.self))
        
        let a7:CRAttributeMutableString = n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        a7.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        XCTAssertEqual(string.string, a7.textStorage!.string)
        XCTAssertEqual(a7.operationsCount(), operationsLimit)
    }

    func testBundleCreation() throws {
        dummyLocalData()
        
        let context = CRStorageController.shared.localContainer.viewContext
        let forests = CRStorageController.protoOperationsForests(context: context)
        XCTAssertEqual(forests.count, 1) //for now that's truth, will change
        
        let forest = forests[0]
//        print(try! forest.jsonString())
  
        XCTAssertEqual(forest.peerID.object(), localPeerID)
        XCTAssertGreaterThan(try! forest.serializedData().count, 8000)

        // testing in second run returns empty bundle
        let forests2 = CRStorageController.protoOperationsForests(context: context)
        XCTAssertEqual(forests2.count,0)
        
        context.reset()
        
        let forests3 = CRStorageController.protoOperationsForests(context: context)
        XCTAssertGreaterThan(try! forests3[0].serializedData().count, 8000)

        context.reset()
        

        CRStorageController.processUpsteamOperationsQueue()
        
        let remoteContext = CRStorageController.shared.replicatedContainer.newBackgroundContext()
        let cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 1)
        
        
        //TODO: count objects in the replicated / scan proto form of the forest

//        let protoBundle = CRStorageController.protoOperationsBundle()
//        XCTAssertEqual(protoBundle.objectOperations.count, CRObjectOp.allObjects().count)
//        XCTAssertGreaterThan(protoBundle.attributeOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.lwwOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.stringInsertOperations.count, 0)
//        XCTAssertGreaterThan(protoBundle.deleteOperations.count, 0)
    }

    func testBundleRestore() throws {
        dummyLocalData()
        CRStorageController.processUpsteamOperationsQueue()
        let remoteContext = CRStorageController.shared.replicatedContainer.newBackgroundContext()
        let cdForests = CDOperationsForest.allObjects(context: remoteContext)
        XCTAssertEqual(cdForests.count, 1)
        flushAllCoreData(CRStorageController.shared.localContainer)
        CRStorageController.processDownstreamForest(forest: cdForests[0].objectID)
        //TODO: test that string was properly restored
    }

}
