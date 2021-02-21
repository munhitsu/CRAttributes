# CoOpAttributes

A description of this package.


## how to regenerate protobuf
protoc --swift_opt=Visibility=Public  --swift_out=. CoOpLogModel.proto




## Need
Document created using this library allows for clean cross device sync (CRDT) and allows to invite others to collaborate

Operation based CRDT



## Ideas

we just provide attributes
let's ensure that we have the future path of sharing over synced core-data


## CK plan

1st run sync

on app launch - ash for changes you don't have

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




## ADL


0.
there is a way to track changes introduced by cloudkit core data
https://developer.apple.com/videos/play/wwdc2017/210/?time=715
transaction history

PS: you can subscribe to notifications and consume from other contexts


1. referencing models
caveat sub model can not be coming from the xcode visual data model editor

2. Should cache be merged with attribute? - YES - for now
I didn't wan't so that sync could be separated out, but I implement sync myself so for now it means less boilerplate code. 
May change

E.g. I could store the cache in a dedicated key value store

3. Op Log format - ProtoBuf 
we need to leave as fields things that we query on, but otherwise it's a blob
Apple Notes picked protobuf

Python benchmarks point to msgpack
https://medium.com/@shmulikamar/python-serialization-benchmarks-8e5bb700530b

SwiftPack for msgpack is barely supported - last update in 2015

Swift benchmarks:
https://github.com/mczachurski/SwiftBenchmarkJSON -> protobuf
https://itnext.io/swift-json-performance-ce9438632b02 -> protobuf


4. When should the fields be updated - only when document is open
we replicate all operations but we update the cache only on document open an later keep it up to date

if document open is long e.g. 0.1s then we return cached version and shortly update


5. where to store the max seen lamport - attribute in oplog and get max
a) in KV store, but then on every operation, on every msg received we need to update it
b) expose it as attribute in oplog and get max - we only do it at the start as later we just update singleton


6. abstract out data layer or dive in - dive in
why? premature abstraction

6. abstract out transport layer or dive in - dive in
native cloudkit is the target architecture
cloudkit coredata sync can't provide:
- sharing
- prioritisation
- notify on specific changes

souce of truth for the data is on the device, not in the cloud

7. How to trigger updates on new remote objects 
subscribe to events?

received operation should not force pull attribute/document form the store

a) every field subscribing to it's only events? - how to do it so that only in memory fields are processing
b) only open document gets update - I need more code for the document


8. and on new internal objects



9.



## Missign cloudkit core data functionality

- sharing of object trees
- fine tuning sync of specific objects 1st
- exclusion of specific attributes



## milestones
- LWW string and int registers saveable
- sync over cloudkit
- SwiftUI demo app
- colaborative text edit field
- collaborative sharing


## TODO
- make all operations as children of Container



- (low) bug when running form commandline swift test "'NSInternalInconsistencyException', reason: 'Can't modify an immutable model.'"


## maybe 
// TODO (post): maybe replace peer ID with... nothing and use ophash as 3rd item to compare




## Done
- try model on top of a model so we can cross link





## HowTo add a local package to your application
https://forums.swift.org/t/how-to-add-local-swift-package-as-dependency/26457/7

- Drag the package folder which contains the Package.swift into your Xcode project
- Click the Plus button in the "Link Binary with Libraries" section, locate the package in the modal dialog, select the gray library icon inside the package, and add this one.
