//
//  CRAttributedStringTests.swift
//  CRAttributedStringTests
//
//  Created by Mateusz Lapsa-Malawski on 29/08/2021.
//

import XCTest
@testable import CRAttributes


var container:NSPersistentContainer?
var context:NSManagedObjectContext?

//
//class CRAttributedStringTests: XCTestCase {
//    var strWithOpID:NSMutableAttributedString?
//    var strWithObjID:NSMutableAttributedString?
//    var strWithNil:NSMutableAttributedString?
//    var longLorem = lorem+lorem+lorem+lorem+lorem
//
//    
//    override class func setUp() {
////        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
////        print(paths[0])
////        CRStorageController.testMode()
//        container = CRStorageController.shared.localContainer
//        context = container?.viewContext
//
//        for description in container!.persistentStoreDescriptions {
//            print("db location: \(description.url?.path ?? "")")
//        }
//        flushAllCoreData(container!)
//    }
//
////    func buildStr(myLorem: String) {
////        printTimeElapsedWhenRunningCode(title: "buildStringWithOpID") {
////            strWithOpID = NSMutableAttributedString()
////
////            for c in myLorem {
////                let cStr = String(c)
////                let cOp:CDStringInsertOp = CDStringInsertOp(context: context!, parent: nil, container: nil, contribution: cStr)
////                try! context!.save()
////                let cWithOpID = NSMutableAttributedString(string: cStr, attributes:
////                                                            [
////                                                                .opObjectID: cOp.objectID,
////                                                                .opLamport: cOp.lamport,
////                                                                .opPeerID: cOp.peerID
////                                                          ])
////                strWithOpID!.append(cWithOpID)
////            }
////        }
////    }
//
//    
//    func buildStrWithNil(myLorem: String) {
//        printTimeElapsedWhenRunningCode(title: "buildStrWithNil") {
//            strWithObjID = NSMutableAttributedString()
//            
//            for c in myLorem {
//                let cStr = String(c)
//                let cWithObjID = NSMutableAttributedString(string: cStr)
//                strWithObjID!.append(cWithObjID)
//            }
//        }
//    }
//    
////    func buildStrWithOpID(myLorem: String) {
////        printTimeElapsedWhenRunningCode(title: "buildStringWithOpID") {
////            strWithOpID = NSMutableAttributedString()
////
////            for c in myLorem {
////                let cStr = String(c)
////                let cOp:CDStringInsertOp = CDStringInsertOp(context: context!, parent: nil, container: nil, contribution: cStr)
////                try! context!.save()
////                let cWithOpID = NSMutableAttributedString(string: cStr, attributes:
////                                                            [
////                                                                .opLamport: cOp.lamport,
////                                                                .opPeerID: cOp.peerID
////                                                          ])
////                strWithOpID!.append(cWithOpID)
////            }
////        }
////    }
////
////    func buildStrWithOpIDBulk(myLorem: String) {
////        printTimeElapsedWhenRunningCode(title: "buildStringWithOpID") {
////            strWithOpID = NSMutableAttributedString()
////
////            for c in myLorem {
////                let cStr = String(c)
////                let cOp:CDStringInsertOp = CDStringInsertOp(context: context!, parent: nil, container: nil, contribution: cStr)
////                try! context!.save()
////                let cWithOpID = NSMutableAttributedString(string: cStr, attributes:
////                                                            [
////                                                                .opLamport: cOp.lamport,
////                                                                .opPeerID: cOp.peerID
////                                                          ])
////                strWithOpID!.append(cWithOpID)
////            }
////        }
////    }
//
////    func buildStrWithOpIDBulkOptimised(myLorem: String, bundleSize: Int=60) {
////        printTimeElapsedWhenRunningCode(title: "buildStringWithOpID") {
////            strWithOpID = NSMutableAttributedString()
////
//////            let bundleSize = 100
////            var bundleCounter = 0
////
////            for c in myLorem {
////                bundleCounter += 1
////                let cStr = String(c)
////                let cOp:CDStringInsertOp = CDStringInsertOp(context: context!, parent: nil, container: nil, contribution: cStr)
////                let cWithOpID = NSMutableAttributedString(string: cStr, attributes:
////                                                            [
////                                                                .opLamport: cOp.lamport,
////                                                                .opPeerID: cOp.peerID
////                                                          ])
////                strWithOpID!.append(cWithOpID)
////                if bundleCounter > bundleSize {
////                    bundleCounter = 0
////                    try! context!.save()
////                }
////            }
////            try! context!.save()
////        }
////    }
////
////    func buildStrWithObjID(myLorem: String) {
////        printTimeElapsedWhenRunningCode(title: "buildStrWithObjID") {
////            strWithObjID = NSMutableAttributedString()
////
////            for c in myLorem {
////                let cStr = String(c)
////                let cOp:CDStringInsertOp = CDStringInsertOp(context: context!, parent: nil, container: nil, contribution: cStr)
////                try! context!.save()
////                let cWithObjID = NSMutableAttributedString(string: cStr, attributes: [.opObjectID: cOp.objectID])
////                strWithObjID!.append(cWithObjID)
////            }
////        }
////    }
////
////
////    func fetchFromObjID() {
////        printTimeElapsedWhenRunningCode(title: "fetchFromObjID") {
////            for position in 0..<(strWithObjID?.string.count ?? -1) {
////                let objectID:NSManagedObjectID = strWithObjID!.attribute(.opObjectID, at: position, effectiveRange: nil) as! NSManagedObjectID
////                let strOp:CDStringInsertOp = CRStorageController.shared.localContainer.viewContext.object(with: objectID) as! CDStringInsertOp
////                _ = strOp.contribution
////
////        //            print(op.contribution)
////            }
////        }
////    }
////
////    func fetchFromOpID() {
////        printTimeElapsedWhenRunningCode(title: "fetchFromOpID") {
////            for position in 0..<(strWithOpID?.string.count ?? -1) {
////                let lamport = strWithOpID!.attribute(.opLamport, at: position, effectiveRange: nil) as! lamportType
//////                let peerID = strWithOpID!.attribute(.opPeerID, at: position, effectiveRange: nil) as! UUID
////                let strOp:CDStringInsertOp = fetchOperation(fromLamport: lamport, in: context!) as! CDStringInsertOp
////                _ = strOp.contribution
//////                let op:CDStringInsertOp = CDAbstractOp.operation(fromLamport: lamport, fromPeerID: peerID, in: context) as! CDStringInsertOp
//////                    print(op.contribution)
////            }
////        }
////    }
//
//    func fetchFromSortedList() {
//        printTimeElapsedWhenRunningCode(title: "fetchFromSortedList") {
//            let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
//            request.predicate = NSPredicate(format: "container == nil")
//            let ops = try! context!.fetch(request)
//            for op in ops {
//                let strOp = op as! CDStringInsertOp
//                _ = strOp.contribution
//            }
//            print(ops.count)
//        }
//    }
//    
//    
//    override func setUpWithError() throws {
////        context.stalenessInterval = 0.0;
////        print("lorem length: \(longLorem.count)")
// 
////        buildStrWithNil()§    q
////        buildStringWithOpID()
////        buildStrWithObjID()
//    }
//
//    override func tearDownWithError() throws {
//        context!.reset()
//        // Put teardown code here. This method is called after the invocation of each test method in the class.
//    }
//
//    func testFetchFromObjID() throws {
//        buildStrWithObjID(myLorem: longLorem)
//        fetchFromObjID()
//        context!.reset()
//        fetchFromObjID()
//    }
//
//    func testFetchFromOpID() throws {
//        buildStrWithOpID(myLorem: longLorem)
//        fetchFromOpID()
//        context!.reset()
//        fetchFromOpID()
//    }
//
//    func testFetchFromSortedList() throws {
//        buildStrWithObjID(myLorem: longLorem)
//        fetchFromObjID()
//        context!.reset()
//        fetchFromObjID()
//        context!.reset()
//        fetchFromSortedList()
//        context!.reset()
//        fetchFromSortedList()
//    }
//    
//    func testPrototype() throws {
////        buildStrWithObjID(myLorem: lorem)
////        fetchFromObjID()
////        context!.reset()
////        fetchFromObjID()
////        context!.reset()
//        fetchFromSortedList()
//        context!.reset()
//        fetchFromSortedList()
//    }
//    
//    func testNoCacheFetchFromSortedList() throws {
//        //TODO: how to test the fetch from old DB???
//        fetchFromSortedList()
//        context!.reset()
//        fetchFromSortedList()
//    }
//
//    func fetchOperation(fromLamport:lamportType, in context: NSManagedObjectContext) -> CDAbstractOp? {
//        let request:NSFetchRequest<CDAbstractOp> = CDAbstractOp.fetchRequest()
//        request.predicate = NSPredicate(format: "lamport == %@", argumentArray: [fromLamport])
//        request.fetchLimit = 1
//        let ops = try? context.fetch(request)
//        return ops?.first
//    }
//    
//    
//    func testPerformanceExample() throws {
//        // This is an example of a performance test case.
//        self.measure {
////            buildStrWithNil()
//            // Put the code you want to measure the time of here.
//        }
//    }
//    
//    func testCompareBulkSave() throws {
//        // about the threshold when bulk save becomes more expensive
//        // so we can't use batch save as we have references - do we need references?
//        // bulk save is not bad but 1340 seems to be the go even with save on each
//        let shortLorem = String(lorem[...lorem.index(lorem.startIndex, offsetBy: 1340)])
//        print("Reference:")
//        buildStrWithNil(myLorem: shortLorem)
//        buildStrWithObjID(myLorem: shortLorem)
//        print("Finding max bundle size:")
//        buildStrWithOpID(myLorem: shortLorem)
//        buildStrWithOpIDBulk(myLorem: shortLorem)
//    }
//    
//    func testOptimalBulkSave() throws {
//        print("Optimal bundle size:")
//        measure {
//            buildStrWithOpIDBulkOptimised(myLorem: lorem, bundleSize: 60)
//        }
////        buildStrWithOpID(myLorem: longLorem)
//    }
//}
