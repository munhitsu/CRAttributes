//
//  CRModel.swift
//  CRModel
//
//  Created by Mateusz Lapsa-Malawski on 15/08/2021.
//

import Foundation
import CoreDataModelDescription


// use case
// list of all top level folders
// list of all folders and notes within a folder
// list of all attributes within a note

let localModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "CRAbstractOp",
                managedObjectClass: CRAbstractOp.self,
                isAbstract: true,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "lamport", type: .integer64AttributeType),
                    .attribute(name: "peerID", type: .UUIDAttributeType),
                    .attribute(name: "containerLamport", type: .integer64AttributeType),
                    .attribute(name: "containerPeerID", type: .UUIDAttributeType),
                    .attribute(name: "hasTombstone", type: .booleanAttributeType),
                    .attribute(name: "upstreamQueueOperation", type: .booleanAttributeType, defaultValue: true), //TODO: remove default as it's implicit
                    .attribute(name: "waitingForContainer", type: .booleanAttributeType, defaultValue: false)
                ],
                relationships: [
                    .relationship(name: "container", destination: "CRAbstractOp", optional: true, toMany: false),  // insertion point
                    .relationship(name: "containedOperations", destination: "CRAbstractOp", optional: true, toMany: true, inverse: "container"),  // insertion point
                ],
                indexes: [
                    .index(name: "lamport", elements: [.property(name: "lamport")]),
                    .index(name: "lamportPeerID", elements: [.property(name: "lamport"),.property(name: "peerID")])
                ],
                constraints: ["lamport", "peerID"]
               ),
        // object parent is an object it is nested within
        // null parent means it's a top level object
        // if you are a folder then set yourself a CRAttributeOp "name"
        // subOperations will be either sub attributes or sub objects
            .entity(name: "CRObjectOp",
                    managedObjectClass: CRObjectOp.self,
                    parentEntity: "CRAbstractOp",
                    attributes: [
                        .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                    ]
                   ),
        // attribute parent is an object attribute is nested within
        .entity(name: "CRAttributeOp",
                managedObjectClass: CRAttributeOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "name", type: .stringAttributeType, defaultValue: "default"),
                    .attribute(name: "rawType", type: .integer32AttributeType, defaultValue: Int32(0))
                ]
               ),
        .entity(name: "CRLWWOp",
                managedObjectClass: CRLWWOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "int", type: .integer64AttributeType, isOptional: true),
                    .attribute(name: "float", type: .floatAttributeType, isOptional: true),
                    .attribute(name: "date", type: .dateAttributeType, isOptional: true),
                    .attribute(name: "boolean", type: .booleanAttributeType, isOptional: true),
                    .attribute(name: "string", type: .stringAttributeType, isOptional: true)
                ]
               ),
        // parent is what was deleted
        .entity(name: "CRDeleteOp",
                managedObjectClass: CRDeleteOp.self,
                parentEntity: "CRAbstractOp"
               ),
        .entity(name: "RenderedString",
                managedObjectClass: RenderedString.self,
                attributes: [
                    .attribute(name: "string", type: .binaryDataAttributeType)
                ]
               ),
        .entity(name: "CRStringInsertOp",
                managedObjectClass: CRStringInsertOp.self,
                parentEntity: "CRAbstractOp",
                attributes: [
                    .attribute(name: "contribution", type: .stringAttributeType),
                    .attribute(name: "parentLamport", type: .integer64AttributeType),
                    .attribute(name: "parentPeerID", type: .UUIDAttributeType),
                    .attribute(name: "waitingForParent", type: .booleanAttributeType, defaultValue: false)
                ],
                relationships: [
                    .relationship(name: "parent", destination: "CRStringInsertOp", optional: true, toMany: false, inverse: "childOperations"),  // insertion point
                    .relationship(name: "childOperations", destination: "CRStringInsertOp", optional: true, toMany: true, inverse: "parent"),  // insertion point
                    .relationship(name: "next", destination: "CRStringInsertOp", toMany: false, inverse: "prev"),
                    .relationship(name: "prev", destination: "CRStringInsertOp", toMany: false, inverse: "next"),
                ]
               )
    ]
)
public let CRLocalModel = localModelDescription.makeModel()


