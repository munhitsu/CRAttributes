import XCTest
import CoreData
import os.signpost
@testable import CRAttributes


let lorem = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam sed nisi gravida, bibendum ante et, vehicula diam. Integer at ligula sed lacus rhoncus pharetra. Duis consectetur sagittis ligula, ornare dapibus lorem tincidunt quis. Pellentesque rutrum, ante quis iaculis tristique, sem erat dapibus odio, ac facilisis justo augue sed metus. In ut semper lectus. Quisque vitae quam felis. Vivamus sed purus urna. In bibendum nibh ut gravida mattis. Interdum et malesuada fames ac ante ipsum primis in faucibus.

    Donec ut neque nisl. Pellentesque ullamcorper leo et nisi blandit, ullamcorper elementum lorem gravida. Suspendisse et consectetur diam. Duis in nunc et ipsum molestie tincidunt. Nam eleifend blandit gravida. Suspendisse mollis libero risus, interdum laoreet felis rhoncus et. Ut quam metus, facilisis ut euismod pharetra, feugiat non turpis. Aenean fermentum ex risus, ut posuere eros faucibus a. Aenean tempor luctus justo luctus pulvinar.

    Curabitur pharetra a sapien non fringilla. Pellentesque maximus semper tortor, id porttitor justo imperdiet sed. Aliquam tempor rutrum condimentum. Maecenas in erat venenatis, dapibus lectus vitae, pharetra tellus. Praesent nec finibus massa. Aliquam et scelerisque orci, ac pulvinar justo. Etiam consequat convallis mollis. Suspendisse ut ligula vitae urna facilisis dictum.

    Praesent at leo metus. Donec nec cursus nisl. Mauris laoreet hendrerit est non venenatis. Aenean at eros in felis faucibus semper eu at risus. Quisque tempus, lorem eu sagittis consectetur, felis mauris vulputate orci, vitae hendrerit leo urna id mi. Aliquam fermentum pharetra quam. Cras at odio nec lectus semper laoreet ut sed tellus. Vestibulum vel dui et leo venenatis aliquam quis ut felis. Maecenas suscipit molestie sollicitudin. Nulla pretium cursus lorem, ultrices elementum purus eleifend eget. Donec non odio ullamcorper, condimentum tortor at, hendrerit tellus.

    Nunc scelerisque enim lorem, ac interdum felis egestas ut. Duis ac suscipit massa. Nullam eleifend diam et tellus pharetra, at bibendum velit fermentum. Maecenas sed magna at augue tincidunt porta. Nunc lacinia est purus, sed laoreet mi tincidunt vitae. Mauris dignissim, quam sit amet rutrum egestas, risus augue imperdiet erat, eu lobortis quam felis vitae est. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nullam iaculis purus ut tincidunt finibus. Integer diam dolor, dapibus ut odio sit amet, lobortis fermentum arcu. Morbi eget venenatis eros, at pretium sem. Interdum et malesuada fames ac ante ipsum primis in faucibus.

    Praesent sollicitudin dapibus ultricies. Sed vel ante sed justo auctor accumsan. Nunc at finibus erat. In ultrices pulvinar nulla, vitae rutrum arcu consequat vitae. Proin viverra ut sem non posuere. Sed elementum, velit hendrerit sagittis imperdiet, quam orci mollis risus, et vulputate dolor ante vitae purus. Cras consequat maximus justo, eget mattis orci venenatis ut. Proin placerat finibus magna ac maximus.

    Nulla condimentum lorem vitae interdum commodo. Nam cursus purus libero, at pretium velit convallis a. Aenean lobortis a erat et vehicula. Vivamus finibus sagittis tincidunt. Aenean dolor odio, efficitur non diam ac, pellentesque commodo lorem. Donec gravida sem sit amet nisi auctor viverra. Integer feugiat vehicula luctus. Sed eu tincidunt metus. Aliquam varius, enim a bibendum ullamcorper, risus nisl luctus risus, sit amet venenatis est nulla in nisl. Duis sed malesuada felis. In vel velit et felis hendrerit laoreet at id magna. Suspendisse vitae maximus est, vitae interdum tortor.

    Morbi pellentesque nisl ut pulvinar viverra. Pellentesque feugiat lobortis turpis, iaculis faucibus diam. Suspendisse lobortis, elit eget iaculis vehicula, nunc nulla tempus felis, eu elementum libero metus sit amet libero. Sed ultricies nisi ut sapien maximus elementum. Aenean ac augue hendrerit, venenatis turpis non, fermentum lorem. Sed eu risus libero. Nullam sit amet dolor velit.

    Quisque iaculis massa magna, in eleifend libero dignissim at. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Cras tincidunt elementum nisl nec egestas. Etiam facilisis enim id ex aliquet dapibus. Sed commodo laoreet ante, nec facilisis dui. Proin quis commodo enim, nec vestibulum lectus. Duis rhoncus sit amet urna non rutrum. Suspendisse eget elit ullamcorper, feugiat tellus nec, mattis tellus. Maecenas ut felis mi. Mauris viverra massa vel rhoncus semper. Sed posuere turpis sed sagittis consequat. Proin id velit et ligula commodo dictum sit amet et nibh. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. In id sagittis urna. Sed purus dolor, interdum ut feugiat in, tristique nec erat. Nam non metus sit amet nibh vestibulum pulvinar.

    Aenean mollis felis ipsum, vulputate sagittis neque volutpat vitae. Etiam rutrum justo eu odio tincidunt, ac scelerisque turpis porttitor. Duis semper elit eget sapien sagittis, tempor malesuada ipsum suscipit. Nulla facilisi. Praesent finibus metus id lectus feugiat, non viverra orci tempus. In faucibus bibendum tincidunt. Sed cursus ut nibh quis porta. Fusce sit amet porta nunc. Vivamus bibendum ut nibh ut mattis.

    Nam fringilla efficitur massa, eget ultrices sapien cursus eget. Praesent scelerisque, tortor a dignissim venenatis, orci lectus imperdiet velit, non elementum velit erat id ligula. Donec porttitor est non ipsum maximus aliquam. Mauris non porta dui, sit amet bibendum tellus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Sed volutpat vitae metus quis convallis. Morbi vel finibus libero. Sed a turpis nec velit pellentesque eleifend at at felis. Maecenas quis felis eget orci viverra tincidunt. Sed vel lectus mauris.

    Proin at ipsum tempor, tempus erat eget, porta massa. Duis ultricies sit amet sapien nec sagittis. Curabitur tempus hendrerit lectus vitae pulvinar. Aenean sit amet nunc eu magna dignissim tempus. Quisque ac orci dapibus, maximus ipsum vitae, laoreet arcu. Mauris sodales imperdiet massa, eu varius eros porta eget. Aenean posuere ultrices metus, quis lobortis justo hendrerit quis. Vestibulum scelerisque urna in ipsum feugiat, quis fringilla turpis placerat. Phasellus vel lorem ut massa pretium eleifend. Aliquam a felis tempus, aliquam felis posuere, tincidunt ligula. In sit amet ipsum eu nisi accumsan vehicula nec nec tellus. Phasellus eget dolor dolor. Nulla id tincidunt purus. Aliquam efficitur aliquam elit, a ullamcorper arcu cursus feugiat. Curabitur convallis lectus vitae arcu imperdiet laoreet. Mauris eget dictum sem, accumsan condimentum lacus.

    Sed pharetra metus sed tincidunt finibus. Praesent odio massa, laoreet vitae turpis nec, iaculis malesuada dolor. Vivamus tempor nisi nec semper fringilla. In a eros mollis, porta lorem non, ultrices est. Duis felis tortor, elementum et pharetra ac, tempor at est. Morbi rutrum urna sapien, ut tristique nisi pretium posuere. Cras orci libero, sodales eu pretium a, hendrerit ut sem. Donec varius urna sodales ullamcorper dictum.

    In ut laoreet urna. Nunc purus purus, ornare quis sollicitudin in, egestas sit amet ligula. Curabitur sed tincidunt orci, sit amet tempus velit. Proin feugiat lorem sit amet augue fringilla, sed tristique libero rhoncus. Vivamus auctor elit eget scelerisque iaculis. Integer turpis tortor, lobortis et lectus non, mattis consequat lacus. Nulla est quam, ornare ut dolor et, congue pulvinar magna. Nulla hendrerit faucibus vestibulum. Mauris pellentesque, quam id bibendum faucibus, quam lorem tincidunt enim, scelerisque consectetur erat justo at ipsum.

    In gravida venenatis risus ac consequat. Maecenas ultrices massa leo, at mattis felis lacinia ut. Donec ac nunc enim. Morbi fringilla, purus nec rutrum auctor, elit eros porta velit, at tempus mauris libero vitae lectus. Phasellus ut dolor porta, sollicitudin neque sit amet, fermentum odio. Proin vitae imperdiet massa, ac suscipit magna. Integer odio velit, malesuada et fermentum vel, fermentum et eros. Suspendisse quis augue vitae justo porta semper. Fusce gravida in urna in aliquet. Aliquam dignissim metus ut eros tempus, ac faucibus orci maximus.

    Curabitur eleifend iaculis rhoncus. Nulla sed molestie nulla. Aenean finibus accumsan magna aliquam porta. Maecenas malesuada et eros ut suscipit. Donec sed tellus dignissim, tempor enim id, convallis ipsum. Aliquam fringilla blandit suscipit. Aliquam malesuada iaculis mauris, nec porttitor augue. Cras condimentum porttitor nibh at consectetur. Sed a nisi mollis, dictum ante vitae, hendrerit neque. In facilisis tempor turpis non interdum. Aenean condimentum ante nec velit placerat venenatis. Pellentesque augue lectus, consectetur non consectetur sodales, hendrerit nec tortor. Sed ac leo felis. Vivamus ornare est ac venenatis semper.

    Sed iaculis blandit tristique. Fusce non urna dignissim, venenatis dolor id, molestie tortor. Donec id eros a leo auctor consequat. In mollis lacinia ligula, non ultrices quam sollicitudin in. Mauris ac orci rhoncus, scelerisque dolor vel, luctus elit. Quisque laoreet lectus velit, ut rhoncus lectus consectetur a. Aenean eu pulvinar tellus. In dictum mattis mauris, ac convallis nisi interdum eget. Proin quis vestibulum purus. Donec ornare, lectus quis accumsan sagittis, enim lorem auctor diam, at sodales odio purus et ex. Nullam eget eros neque. Aliquam fermentum sodales imperdiet. Curabitur tincidunt quis lectus a lobortis. Morbi lacinia, nisl sed vulputate consequat, dolor tellus feugiat justo, a posuere ligula dolor id sapien.

    Cras pellentesque dictum facilisis. Phasellus sed turpis fermentum, tempus magna sit amet, tempus metus. Aenean blandit fringilla dapibus. Nunc quis ex nibh. Integer at velit et ipsum efficitur consectetur sit amet mollis magna. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vestibulum faucibus pharetra mattis. Suspendisse quis lacinia sem. Duis sed feugiat purus, eu maximus tortor. Donec maximus ex eget molestie.
    """


let posLogHandler = OSLog(subsystem: "test.load", category: .pointsOfInterest)

// adding out object type
extension CRObjectType {
    static let testNote = CRObjectType(rawValue: 2)
}


final class CRLocalOperationsTests: XCTestCase {
    
    override func setUpWithError() throws {
        super.setUp()
        CRStorageController.testMode() // in memory db
        flushAllCoreData(CRStorageController.shared.localContainer)
    }

    override func tearDownWithError() throws {
        super.tearDown()
    }
    
    func test00AttributeRecovery() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)
        let a1:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        a1.value = 1
        a1.value = 2
        XCTAssertEqual(a1.value, 2)
//        print("CRObjectOps:")
//        print(CDObjectOp.allObjects())
//
//        print("CDAttributeOps:")
//        print(CDAttributeOp.allObjects())
//
//        print("CRLLWOps:")
//        print(CDLWWOp.allObjects())

        let b_n1 = CRObject.allObjects(context: viewContext, type: .testNote)[0]
        XCTAssertEqual(b_n1.operation, n1.operation)
        
        let b_a1:CRAttributeInt = b_n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(b_a1.operation, a1.operation)
        XCTAssertEqual(b_a1.value, 2)

    }
    
    func test00Modeling() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)
        let a1:CRAttributeInt = n1.attribute(name: "count", type: .int) as! CRAttributeInt
        a1.value = 1
        XCTAssertEqual(a1.operationsCount(), 1)
        a1.value = 2
        XCTAssertEqual(a1.operationsCount(), 2)
        a1.value = 3
        XCTAssertEqual(a1.operationsCount(), 3)
        a1.value = 4
        XCTAssertEqual(a1.operationsCount(), 4)
        XCTAssertEqual(a1.value, 4)
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

        let a4:CRAttributeDate = n1.attribute(name: "created_on", type: .date) as! CRAttributeDate
        a4.value = Date()
        a4.value = Date()
        XCTAssertEqual(a4.operationsCount(), 2)
        
        
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

        
        let operationsLimit = 10
        let string = NSMutableAttributedString()
        string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: Self.self))
        
        let a7:CRAttributeMutableString = n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        a7.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        XCTAssertEqual(string.string, a7.textStorage!.string)
        XCTAssertEqual(a7.operationsCount(), operationsLimit)
        
        
        
        //restoring
        
        let b_n1 = CRObject.allObjects(context: viewContext, type: .testNote)[0]
        XCTAssertEqual(b_n1.operation, n1.operation)
        
        let b_a1:CRAttributeInt = b_n1.attribute(name: "count", type: .int) as! CRAttributeInt
        XCTAssertEqual(b_a1.operation, a1.operation)
        XCTAssertEqual(b_a1.value, 4)

        let b_a2:CRAttributeFloat = b_n1.attribute(name: "weight", type: .float) as! CRAttributeFloat
        XCTAssertGreaterThan(Double(b_a2.value!), 0.19)

        let b_a3:CRAttributeBool = b_n1.attribute(name: "active", type: .boolean) as! CRAttributeBool
        XCTAssertEqual(b_a3.value, true)

        let b_a4:CRAttributeDate = b_n1.attribute(name: "created_on", type: .date) as! CRAttributeDate
        XCTAssertEqual(b_a4.operationsCount(), 2)

        let b_a5:CRAttributeString = b_n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(b_a5.value, "abc")


        let b_a6:CRAttributeMutableString = b_n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(b_a6.textStorage!.string, "ABCdef")

        let b_a7:CRAttributeMutableString = b_n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(string.string, b_a7.textStorage!.string)

    }
    
    func test00StringSaveRestore() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext
//
//        expectation(
//          forNotification: .NSManagedObjectContextDidSave,
//          object: bgContext) { _ in
//            return true
//        }

        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)
        let a5:CRAttributeString = n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(a5.operationsCount(), 0)
        XCTAssertNil(a5.value)
        a5.value = "abc"
        XCTAssertEqual(a5.operationsCount(), 1)
        XCTAssertEqual(a5.value, "abc")

        
        // MutableString handcrafted
        let a6:CRAttributeMutableString = n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(a6.operationsCount(), 0)
//        XCTAssertNil(a6.value)
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "A")
        XCTAssertEqual(a6.textStorage!.string, "A")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 1, length: 0), with: "BCDEF")
        XCTAssertEqual(a6.textStorage!.string, "ABCDEF")
        a6.textStorage!.replaceCharacters(in: NSRange.init(location: 3, length: 3), with: "def")
        XCTAssertEqual(a6.textStorage!.string, "ABCdef")

        
        // MutableString from fixture
        let operationsLimit = 10
        let string = NSMutableAttributedString()
        string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: Self.self))
        
        let a7:CRAttributeMutableString = n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        a7.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        XCTAssertEqual(string.string, a7.textStorage!.string)
        XCTAssertEqual(a7.operationsCount(), operationsLimit)
        
        
        let a8:CRAttributeMutableString = n1.attribute(name: "note3", type: .mutableString) as! CRAttributeMutableString
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "A")
        XCTAssertEqual(a8.textStorage!.string, "A")
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "abc")
        XCTAssertEqual(a8.textStorage!.string, "abcA")
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "123")
        XCTAssertEqual(a8.textStorage!.string, "123abcA")
        a8.textStorage!.replaceCharacters(in: .init(location: 4, length: 1), with: "X")
        XCTAssertEqual(a8.textStorage!.string, "123aXcA")

        
        
        // TODO: add snapshot test
//        bgContext.performAndWait {
//            print("Blocking for the merge operations to finish")
//        }
        // test if rga form is correct
//        a7.textStorage?.prebuildAttributedStringFromOperations(attributeOp: a7.textStorage!.attributeOp)
//        XCTAssertEqual(string.string, a7.textStorage!.string)
        
        waitForStringAttributeValue(context: viewContext, operation: a7.operation!, value: string.string)
        
        let fromOp_a7 = a7.operation!.stringFromRGAList().0
        XCTAssertEqual(fromOp_a7.string, string.string)

//        let fromOp_a8 = a8.operation!.stringFromRGAList(context: viewContext).0
//        XCTAssertEqual(fromOp_a8.string, "123aXcA")
        waitForStringAttributeValue(context: viewContext, operation: a8.operation!, value:"123aXcA")
        
        CDOperation.printTreeOfContainers(context: viewContext)

        // Restoring
        let b_n1 = CRObject.allObjects(context: viewContext, type: .testNote)[0]
        XCTAssertEqual(b_n1.operation, n1.operation)
        
        let b_a5:CRAttributeString = b_n1.attribute(name: "title", type: .string) as! CRAttributeString
        XCTAssertEqual(b_a5.value, "abc")


        let b_a6:CRAttributeMutableString = b_n1.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(b_a6.textStorage!.string, "ABCdef")

        let b_a7:CRAttributeMutableString = b_n1.attribute(name: "note2", type: .mutableString) as! CRAttributeMutableString
        XCTAssertEqual(string.string, b_a7.textStorage!.string)


//        // not needed anymore, see above
//        waitForExpectations(timeout: 10.0) { error in
//            XCTAssertNil(error, "backgroundContext should save when performing merge")
//        }

        let fromOp_b_a7 = b_a7.operation!.stringFromRGAList().0
        XCTAssertEqual(fromOp_b_a7.string, string.string)

        
        // TODO: test restored string from RGA form
    }
    
    
    
    func test00MultipleInsertsAtZero() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext

        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)
        
        let a8:CRAttributeMutableString = n1.attribute(name: "note3", type: .mutableString) as! CRAttributeMutableString
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "ABC")
        XCTAssertEqual(a8.textStorage!.string, "ABC")
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "abc")
        XCTAssertEqual(a8.textStorage!.string, "abcABC")
        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "123")
        XCTAssertEqual(a8.textStorage!.string, "123abcABC")
        a8.textStorage!.replaceCharacters(in: .init(location: 4, length: 1), with: "X")
        XCTAssertEqual(a8.textStorage!.string, "123aXcABC")

        let expPredicate = NSPredicate(block: { op, _ -> Bool in
            guard let op = op as? CDOperation else { return false}
            return op.stringFromRGAList().0.string == "123aXcABC"
        })
        expectation(for: expPredicate, evaluatedWith: a8.operation)
        waitForExpectations(timeout: 10)

        XCTAssertEqual(a8.operation!.stringFromRGAList().0.string, "123aXcABC") // w already have it but reads better
        XCTAssertEqual(a8.operation!.stringFromRGATree().0.string, "123aXcABC")

    }
    
    /**
     test inserting one character into string - good for debugging head of the string
     */
    func test00InitialInsert() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let bgContext = CRStorageController.shared.localContainerBackgroundContext

        let n1 = CRObject(context: viewContext, type: .testNote, container: nil)


        let a8:CRAttributeMutableString = n1.attribute(name: "note3", type: .mutableString) as! CRAttributeMutableString
        print("Attribute ID: \(a8.operation?.operationID())")

        XCTAssertEqual(a8.operation!.stringFromRGAList().0.string, "") // w already have it but reads better
        XCTAssertEqual(a8.operation!.stringFromRGATree().0.string, "")

        a8.textStorage!.replaceCharacters(in: .init(location: 0, length: 0), with: "A")
        XCTAssertEqual(a8.textStorage!.string, "A")
        
        let expPredicate = NSPredicate(block: { op, _ -> Bool in
            guard let op = op as? CDOperation else { return false}
            return op.stringFromRGAList().0.string == "A"
        })
        expectation(for: expPredicate, evaluatedWith: a8.operation)
        waitForExpectations(timeout: 10)

        XCTAssertEqual(a8.operation!.stringFromRGAList().0.string, "A") // w already have it but reads better
        XCTAssertEqual(a8.operation!.stringFromRGATree().0.string, "A")

    }
  
    func waitForStringAttributeValue(context: NSManagedObjectContext, operation: CDOperation, value: String) {
        let expPredicate = NSPredicate(block: { operation, _ -> Bool in
            guard let operation = operation as? CDOperation else { return false}
            return operation.stringFromRGAList().0.string == value
        })
        expectation(for: expPredicate, evaluatedWith: operation)
        waitForExpectations(timeout: 10)
    }
    
    func test64CompareStringPerformanceUpstream() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let operationsLimit = 50000
        
        printTimeElapsedWhenRunningCode(title: "NSMutableAttributedString") {
            let string = NSMutableAttributedString()
            string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        }
        printTimeElapsedWhenRunningCode(title: "NSTextStorage") {
            let string = NSTextStorage()
            string.beginEditing()
            string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
            string.endEditing()
        }
        printTimeElapsedWhenRunningCode(title: "NSTextStorage w/o wrapping with begin/end Editing") {
            let string = NSTextStorage()
            string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
        }
        printTimeElapsedWhenRunningCode(title: "CRTextStorage") {
            let noteObject = CRObject(context: viewContext, type: .testNote, container: nil)
            let noteAttribute:CRAttributeMutableString = noteObject.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
            noteAttribute.textStorage!.beginEditing()
            noteAttribute.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
            noteAttribute.textStorage!.endEditing()
        }
//        // The line below triggers: "Terminated due to signal 9"
//        // TODO: (low) investigate why this triggers signal 9 while native NSTextStorage doesn't
//        printTimeElapsedWhenRunningCode(title: "CRTextStorage-each edit with NSTextStorage notifications") {
//            let string = CRTextStorage(container: CRObject(), attributeName: "foo")
//            string.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
//        }

    }
    
    func test64LoadingPerformanceUpstreamOperations() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let operationsLimit = 50000
        
        printTimeElapsedWhenRunningCode(title: "CRTextStorage") {
            let noteObject = CRObject(context: viewContext, type: .testNote, container: nil)
            let noteAttribute:CRAttributeMutableString = noteObject.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
            noteAttribute.textStorage!.beginEditing()
            noteAttribute.textStorage!.loadFromJsonIndexDebug(limiter: operationsLimit, bundle: Bundle(for: type(of: self)))
            noteAttribute.textStorage!.endEditing()
//            noteAttribute.textStorage!.considerSnapshotingStringBundle(force: true)
        }
        
        measure {
            let noteObject = CRObject.allObjects(context: viewContext, type: .testNote)[0]
            XCTAssertEqual(noteObject.operation, noteObject.operation)
            let noteAttribute = noteObject.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
            print("Loaded \(noteAttribute.textStorage!.string.count) charactrers")
        }
    }
    
    func test64LoadingPerformanceSinglePaste() {
        let viewContext = CRStorageController.shared.localContainer.viewContext
        let myText = lorem+lorem
        //+lorem+lorem+lorem+lorem

        print("String length:\(myText.count)")
        printTimeElapsedWhenRunningCode(title: "CRTextStorage") {
            let noteObject = CRObject(context: viewContext, type: .testNote, container: nil)
            let noteAttribute:CRAttributeMutableString = noteObject.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
            noteAttribute.textStorage!.beginEditing()
            noteAttribute.textStorage!.replaceCharacters(in: NSRange(location: 0, length: 0), with: myText)
            noteAttribute.textStorage!.endEditing()
        }
//        CRStorageController.shared.localContainer.viewContext.reset()
        measure {
            let noteObject = CRObject.allObjects(context: viewContext, type: .testNote)[0]
            XCTAssertEqual(noteObject.operation, noteObject.operation)
            let noteAttribute = noteObject.attribute(name: "note", type: .mutableString) as! CRAttributeMutableString
            print("Loaded \(noteAttribute.textStorage!.string.count) charactrers")
            XCTAssertEqual((noteAttribute.textStorage!.string), myText)
        }
    }
}


extension XCTest {
    func expectToEventually(_ test: @autoclosure () -> Bool, timeout: TimeInterval = 1.0, message: String = "") {
        let runLoop = RunLoop.current
        let timeoutDate = Date(timeIntervalSinceNow: timeout)
        repeat {
            // 1
            if test() {
                return
            }
            // 2
            runLoop.run(until: Date(timeIntervalSinceNow: 0.01))
        } while Date().compare(timeoutDate) == .orderedAscending // 3
        // 4
        XCTFail(message)
    }
}