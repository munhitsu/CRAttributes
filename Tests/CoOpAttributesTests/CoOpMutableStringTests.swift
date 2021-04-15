import XCTest
@testable import CoOpAttributes


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
        
        XCTAssertEqual(stringAttribute.getOperationFor(0).contribution,"")
        XCTAssertEqual(stringAttribute.getOperationFor(1).contribution,"A")
        XCTAssertEqual(stringAttribute.getOperationFor(2).contribution,"B")

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
        XCTAssertEqual(stringAttribute.getOperationFor(100).contribution, "F")

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
