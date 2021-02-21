import XCTest
import CoreDataModelDescription
import CoreData
@testable import CoOpAttributes


@objc(TestNote)
public class TestNote: NSManagedObject {

}

extension TestNote {

//    @nonobjc public class func fetchRequest() -> NSFetchRequest<TestNote> {
//        return NSFetchRequest<TestNote>(entityName: "TestNote")
//    }

    @NSManaged public var version: Int16
    @NSManaged public var body: StringLwwCoOpAttribute?
    @NSManaged public var title: StringLwwCoOpAttribute?
}


let testModelDescription = CoreDataModelDescription(
    entities: [
        .entity(
            name: "TestNote",
            managedObjectClass: TestNote.self,
            attributes: [
                .attribute(name: "version", type: .integer16AttributeType),
            ],
            relationships: [
                .relationship(name: "body", destination: "StringLwwCoOpAttribute", optional: true, toMany: false),
                .relationship(name: "title", destination: "StringLwwCoOpAttribute", optional: true, toMany: false),
            ],
            indexes: []
        )
    ]
)

let testModel = testModelDescription.makeModel(byMerging: coOpModel)



var testPersistentContainer:NSPersistentContainer = {
    let container = NSPersistentContainer(name: "TestModel", managedObjectModel: testModel)
    
    //enable remote notifications
    guard let description = container.persistentStoreDescriptions.first else {
        fatalError("Failed to retrieve a persistent store description.")
    }
    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    
    container.loadPersistentStores { storeDesription, error  in
        guard error == nil else {
            print(container.persistentStoreDescriptions.first!.url!)
            fatalError("Unresolved error \(error!)")
            //, \(error.userInfo)
        }
    }

    container.viewContext.automaticallyMergesChangesFromParent = true //this may add extra load to the ViewContext when syncing
    container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
    container.viewContext.undoManager = nil // save cpu on MacOS
    container.viewContext.shouldDeleteInaccessibleFaults = true // clean data

//    NotificationCenter.default.addObserver(
//        self, selector: #selector(type(of: self).storeRemoteChange(_:)),
//        name: .NSPersistentStoreRemoteChange, object: nil)
    
    return container
}()


private func newTaskContext() -> NSManagedObjectContext {
    // Create a private queue context.
    let taskContext = testPersistentContainer.newBackgroundContext()
    taskContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
//    taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    // Set unused undoManager to nil for macOS (it is nil by default on iOS)
    // to reduce resource requirements.
    taskContext.undoManager = nil
    return taskContext
}


final class ModelTests: XCTestCase {
    func testStorage() {
        let expectation = self.expectation(description: #function)

        flushAllCoreData(container: testPersistentContainer)
        let context = testPersistentContainer.viewContext
        
        OperationID.updateLastLamportFromCoOpLog(in: context)
        
        let note = TestNote.init(context: context)
        let title = StringLwwCoOpAttribute.init(context: context)
        let body = StringLwwCoOpAttribute.init(context: context)

        note.title = title
        note.body = body
        note.version = 0

        note.title?.value = "foo"
        XCTAssertEqual(note.title?.value, "foo")
        note.title?.value = "foo1"
        XCTAssertEqual(note.title?.value, "foo1")
        note.title?.value = "foo2"
        XCTAssertEqual(note.title?.value, "foo2")
        
        note.body?.value = "bar"
        XCTAssertEqual(note.body?.value, "bar")

        do {
            try context.save()
        } catch let error as NSError {
            fatalError("ble \(error) from ble \(error.userInfo)")
        }

//        let noteID = note.objectID
        
        note.title?.value = "foo2"
        XCTAssertEqual(note.title?.value, "foo2")
        XCTAssertEqual(note.title?.operations?.allObjects.count, 1)
        
        // current version is not merging
        simmulateRemoteOperations()
        
//        testPersistentContainer.viewContext.refreshAllObjects()
//        testPersistentContainer.viewContext.reset()
        
//        note = testPersistentContainer.viewContext.object(with: noteID) as! TestNote
        
        print("sync title: \(note.title?.value ?? "nil")")
        XCTAssertEqual(note.title?.value, "foo2")
        DispatchQueue.main.async {
            print("async title: \(note.title?.value ?? "nil")")
            XCTAssertEqual(note.title?.value, "Remote")
            XCTAssertEqual(note.title?.operations?.allObjects.count, 2)
            XCTAssertEqual(note.body?.value, "Remote")
            XCTAssertEqual(note.body?.operations?.allObjects.count, 2)
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    /**
        will add remote operation to every StringLwwCoOpAttribute
     */
    func simmulateRemoteOperations() {
        print("simmulateRemoteOperations")
        let context = newTaskContext()
        context.performAndWait {
            let fetchRequest = StringLwwCoOpAttribute.fetchRequest() as! NSFetchRequest<StringLwwCoOpAttribute>
    //        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "lamport", ascending: false)]
    //        fetchRequest.fetchLimit = 1
            do {
                let attrs = try context.fetch(fetchRequest)
                var remoteLamport:Int64 = OperationID.lastLamport+1
                for attr in attrs {
                    print("extending \(attr)")
                    let logEntry = CoOpOperation.init(in: context, operation: Operation.with {
                        $0.id = OperationID.with{
                            $0.lamport = remoteLamport
                            $0.peerID = 1
                        }
                        $0.string = "Remote"
                    })
                    OperationID.newLamportSeen(remoteLamport)
                    print("adding \(logEntry)")
                    attr.addToOperations(logEntry)
                    remoteLamport += 1
                }

                try context.save()
                print("saved")
            } catch let error as NSError {
                print("Error on DB. \(error), \(error.userInfo)")
            }
        }
        
    }
    //TODO test constrain
    
    
    //TODO test remote update
}
