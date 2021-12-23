//
//  CDModel.swift
//  CDModel
//
//  Created by Mateusz Lapsa-Malawski on 16/08/2021.
//

import Foundation
import CoreDataModelDescription

let replicationModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "CDOperationsForest",
                managedObjectClass: CDOperationsForest.self,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "lamport", type: .integer64AttributeType, defaultValue: 0),
                    .attribute(name: "peerID", type: .UUIDAttributeType, defaultValue: localPeerID),
                    .attribute(name: "data", type: .binaryDataAttributeType),
                ]
               )
    ]
)

public let CRReplicationModel = replicationModelDescription.makeModel()
