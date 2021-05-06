# CoOpAttributes

Enables colaboration on text field across multiple iOS devices.

It's based on operation based CRDT (RGA) with replication leveraging native graph synchronisation using CoreData CloudKit sync.

## research
Merging:
- Weihai Yu Linked List with cursor approach from "A String-Wise CRDT for Group Editing" [2012]
- RGA Tree Split (w/o tree) from "High Responsiveness for Group Editing CRDTs" [2016]
- "CloudKit - Structured Storage for Mobile Applications" [2018]

### future roadmap
- split string from "A String-Wise CRDT for Group Editing" [2012]
- potentially undo support from "Supporting String-Wise Operations and Selective Undo for Peer-to-Peer Group Editing" [2014]


## usage
Build your data model on top of the CoOpAttributes one. We found CoreDataModelDescription framework the missing piece to enable usable programatic declaration of CoreData Model.
See ModelTests.swift for an example.

Plese note that you decide when changes are commited - you perform core data save.


## Goal
To describe text as an operation graph where adding operation does not modify exiting nodes (no foreign key updates, but leveraging reverse foreign key updates).
10K characters note needs to load with low latency - below 0.1s

Source: https://www.nngroup.com/articles/response-times-3-important-limits/
"0.1 second is about the limit for having the user feel that the system is reacting instantaneously, meaning that no special feedback is necessary except to display the result."


## Missign cloudkit core data functionality
- sharing of object trees between users
- exclusion of specific attributes from the sync
- exclusion of specific objects from the sync
- fine tuning cloudkit sync to prioritise specific objects
- easy hook for a code block on every remote object creation, object update, object delete

Note: sharing will eventually come and meanwhile at worse we can do sharing by hand


## Milestones
- mutable string model field (https://developer.apple.com/documentation/uikit/nstextstorage)
- SwiftUI demo app
- mutable attributed string model field
- migrate 1st string rendering from recursion to the loop

### future milestone
- enable cloudkit sync and process remote updates
- cached rendered string (hash applied operation ids) (store op local id and true false) / or prerender only what is being displayed
- optimise the structure with split and attached search tree (manually balanced once in a while)


## future potential optimisations
- var string: String - make our own String subclass and implement subscript and/or other used methods (1st note load should not need he whole note)
- cache rendered string in anothed data store - warning, remote operations may have arrived

- remember location for the user - done
- preload all related objects on document open - done

### not sure anymore
- implement iterator for the above - not really needed after introducing linked list perspective
- binary tree initialised on every note load - not really needed if we remember the current user cursor and have the linked list perspective
- compare full binary tree with binary tree and list search for last 20 elements - not needed, see above


## HowTo add a local package to your application
https://forums.swift.org/t/how-to-add-local-swift-package-as-dependency/26457/7

- Drag the package folder which contains the Package.swift into your Xcode project
- Click the Plus button in the "Link Binary with Libraries" section, locate the package in the modal dialog, select the gray library icon inside the package, and add this one.


## benchmarking
benchmarking first string building

### lorem impsum walking
avg 0.288 - with faults
avg 0.165 - after introducing prefetching
avg 0.047 - after replacing recursion with a loop (1st run is 0.078)
