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
        // object parent is an object it is nested within
        // null parent means it's a top level object
        // if you are a folder then set yourself a CDAttributeOp "name"
        // subOperations will be either sub attributes or sub objects
        // attribute container is an object attribute is nested within
        .entity(name: "CDOperation",
                managedObjectClass: CDOperation.self,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .UUIDAttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType, defaultValue: false),
                    .attribute(name: "rawState", type: .integer32AttributeType), // default: unknown
                    .attribute(name: "rawType", type: .integer32AttributeType),

                    .attribute(name: "rawObjectType", type: .integer32AttributeType, defaultValue: Int32(0)),

                    .attribute(name: "attributeName", type: .stringAttributeType, isOptional: true),
                    .attribute(name: "rawAttributeType", type: .integer32AttributeType, defaultValue: Int32(0)),

                    .attribute(name: "lwwInt", type: .integer64AttributeType, defaultValue: 0),
                    .attribute(name: "lwwFloat", type: .floatAttributeType, defaultValue: 0),
                    .attribute(name: "lwwDate", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "lwwBool", type: .booleanAttributeType, defaultValue: false),
                    .attribute(name: "lwwString", type: .stringAttributeType, isOptional: true),

                    .attribute(name: "parentLamport", type: .integer64AttributeType, defaultValue: 0), // string, delete
                    .attribute(name: "parentPeerID", type: .UUIDAttributeType, defaultValue: UUID.zero), // string, delete
                    .attribute(name: "stringInsertContribution", type: .integer32AttributeType, isOptional: true),
                ],
                relationships: [
                    .relationship(name: "container", destination: "CDOperation", optional: true, toMany: false),
                    //                    .relationship(name: "containedOperations", destination: "CDAbstractOp", optional: true, toMany: true, inverse: "container"), - removed as maintaining this reverse link is expensive - it's only used for serialisation and deserialisation
                    .relationship(name: "parent", destination: "CDOperation", optional: true, toMany: false, inverse: "childOperations"),  // insertion point
                    .relationship(name: "childOperations", destination: "CDOperation", optional: true, toMany: true, inverse: "parent"),  // insertion point
                    .relationship(name: "next", destination: "CDOperation", toMany: false, inverse: "prev"),
                    .relationship(name: "prev", destination: "CDOperation", toMany: false, inverse: "next"),
                ],
                indexes: [
                    .index(name: "lamport", elements: [.property(name: "lamport")]),
                    .index(name: "lamportPeerID", elements: [.property(name: "lamport"),.property(name: "peerID")])
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
                    //                constraints: ["lamport", "peerID", "container"]
                ]
               ),
    ]
)
public let CRLocalModel = localModelDescription.makeModel()


