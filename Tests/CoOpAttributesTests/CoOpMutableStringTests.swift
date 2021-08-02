import XCTest
import CoreData
@testable import CoOpAttributes


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


final class CoOpMutableStringTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print("setUpWithError")
        flushAllCoreData(CoOpLocalContainerController.shared.container)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // test lamport creation
    func testStorageAndWalking() {
        flushAllCoreData(CoOpLocalContainerController.shared.container)

        let context = CoOpLocalContainerController.shared.container.viewContext
        let stringAttribute = CoOpMutableStringAttribute(context: context)
        stringAttribute.version = 0
        XCTAssertEqual(stringAttribute.string, "")
        stringAttribute.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "ABCDEF") // ABCDEF
        XCTAssertEqual(stringAttribute.string, "ABCDEF")
        
        XCTAssertEqual(stringAttribute.getOperationFor(position:0).contribution,"")
        XCTAssertEqual(stringAttribute.getOperationFor(position:1).contribution,"A")
        XCTAssertEqual(stringAttribute.getOperationFor(position:2).contribution,"B")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "123") // 123 ABCDEF
        XCTAssertEqual(stringAttribute.string, "123ABCDEF")
        stringAttribute.replaceCharacters(in: NSRange.init(location: 6, length: 0), with: "XYZ") // 123 ABC XYZ DEF
        XCTAssertEqual(stringAttribute.string, "123ABCXYZDEF")
        XCTAssertEqual(stringAttribute.stringFromList(), "123ABCXYZDEF")


        
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        print(stringAttribute.objectID.uriRepresentation())
        print(stringAttribute)

        XCTAssertEqual(stringAttribute.string, "123ABCXYZDEF")
        XCTAssertEqual(stringAttribute.getOperationFor(position:12).contribution, "F")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 0, length: 3), with: "")
        print(stringAttribute)
        XCTAssertEqual(stringAttribute.string, "ABCXYZDEF")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "123")
        print(stringAttribute)
        XCTAssertEqual(stringAttribute.string, "123ABCXYZDEF")
        
        stringAttribute.replaceCharacters(in: NSRange.init(location: 0, length: 3), with: "000")
        print(stringAttribute)
        XCTAssertEqual(stringAttribute.string, "000ABCXYZDEF")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 6, length: 3), with: "000")
        XCTAssertEqual(stringAttribute.string, "000ABC000DEF")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 9, length: 3), with: "222222")
        XCTAssertEqual(stringAttribute.string, "000ABC000222222")

        stringAttribute.replaceCharacters(in: NSRange.init(location: 15, length: 0), with: "111")
        XCTAssertEqual(stringAttribute.string, "000ABC000222222111")

//        XCTAssertThrowsError(try stringAttribute.replaceCharacters(in: NSRange.init(location: 99, length: 0), with: "111"))
        
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

    }

    
    func testWalkingFaultsBenchmark() {
        flushAllCoreData(CoOpLocalContainerController.shared.container)

        let context = CoOpLocalContainerController.shared.container.viewContext
        var stringAttribute:CoOpMutableStringAttribute? = CoOpMutableStringAttribute(context: context)
        stringAttribute!.version = 0
        stringAttribute!.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: lorem)
        stringAttribute!.replaceCharacters(in: NSRange.init(location: 0, length: 10), with: "ABCD")

        var strCount = stringAttribute?.string.count as! Int
        print("lorem len: \(strCount)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        print("reset")
        context.reset()
        print("deinit")
        stringAttribute = nil

        measure {
            print("fetch")
            let request:NSFetchRequest<CoOpMutableStringAttribute> = CoOpMutableStringAttribute.fetchRequest()
//            request.fetchLimit = 1
//            request.relationshipKeyPathsForPrefetching = ["inserts.inserts", "inserts.deletes"]
//            request.returnsObjectsAsFaults = false
            let rows = try? context.fetch(request)
            stringAttribute = rows?.first
            print("crawl")
            strCount = stringAttribute?.string.count as! Int
            print("lorem len: \(strCount)")
            XCTAssertGreaterThan(strCount, 100)
            print("reset")
            context.reset()
            print("deinit")
            stringAttribute = nil
        }
    }
    
    func testWalkingListBenchmark() {
        flushAllCoreData(CoOpLocalContainerController.shared.container)

        let context = CoOpLocalContainerController.shared.container.viewContext
        var stringAttribute:CoOpMutableStringAttribute? = CoOpMutableStringAttribute(context: context)
        stringAttribute!.version = 0
        stringAttribute!.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: lorem)
        stringAttribute!.replaceCharacters(in: NSRange.init(location: 0, length: 10), with: "ABCD")

        var strCount = stringAttribute?.string.count as! Int
        print("lorem len: \(strCount)")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        print("crawl as tree")
        strCount = stringAttribute?.string.count as! Int

        print("lorem len: \(strCount)")
        XCTAssertGreaterThan(strCount, 100)

        measure {
            print("Walking linked list")
            _ = stringAttribute?.stringFromList()
        }
    }
    
    func testPerformance() {
        let limiter = 2000 //TODO change limitted interpretation to characters count

        let context = CoOpLocalContainerController.shared.container.viewContext
        let stringAttribute = CoOpMutableStringAttribute(context: context)
        stringAttribute.version = 0
        XCTAssertEqual(stringAttribute.string, "")
        
        stringAttribute.loadFromJsonIndexDebug(limiter: limiter, bundle: Bundle(for: type(of: self)))
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        print("saved")
        measure {
            print("loading")
            let _ = stringAttribute.string
        }

    }
  
    
    func testSaveAndLoad() {
        flushAllCoreData(CoOpLocalContainerController.shared.container)

        let context = CoOpLocalContainerController.shared.container.viewContext
        var stringAttribute:CoOpMutableStringAttribute? = CoOpMutableStringAttribute(context: context)
        stringAttribute?.version = 0
        XCTAssertEqual(stringAttribute?.string, "")
        stringAttribute?.replaceCharacters(in: NSRange.init(location: 0, length: 0), with: "ABCDEF") // ABCDEF
        stringAttribute?.replaceCharacters(in: NSRange.init(location: 3, length: 3), with: "def") // ABCDEF
        XCTAssertEqual(stringAttribute?.string, "ABCdef")
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        
        print("reset")
        context.reset()
        print("deinit")
        stringAttribute = nil
        
        let request:NSFetchRequest<CoOpMutableStringAttribute> = CoOpMutableStringAttribute.fetchRequest()
        request.fetchLimit = 1
        var rows = try? context.fetch(request)
        var str = rows?.first

        XCTAssertEqual(str!.string, "ABCdef")
        str?.replaceCharacters(in: NSRange.init(location: 1, length: 0), with: " ") // ABCDEF
        str?.replaceCharacters(in: NSRange.init(location: 3, length: 0), with: " ") // ABCDEF
        str?.replaceCharacters(in: NSRange.init(location: 5, length: 0), with: " ") // ABCDEF
        str?.replaceCharacters(in: NSRange.init(location: 7, length: 0), with: " ") // ABCDEF
        str?.replaceCharacters(in: NSRange.init(location: 9, length: 0), with: " ") // ABCDEF
        XCTAssertEqual(str!.string, "A B C d e f")
        XCTAssertEqual(str!.stringFromList(), "A B C d e f")
        print(str?.head.treeDescription ?? "")

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        print("reset")
        context.reset()
        print("deinit")
        stringAttribute = nil

        rows = try? context.fetch(request)
        str = rows?.first
        XCTAssertEqual(str!.string, "A B C d e f")
        print(str?.head.treeDescription ?? "")
    }
    
    func testRemoteChanges() {
        
    }
//    static var allTests = [
//        ("testExample", testExample),
//    ]
}
