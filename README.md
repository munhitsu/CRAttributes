# CoOpAttributes

Enables colaboration on text field across multiple iOS devices.

It's based on operation based CRDT (RGA) with replication leveraging native graph synchronisation using CoreData CloudKit sync.
A nearly vanilla implementation of CRDT RGA (operation per character).


## research
Source:
- RGA Tree Split (w/o tree) from - Marc Shapiro at other - "High Responsiveness for Group Editing CRDTs" [2016]
- "CloudKit - Structured Storage for Mobile Applications" [2018]


## warning
This code is not produciton ready. Data structures and api may change


### future roadmap
- split string from "A String-Wise CRDT for Group Editing" [2012]
- potentially undo support from "Supporting String-Wise Operations and Selective Undo for Peer-to-Peer Group Editing" [2014]


## usage
See tests. 


## Goal
To describe text as an operation graph where adding operation does not modify exiting nodes (no foreign key updates, but leveraging reverse foreign key updates).
10K characters note needs to load with low latency - below 0.1s - within the requirements on M1

Source: https://www.nngroup.com/articles/response-times-3-important-limits/
"0.1 second is about the limit for having the user feel that the system is reacting instantaneously, meaning that no special feedback is necessary except to display the result."


## Missign cloudkit core data functionality
- sharing of object trees between users (changed in 2021)
- exclusion of specific attributes from the sync (forces to have separate sync store)
- exclusion of specific objects from the sync (forces to have separate sync store)
- fine tuning cloudkit sync to prioritise specific objects
- easy hook for a code block on every remote object creation, object update, object delete

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
- binary tree initialised on every note load - not really needed if we remember the current user cursor and have the linked list perspective - though it will optimise remote operations
- compare full binary tree with binary tree and list search for last 20 elements - not needed, see above


# Tasks
rebuilding protobuf model
```
cd Sources/CRAttributes/ReplicationModel
protoc --swift_out=. ProtoModel.proto
```
