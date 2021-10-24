//
//  CDStringInsertOpProxy.swift
//  CRAttributes
//
//  Created by Mateusz Lapsa-Malawski on 21/09/2021.
//

import Foundation
import CoreData

/**
 a form to aid serialisaiton within NSMutableAttributedString
 */
class CDStringOpProxy: NSObject, NSCoding {
    
    var context:NSManagedObjectContext
    private var _objectURL:URL?
    private var _objectID:NSManagedObjectID?
    private var _object:CDStringOp? = nil

    // MARK: - computed properties

    var objectID:NSManagedObjectID {
        set {
            _objectID = newValue
        }
        get {
            if _objectID != nil {
                return _objectID!
            }
            if _object != nil {
                return _object!.objectID
            }
            return (context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: _objectURL!))!
        }
    }
    
    var object:CDStringOp {
        set {
            _object = newValue
        }
        get {
            if _object != nil {
                return _object!
            } else {
                if _objectID != nil {
                    return (context.object(with: _objectID!) as? CDStringOp)!
                } else {
                    _objectID = (context.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: _objectURL!))!
                    return (context.object(with: _objectID!) as? CDStringOp)!
                }
            }
        }
    }
    
    var objectURL:URL {
        set {
            _objectURL = newValue
        }
        get {
            if _objectURL != nil {
                return _objectURL!
            }
            return objectID.uriRepresentation()
        }
    }
    
    // MARK: - constructors
    
    init(context:NSManagedObjectContext) {
        self.context = context
    }

    convenience init(context:NSManagedObjectContext, object:NSManagedObjectID) {
        self.init(context: context)
        self.objectID = object
    }

    convenience init(context:NSManagedObjectContext, object:CDStringOp) {
        self.init(context: context)
        self.object = object
    }

    convenience init(context:NSManagedObjectContext, object:URL) {
        self.init(context: context)
        self.objectURL = object
    }

    // MARK: - NSCoding
    
    required convenience init?(coder: NSCoder) {
        self.init(context: CRStorageController.shared.localContainer.viewContext)

        context = CRStorageController.shared.localContainer.viewContext // TODO: I'm not too comfortable - too hardcoded and we will want to process AttributedString in a background task
        // but how else can I pass argument to a deserialisaiton form coder
        if let objectURL = coder.decodeObject(forKey: "objectURL") as? URL {
            self.objectURL = objectURL
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(self.objectURL, forKey: "objectURL")
    }
    
}

