//
//  CRModel.swift
//  CRModel
//
//  Created by Mateusz Lapsa-Malawski on 15/08/2021.
//

import Foundation
import CoreDataModelDescription
import CoreData


// use case
// list of all top level folders
// list of all folders and notes within a folder
// list of all attributes within a note




let localModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "CDAbstractOp",
                managedObjectClass: CDAbstractOp.self,
                isAbstract: true,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .UUIDAttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType),
                    .attribute(name: "upstreamQueueOperation", type: .booleanAttributeType, defaultValue: true), //TODO: remove default as it's implicit
                    //TODO: replace with rawSatus from stringOp
                ],
//                fetchedProperties: [
//                    .fetchedProperty(name: "containedOps", fetchRequest: CDAbstractOp.containedOperationsFetchRequest())
//                ],
                relationships: [
                    .relationship(name: "container", destination: "CDAbstractOp", optional: true, toMany: false),
//                    .relationship(name: "containedOperations", destination: "CDAbstractOp", optional: true, toMany: true, inverse: "container"), //TODO: remove as maintaining this reverse link is expensive - it's only used for serialisation and deserialisation
                ],
                indexes: [
                    .index(name: "lamport", elements: [.property(name: "lamport")]),
                    .index(name: "lamportPeerID", elements: [.property(name: "lamport"),.property(name: "peerID")])
                ],
                constraints: ["lamport", "peerID"]
               ),
        // object parent is an object it is nested within
        // null parent means it's a top level object
        // if you are a folder then set yourself a CDAttributeOp "name"
        // subOperations will be either sub attributes or sub objects
            .entity(name: "CDObjectOp",
                    managedObjectClass: CDObjectOp.self,
                    parentEntity: "CDAbstractOp",
                    attributes: [
                        .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                    ]
                   ),
        // attribute parent is an object attribute is nested within
        .entity(name: "CDAttributeOp",
                managedObjectClass: CDAttributeOp.self,
                parentEntity: "CDAbstractOp",
                attributes: [
                    .attribute(name: "name", type: .stringAttributeType, defaultValue: "default"),
                    .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                ]
//                ,
//                relationships: [
//                    .relationship(name: "renderedStringOperations", destination: "CDRenderedStringOp", optional: true, toMany: true, inverse: "container")
//                ]
               ),
        .entity(name: "CDLWWOp",
                managedObjectClass: CDLWWOp.self,
                parentEntity: "CDAbstractOp",
                attributes: [
                    .attribute(name: "int", type: .integer64AttributeType, isOptional: true),
                    .attribute(name: "float", type: .floatAttributeType, isOptional: true),
                    .attribute(name: "date", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "boolean", type: .booleanAttributeType, isOptional: true),
                    .attribute(name: "string", type: .stringAttributeType, isOptional: true)
                ]
               ),
        // container is what was deleted
        .entity(name: "CDDeleteOp",
                managedObjectClass: CDDeleteOp.self,
                parentEntity: "CDAbstractOp"
               ),
        .entity(name: "CDStringOp",
                managedObjectClass: CDStringOp.self,
                parentEntity: "CDAbstractOp",
                attributes: [
                    .attribute(name: "parentLamport", type: .integer64AttributeType),
                    .attribute(name: "parentPeerID", type: .UUIDAttributeType),
                    .attribute(name: "insertContribution", type: .integer32AttributeType, isOptional: true),
                    .attribute(name: "rawState", type: .integer32AttributeType, defaultValue: 0), // default: unknown
                    .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: 0), // default: insert
                ],
                relationships: [
                    .relationship(name: "parent", destination: "CDStringOp", optional: true, toMany: false, inverse: "childOperations"),  // insertion point
                    .relationship(name: "childOperations", destination: "CDStringOp", optional: true, toMany: true, inverse: "parent"),  // insertion point
                    .relationship(name: "next", destination: "CDStringOp", toMany: false, inverse: "prev"),
                    .relationship(name: "prev", destination: "CDStringOp", toMany: false, inverse: "next"),
                ]
               ),
        .entity(name: "CDRenderedStringOp",
                managedObjectClass: CDRenderedStringOp.self,
                attributes: [
                    .attribute(name: "lamport", type: .integer64AttributeType, isOptional: false),  // newly generated lamport for this operation
                    .attribute(name: "isSnapshot", type: .booleanAttributeType, isOptional: false, defaultValue: false),
                    .attribute(name: "location", type: .integer64AttributeType, defaultValue: 0), // replacement point
                    .attribute(name: "length", type: .integer64AttributeType, defaultValue: 0),   // replaced characters
                    .attribute(name: "stringContributionRaw", type: .binaryDataAttributeType, isOptional: true, defaultValue: nil), // data consolidated from all operations will contain references to operations
                    .attribute(name: "arrayContributionRaw", type: .binaryDataAttributeType, isOptional: true,  defaultValue: nil), // data consolidated from all operations will contain references to operations
                    // pure delete may store nil here
                ],
                relationships: [
                    .relationship(name: "container", destination: "CDAttributeOp", optional: false, toMany: false)
                ],
                indexes: [
                    .index(name: "lamport", elements: [
                        .property(name: "container"),
                        .property(name: "lamport")
                    ]),
                    .index(name: "lamport_desc", elements: [
                        .property(name: "container"),
                        .property(name: "lamport", type: .binary, ascending: false)
                    ]),
                    .index(name: "isSnapshot", elements: [
                        .property(name: "container"),
                        .property(name: "isSnapshot")
                    ]),
                ]
//                ,
//                constraints: ["lamport"]
               ),    ]
)
public let CRLocalModel = localModelDescription.makeModel()


