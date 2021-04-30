# CoOpAttributes



## usage

you need to save context when you decide to - we just don't do it


## Goal/challenge
is it possible to to describe text as an operation graph where adding operation does not modify exiting nodes (no reference updates)

10K characters note needs to me low latency



## Need
Document created using this library allows for clean cross device sync (CRDT) and allows to invite others to collaborate

Operation based CRDT



## Ideas

we just provide attributes
let's ensure that we have the future path of sharing over synced core-data


## Milestones
- mutable string model field (https://developer.apple.com/documentation/uikit/nstextstorage)
- SwiftUI demo app
- mutable attributed string model field
- cached rendered string (hash applied operation ids) (store op local id and true false)
- optimise the structure with split and attached search tree (manually balanced once in a while)




## future potential optimisations
- var string: String - make our own String subclass and implement subscript and/or other used methods
- remember location per each peerID (At least for the current) and search location from the last location
- implement iterator for the above
- binary tree initialised on every note load
- compare full binary tree with binary tree and list search for last 20 elements
- preload all related objects on document open
- cache rendered string in anothed data store




## Missign cloudkit core data functionality

- sharing of object trees
- fine tuning sync of specific objects 1st
- exclusion of specific attributes

but sharing will come and at worse we can do sharing by hand



## CK plan

1st run sync

on app launch - ask for changes you don't have

register for notificaiton (notifications can be coalesced) 
on each notification... pull changes

enable push notifications
enable abckground changes
 
set parent for each operation to be attribute

fetch references - what are the errors?

register to network changes to sync the offline operations

register to CKAccountChange - as user may eb logged off 

batch operations to save bandwidth

qos user initiated - maybe




KVO with Combine
https://gist.github.com/hermanbanken/cf635644147abd0e330fb6deae758ce4
Performing Key-Value Observing with Combine https://developer.apple.com/documentation/combine/performing-key-value-observing-with-combine


How to make a singleton
https://developer.apple.com/documentation/swift/cocoa_design_patterns/managing_a_shared_resource_using_a_singleton



CoudKit allows for atomic commits (follows relations) in special zones

delta downlaod and recording change tokens


There is no cross zone linking








## HowTo add a local package to your application
https://forums.swift.org/t/how-to-add-local-swift-package-as-dependency/26457/7

- Drag the package folder which contains the Package.swift into your Xcode project
- Click the Plus button in the "Link Binary with Libraries" section, locate the package in the modal dialog, select the gray library icon inside the package, and add this one.



## Readings
Advanced CloudKit
https://www.youtube.com/watch?v=8iHfrqvF5po
