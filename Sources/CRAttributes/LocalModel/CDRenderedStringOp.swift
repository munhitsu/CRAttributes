//
//  RenderedStringOp.swift
//  RenderedStringOp
//
//  Created by Mateusz Lapsa-Malawski on 26/08/2021.
//


import Foundation
import CoreData

@objc(CDRenderedStringOp)
public class CDRenderedStringOp: NSManagedObject {
}

extension CDRenderedStringOp {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDRenderedStringOp> {
        return NSFetchRequest<CDRenderedStringOp>(entityName: "CDRenderedStringOp")
    }
        
    @NSManaged public var lamport: Int64
    @NSManaged public var isSnapshot: Bool
    @NSManaged public var location: Int64
    @NSManaged public var length: Int64
    @NSManaged public var stringContributionRaw: Data?
    @NSManaged public var arrayContributionRaw: Data?
    // Future: if needing to add attributes then attributes are operations but for this form it might be ok to just make stingContribution into attributedString

    @NSManaged public var container: CDAttributeOp
}

extension CDRenderedStringOp : Identifiable {

}

extension CDRenderedStringOp {

    // this is slow to save so user needss to generate lamport synchronously before and run this async/in background
    convenience init(context: NSManagedObjectContext, containerOp: CDAttributeOp, lamport: Int64, stringSnapshot: String?, addressesSnapshot: [CRStringAddress]?) {
        print("stringSnapshot() - start")
        self.init(context:context)
        self.container = containerOp
        self.lamport = lamport
        self.isSnapshot = true
        self.length = 0
        self.location = 0
        assert((stringSnapshot == nil && addressesSnapshot == nil) || (stringSnapshot != nil && addressesSnapshot != nil))
        
        if stringSnapshot != nil {
            self.stringContributionRaw = try? NSKeyedArchiver.archivedData(withRootObject: stringSnapshot!, requiringSecureCoding: false)
            self.arrayContributionRaw =  try? NSKeyedArchiver.archivedData(withRootObject: addressesSnapshot!, requiringSecureCoding: false)
        }
        print("stringSnapshot() - end")
    }
    
    convenience init(context: NSManagedObjectContext, containerOp: CDAttributeOp, in range: NSRange, operationString: String?, operationAddresses: [CRStringAddress]?) {
        print("stringOperation() - start")
        self.init(context:context)
        self.container = containerOp
        self.lamport = getLamport()
        self.isSnapshot = false
        self.length = Int64(range.length)
        self.location = Int64(range.location)
        assert((operationString == nil && operationAddresses == nil) || (operationString != nil && operationAddresses != nil))
        if operationString != nil {
            self.stringContributionRaw = try? NSKeyedArchiver.archivedData(withRootObject: operationString!, requiringSecureCoding: false)
            self.arrayContributionRaw = try? NSKeyedArchiver.archivedData(withRootObject: operationAddresses!, requiringSecureCoding: false)
        }
        print("stringOperation() - end")
    }

    func getStringContribution() -> String {
        return (try? (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self.stringContributionRaw!) as? String)!) ?? ""
    }
    func getArrayContribution() -> [CRStringAddress] {
        return (try? (NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(self.arrayContributionRaw!) as? [CRStringAddress])!) ?? []
    }
}


extension CDRenderedStringOp {
    static func stringBundleFor(context: NSManagedObjectContext, container: CDAttributeOp) -> (String, [CRStringAddress]) {
        print("stringBundleFor() - start")
        // get latest snapshot
        let requestSnapshot: NSFetchRequest<CDRenderedStringOp> = CDRenderedStringOp.fetchRequest()
        requestSnapshot.predicate = NSPredicate(format: "container == %@ and isSnapshot == true", argumentArray: [container])
        requestSnapshot.sortDescriptors = [NSSortDescriptor(keyPath: \CDRenderedStringOp.lamport, ascending: false)]
        requestSnapshot.fetchLimit = 1
        requestSnapshot.returnsObjectsAsFaults = false
        
        let snapshots:[CDRenderedStringOp] = try! context.fetch(requestSnapshot)
        var string:String = snapshots.first?.getStringContribution() ?? ""
        var array:[CRStringAddress] = snapshots.first?.getArrayContribution() ?? []
        let lamport = snapshots.first?.lamport ?? 0
        print("lamport: \(lamport)")

        // get all operations newer then snapshot and execute them
        let requestOps: NSFetchRequest<CDRenderedStringOp> = CDRenderedStringOp.fetchRequest()
        requestOps.predicate = NSPredicate(format: "container == %@ and lamport > %@", argumentArray: [container, lamport])
        requestOps.sortDescriptors = [NSSortDescriptor(keyPath: \CDRenderedStringOp.lamport, ascending: true)]
        requestOps.returnsObjectsAsFaults = false
        
        let operations:[CDRenderedStringOp] = try! context.fetch(requestOps)
        print("operations: \(operations.count)")
                
        for op in operations {
            if op.isSnapshot == true {
                string = snapshots.first?.getStringContribution() ?? ""
            }
            let startStringIndex = string.index(string.startIndex, offsetBy: String.IndexDistance(op.location))
            let endStringIndex = string.index(startStringIndex, offsetBy: String.IndexDistance(op.length))
            string.replaceSubrange(startStringIndex...endStringIndex, with: op.getStringContribution())
            array.replaceSubrange(Int(op.location)...Int((op.location+op.length)), with: op.getArrayContribution())
        }
        print("stringBundleFor () - done")
        return (string, array)
    }
}
