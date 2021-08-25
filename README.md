# CoOpAttributes

Enables colaboration on text field across multiple iOS devices.

It's based on operation based CRDT (RGA) with replication leveraging native graph synchronisation using CoreData CloudKit sync.

## research
Merging:
- Weihai Yu Linked List with cursor approach from "A String-Wise CRDT for Group Editing" [2012] and "Supporting String-Wise Operations and Selective Undo for Peer-to-Peer Group Editing" 2014
- RGA Tree Split (w/o tree) from - Marc Shapiro at other - "High Responsiveness for Group Editing CRDTs" [2016]
- "CloudKit - Structured Storage for Mobile Applications" [2018]


## warning
This code is not produciton ready. Data structures and api may change as we are polishing the solution.


### future roadmap
- split string from "A String-Wise CRDT for Group Editing" [2012]
- potentially undo support from "Supporting String-Wise Operations and Selective Undo for Peer-to-Peer Group Editing" [2014]


## usage
Build your data model on top of the CoOpAttributes one. We found CoreDataModelDescription framework the missing piece to enable usable programatic declaration of CoreData Model.
See ModelTests.swift for an example.

Plese note that you decide when changes are commited - you perform core data save.


## Goal
To describe text as an operation graph where adding operation does not modify exiting nodes (no foreign key updates, but leveraging reverse foreign key updates).
10K characters note needs to load with low latency - below 0.1s - within the requirements on M1

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
- binary tree initialised on every note load - not really needed if we remember the current user cursor and have the linked list perspective - though it will optimise remote operations
- compare full binary tree with binary tree and list search for last 20 elements - not needed, see above


## HowTo add a local package to your application
https://forums.swift.org/t/how-to-add-local-swift-package-as-dependency/26457/7

- Drag the package folder which contains the Package.swift into your Xcode project
- Click the Plus button in the "Link Binary with Libraries" section, locate the package in the modal dialog, select the gray library icon inside the package, and add this one.


## benchmarking
benchmarking first string building

### lorem impsum walking
tested on MBP M1
lorem 5 paragraphs - approx 5K characters
avg 0.288 - with faults
avg 0.165 - after introducing prefetching
avg 0.047 - after replacing recursion tree walk with a loop (1st run is 0.078)


10K ops testWalkingListBenchmark
avg 0.080 - after replacing recursion tree walk with a loop (1st run is 0.118)



## 10K -  using xcode 13.0 betas:
Time elapsed for saving operations: 8.156451940536499 s.
Version 13.0 beta 1
average: 0.004, relative standard deviation: 30.181%, values: [0.005170, 0.005433, 0.006467, 0.005196, 0.003543, 0.002320, 0.002265, 0.003901, 0.004191, 0.003972]

Version 13.0 beta 4 (13A5201i):
average: 0.008, relative standard deviation: 30.413%, values: [0.012892, 0.010469, 0.009059, 0.008257, 0.007364, 0.006581, 0.006141, 0.005799, 0.005536, 0.005177]

## 50K ops from testWalkingListBenchmark:
Time elapsed for saving operations: 201.65687596797943 s.
average: 0.027, relative standard deviation: 34.418%, values: [0.053208, 0.030514, 0.024415, 0.022593, 0.022593, 0.022532, 0.022595, 0.022581, 0.022704, 0.022588]

## opening 50K ops from testPerformance:
Time elapsed for creating operations: 184.44972002506256 s.
Time elapsed for saving operations: 146.00910997390747 s.
average: 0.022, relative standard deviation: 37.334%, values: [0.044644, 0.027610, 0.021237, 0.018515, 0.017842, 0.017754, 0.017686, 0.017655, 0.017596, 0.017944]


## migrated to AttributedString

## opening 50K ops from testLoadingPerformanceUpstreamOperations
1. Time to convert upstream operations into the string:
Time elapsed for CRTextStorage: 11.415868997573853 s.

2. Time to rebuild the string from the saved from:
average: 0.073, relative standard deviation: 10.412%, values: [0.094805, 0.073712, 0.070798, 0.069835, 0.069900, 0.068491, 0.069923, 0.068632, 0.069312, 0.069902]


## opening 50K
Result of doing everything in the main context - let's call it a baseline
But why is loading slower then?

1. Time to convert upstream operations into the string:
Time elapsed for CRTextStorage: 24.234724044799805 s.

2. Time to rebuild the string from the saved from:
average: 0.230, relative standard deviation: 1.900%, values: [0.236713, 0.232893, 0.229278, 0.227163, 0.232548, 0.227663, 0.232114, 0.227976, 0.234746, 0.220696]


# Tasks
rebuilding model
```
cd Sources/CRAttributes/ReplicatedModel
protoc --swift_out=. ProtoModel.proto
```
