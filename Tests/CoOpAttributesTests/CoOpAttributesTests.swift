import XCTest
@testable import CoOpAttributes


final class CoOpAttributesTests: XCTestCase {
//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct
//        // results.
//        XCTAssertEqual(CoOpAttributes().text, "Hello, World!")
//    }

    func testStorage() {
        let context = CoOpPersistenceController.shared.container.viewContext
        let stringAttribute = CoOpMutableStringAttribute.init(context: context)
        stringAttribute.version = 0
        
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        print(stringAttribute.objectID.uriRepresentation())
    }

//    static var allTests = [
//        ("testExample", testExample),
//    ]
}
