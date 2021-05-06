import XCTest
import CoreData
@testable import CoOpAttributes


let lorem = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris vel massa eget metus sodales malesuada vitae sed turpis. Curabitur a maximus lorem. Nulla tempor lectus nulla, et rhoncus ex sollicitudin ac. Nunc et est ut leo ullamcorper placerat. Phasellus a arcu sed lacus elementum ullamcorper vitae sed massa. Cras eu convallis nisi. Vivamus varius aliquam tellus, in rutrum dui venenatis vel. Aliquam molestie turpis nec velit vulputate, et accumsan elit molestie. Donec rhoncus arcu viverra eros venenatis, a lacinia velit egestas. Proin tristique nulla non fringilla varius. Donec blandit ipsum in fermentum lobortis. Duis pretium tortor in accumsan dapibus. Aenean eu odio felis. Fusce eu est non nibh tincidunt malesuada. Aenean nulla purus, tristique et consectetur nec, commodo sed quam. Donec interdum velit ante, vel elementum mi euismod nec.

    Integer porttitor nulla non ligula placerat, id feugiat augue fermentum. Maecenas mattis diam sagittis ante feugiat, nec gravida augue vulputate. Sed aliquam porta mollis. Suspendisse potenti. Donec malesuada eros accumsan consectetur pharetra. Proin consectetur in ante nec fringilla. Vestibulum maximus eleifend arcu sit amet ultricies. Sed gravida libero sed eros iaculis fermentum. Praesent tincidunt nulla eu augue sagittis, id viverra nisl interdum. Donec tortor ex, sollicitudin id dapibus ultrices, fringilla sit amet sem. Pellentesque elementum dui a nibh pharetra fermentum. Cras in nunc id velit pulvinar pharetra.

    Proin ut convallis urna, ultrices luctus ex. Praesent nec nulla nisl. Aliquam vehicula interdum justo, vitae ultricies odio gravida ut. Donec fringilla bibendum nisl sed vulputate. Proin accumsan faucibus vehicula. Integer quis porta massa. Aliquam hendrerit non odio non gravida. Vestibulum accumsan in elit id consequat. Quisque in commodo augue.

    Proin lobortis varius leo, at euismod leo pretium vel. Integer et venenatis nisl, id cursus risus. Nam sit amet lobortis lacus. Interdum et malesuada fames ac ante ipsum primis in faucibus. Praesent ultricies lectus ut libero facilisis, ac consectetur tellus interdum. Sed non ex et ante euismod egestas. Nulla volutpat leo ut felis efficitur scelerisque nec vitae elit. Cras lectus lectus, vulputate sed nisl eleifend, condimentum iaculis justo.

    Proin egestas non ex ut elementum. Duis finibus pharetra risus semper sodales. Praesent non lectus consectetur, eleifend arcu quis, posuere nunc. Pellentesque accumsan hendrerit neque at ornare. Fusce commodo ante viverra risus dapibus, vitae facilisis nunc bibendum. Nulla a auctor turpis. Vivamus pharetra lobortis vestibulum. Aliquam dignissim massa ut purus imperdiet, id egestas diam auctor. Nam et laoreet nibh, eu semper lectus. Quisque ultricies magna nec cursus malesuada.

    Sed sit amet euismod tellus. Quisque congue, orci et lacinia elementum, augue enim fringilla odio, eget sollicitudin metus lacus eu metus. Aliquam non metus diam. In hac habitasse platea dictumst. Morbi mollis dolor luctus, sodales lectus sodales, tempus lectus. Vestibulum vel erat hendrerit, lobortis erat at, ullamcorper urna. Ut suscipit laoreet sem, sed egestas odio placerat sit amet. Morbi elit neque, porttitor eget finibus vitae, tincidunt sit amet ipsum. Nam erat erat, efficitur a risus a, vehicula condimentum est.

    Aliquam imperdiet est sit amet nunc euismod, in euismod ante luctus. Maecenas a enim sed tortor rhoncus tristique. Phasellus vel auctor est. Donec pretium, justo quis aliquam pretium, ex magna consectetur metus, sit amet interdum arcu est a lectus. Nullam cursus lacus vel mauris scelerisque vehicula. Donec efficitur ultricies ipsum, eget malesuada elit porttitor ac. Duis scelerisque elit odio. Donec ullamcorper eros non rutrum faucibus. Suspendisse potenti. In viverra diam odio, non tincidunt risus auctor sit amet. Nulla scelerisque leo vel arcu ultrices fringilla. Nullam quis bibendum tellus, sit amet facilisis diam. Donec efficitur ullamcorper hendrerit. Nullam libero nunc, ultricies at velit vitae, faucibus faucibus nisl.

    Sed lacus libero, placerat facilisis fermentum eget, consectetur sit amet enim. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec neque massa, dictum in mollis eu, maximus vitae ligula. Suspendisse ultrices et risus ac varius. Curabitur eget tortor id nisi cursus pharetra nec sit amet lectus. Aliquam tristique ornare mi id molestie. Nulla quis magna risus.

    Aenean lectus magna, aliquam ac massa non, euismod sollicitudin arcu. Cras a aliquam orci. Nulla porttitor augue id nunc lacinia tempor. Sed porta sagittis sapien, id aliquam dui finibus vitae. Vivamus ut metus augue. Suspendisse blandit est vitae lacus lacinia, sed malesuada ante malesuada. Nam id tincidunt eros. Proin tincidunt semper ante mollis tempus. Integer pellentesque vel ante quis sodales. Morbi facilisis sem mi, et mattis erat iaculis eu. Vivamus elit justo, mattis vel ex eget, sodales condimentum nisi.

    Aenean sed pulvinar elit, vitae pharetra leo. Sed congue tortor et ex vestibulum, convallis malesuada arcu lacinia. Praesent non arcu diam. Suspendisse dignissim est risus, vitae luctus lorem commodo ut. Praesent metus nulla, feugiat id gravida at, maximus vel risus. In faucibus diam sit amet turpis feugiat, in convallis nibh hendrerit. Vivamus ornare molestie vestibulum. Quisque varius vulputate placerat. Fusce tincidunt blandit mollis. Nam et magna consequat, auctor velit eu, lobortis justo. Duis tincidunt auctor leo, quis varius nulla vulputate quis. Maecenas commodo posuere malesuada. Aliquam facilisis ligula et aliquet venenatis.
    """


final class CoOpMutableStringTests: XCTestCase {

    override func setUpWithError() throws {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        print("setUpWithError")
        flushAllCoreData(CoOpPersistenceController.shared.container)
    }

    override func tearDownWithError() throws {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    // test lamport creation
    func testStorageAndWalking() {
        flushAllCoreData(CoOpPersistenceController.shared.container)

        let context = CoOpPersistenceController.shared.container.viewContext
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
        flushAllCoreData(CoOpPersistenceController.shared.container)

        let context = CoOpPersistenceController.shared.container.viewContext
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
            print("pre-fetch")
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

        measure {
            print("Walking linked list")
            _ = stringAttribute?.stringFromList()
        }
    }
    
    func testWalkingListBenchmark() {
        flushAllCoreData(CoOpPersistenceController.shared.container)

        let context = CoOpPersistenceController.shared.container.viewContext
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

        let context = CoOpPersistenceController.shared.container.viewContext
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
        flushAllCoreData(CoOpPersistenceController.shared.container)

        let context = CoOpPersistenceController.shared.container.viewContext
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
