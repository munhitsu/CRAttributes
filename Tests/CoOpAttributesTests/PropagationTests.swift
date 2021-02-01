import XCTest
import CoreDataModelDescription
import CoreData
@testable import CoOpAttributes


@objc(NameDocument)
public class NameDocument: NSManagedObject {

}

extension NameDocument {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NameDocument> {
        return NSFetchRequest<NameDocument>(entityName: "NameDocument")
    }

    @NSManaged public var name: String?
}


let nameModelDescription = CoreDataModelDescription(
    entities: [
        .entity(
            name: "NameDocument",
            managedObjectClass: NameDocument.self,
            attributes: [
                .attribute(name: "name", type: .stringAttributeType),
            ],
            indexes: []
        )
    ]
)

let nameModel = nameModelDescription.makeModel()




var namePersistentContainer:NSPersistentContainer = {
    let container = NSPersistentContainer(name: "NameTestModel", managedObjectModel: nameModel)
    
    //enable remote notifications
//    guard let description = container.persistentStoreDescriptions.first else {
//        fatalError("Failed to retrieve a persistent store description.")
//    }
//    description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
    
    container.loadPersistentStores { storeDesription, error  in
        guard error == nil else {
            print(container.persistentStoreDescriptions.first!.url!)
            fatalError("Unresolved error \(error!)")
            //, \(error.userInfo)
        }
    }

//    container.viewContext.automaticallyMergesChangesFromParent = true //this may add extra load to the ViewContext when syncing
    container.viewContext.mergePolicy = NSMergePolicy(merge: .overwriteMergePolicyType)
    container.viewContext.undoManager = nil // save cpu on MacOS
    container.viewContext.shouldDeleteInaccessibleFaults = true // clean data

//    NotificationCenter.default.addObserver(
//        self, selector: #selector(type(of: self).storeRemoteChange(_:)),
//        name: .NSPersistentStoreRemoteChange, object: nil)
    
    return container
}()




/**
 https://stackoverflow.com/questions/55678116/automaticallymergeschangesfromparent-doesnt-do-anything
 */
final class PropagationTests: XCTestCase {
    func testChildUpdatedByParent() {
        let expectation = self.expectation(description: #function)
        
        let myDocument = NameDocument(context: namePersistentContainer.viewContext)
        myDocument.name = "TEST"
        namePersistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContext.parent = namePersistentContainer.viewContext
        childContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContext.automaticallyMergesChangesFromParent = true
        
        let myDocumentFromParent:NameDocument = namePersistentContainer.viewContext.object(with: myDocument.objectID) as! NameDocument
        let myDocumentFromChild:NameDocument = childContext.object(with: myDocument.objectID) as! NameDocument
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME Child \(myDocumentFromChild.name!)")
        print("Setting NAME=JO using Parent")
        myDocumentFromParent.name = "JO"
        print("NAME Orginal \(myDocument.name!)")
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME Child \(myDocumentFromChild.name!)")
        print("Saving")
        do {
            try namePersistentContainer.viewContext.save()
        } catch let error as NSError {
            print("Error on DB. \(error), \(error.userInfo)")
        }
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME Child \(myDocumentFromChild.name!)")
        XCTAssertEqual(myDocumentFromChild.name, "TEST")
        DispatchQueue.main.async {
            print("NAME Child(async) \(myDocumentFromChild.name!)")
            XCTAssertEqual(myDocumentFromChild.name, "JO")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
    
    func testChildrenPropagation() {
        let expectation = self.expectation(description: #function)
        
        let myDocument = NameDocument(context: namePersistentContainer.viewContext)
        myDocument.name = "TEST"
        namePersistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let childContextA = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContextA.parent = namePersistentContainer.viewContext
        childContextA.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContextA.automaticallyMergesChangesFromParent = true

        let childContextB = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContextB.parent = namePersistentContainer.viewContext
        childContextB.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContextB.automaticallyMergesChangesFromParent = true

    
        let myDocumentFromParent:NameDocument = namePersistentContainer.viewContext.object(with: myDocument.objectID) as! NameDocument
        let myDocumentFromChildA:NameDocument = childContextA.object(with: myDocument.objectID) as! NameDocument
        let myDocumentFromChildB:NameDocument = childContextB.object(with: myDocument.objectID) as! NameDocument
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME ChildA \(myDocumentFromChildA.name!)")
        print("NAME ChildB \(myDocumentFromChildB.name!)")
        print("Setting NAME=JO using Parent")
        myDocumentFromParent.name = "JO"
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME ChildA \(myDocumentFromChildA.name!)")
        print("NAME ChildB \(myDocumentFromChildB.name!)")
        print("Saving")
        do {
            try namePersistentContainer.viewContext.save()
        } catch let error as NSError {
            print("Error on DB. \(error), \(error.userInfo)")
        }
        print("Sync NAME Parent \(myDocumentFromParent.name!)")
        print("Sync NAME ChildA \(myDocumentFromChildA.name!)")
        print("Sync NAME ChildB \(myDocumentFromChildB.name!)")
        XCTAssertEqual(myDocumentFromChildA.name, "TEST")
        XCTAssertEqual(myDocumentFromChildB.name, "TEST")
        DispatchQueue.main.async {
            print("Async NAME Parent \(myDocumentFromParent.name!)")
            print("Async NAME ChildA \(myDocumentFromChildA.name!)")
            print("Async NAME ChildB \(myDocumentFromChildB.name!)")
            XCTAssertEqual(myDocumentFromChildA.name, "JO")
            XCTAssertEqual(myDocumentFromChildB.name, "JO")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }

    /**
     this fails:
     - parent gets updated but sibling doesnt
     
     From: https://developer.apple.com/videos/play/wwdc2016/242/
     "Speaking of common context work flows, the NSManagedObjectContext has a new property this year called automatically merges changes from parent.
     It's a Boolean and when you set it to true the context will automatically merge, save the change the data of its parent.
     it works for child context when the parent saves its changes, and it also works for top level context when a sibling saves up to the store.
     It works especially well with generation tokens which Melissa talked about earlier."
     */
    func testSiblingPropagation() {
        let expectation = self.expectation(description: #function)
        
        let myDocument = NameDocument(context: namePersistentContainer.viewContext)
        myDocument.name = "TEST"
        namePersistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        let childContextA = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContextA.parent = namePersistentContainer.viewContext
        childContextA.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContextA.automaticallyMergesChangesFromParent = true

        let childContextB = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        childContextB.parent = namePersistentContainer.viewContext
        childContextB.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        childContextB.automaticallyMergesChangesFromParent = true

    
        let myDocumentFromParent:NameDocument = namePersistentContainer.viewContext.object(with: myDocument.objectID) as! NameDocument
        let myDocumentFromChildA:NameDocument = childContextA.object(with: myDocument.objectID) as! NameDocument
        let myDocumentFromChildB:NameDocument = childContextB.object(with: myDocument.objectID) as! NameDocument
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME ChildA \(myDocumentFromChildA.name!)")
        print("NAME ChildB \(myDocumentFromChildB.name!)")
        print("Setting NAME=JO using ChildA")
        myDocumentFromChildA.name = "JO"
        print("NAME Parent \(myDocumentFromParent.name!)")
        print("NAME ChildA \(myDocumentFromChildA.name!)")
        print("NAME ChildB \(myDocumentFromChildB.name!)")
        print("Saving")
        do {
            try childContextA.save()
        } catch let error as NSError {
            print("Error on DB. \(error), \(error.userInfo)")
        }
        print("Sync NAME Parent \(myDocumentFromParent.name!)")
        print("Sync NAME ChildA \(myDocumentFromChildA.name!)")
        print("Sync NAME ChildB \(myDocumentFromChildB.name!)")
        XCTAssertEqual(myDocumentFromParent.name, "JO")
        XCTAssertEqual(myDocumentFromChildA.name, "JO")
        XCTAssertEqual(myDocumentFromChildB.name, "TEST")
        DispatchQueue.main.async {
            print("Async NAME Parent \(myDocumentFromParent.name!)")
            print("Async NAME ChildA \(myDocumentFromChildA.name!)")
            print("Async NAME ChildB \(myDocumentFromChildB.name!)")
            XCTAssertEqual(myDocumentFromParent.name, "JO")
            XCTAssertEqual(myDocumentFromChildA.name, "JO")
            XCTAssertEqual(myDocumentFromChildB.name, "JO")
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1)
    }
}


//TODO: next test if there is a propagation to the siblings
// what are the other ways to create child context
