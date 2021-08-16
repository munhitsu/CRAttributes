//
//  CDModel.swift
//  CDModel
//
//  Created by Mateusz Lapsa-Malawski on 16/08/2021.
//

import Foundation
import CoreDataModelDescription

let replicatedModelDescription = CoreDataModelDescription(
    entities: [
        .entity(name: "CDOperationsForest",
                managedObjectClass: CDOperationsForest.self,
                attributes: [
                    .attribute(name: "version", type: .integer32AttributeType, defaultValue: Int32(0)),
                    .attribute(name: "peerID", type: .UUIDAttributeType, defaultValue: localPeerID),
                    .attribute(name: "data", type: .binaryDataAttributeType),
                ]
               )
    ]
)

public let CRReplicatedModel = replicatedModelDescription.makeModel()
