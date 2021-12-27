#  ADL


## How to identify remote changes?
A: Transaction History

there is a way to track changes introduced by cloudkit core data
https://developer.apple.com/videos/play/wwdc2017/210/?time=715
transaction history

PS: you can subscribe to notifications and consume from other contexts


## Op Log format
A: ProtoBuf 

we need to leave as fields things that we query on, but otherwise it's a blob
Apple Notes picked protobuf

Python benchmarks point to msgpack
https://medium.com/@shmulikamar/python-serialization-benchmarks-8e5bb700530b

SwiftPack for msgpack is barely supported - last update in 2015

Swift benchmarks:
https://github.com/mczachurski/SwiftBenchmarkJSON -> protobuf
https://itnext.io/swift-json-performance-ce9438632b02 -> protobuf


## Op Log structure
A: Combine multiple related operations together into a bigger envelope

We call it a forrest of trees, where each tree is independent, but easy to merge (e.g. linked list of characters comes as an ordered array)
This approach means we can compress a lot.


## where to store the max seen lamport
A: attribute in oplog and get last on ordered

a) in KV store, but then on every operation, on every msg received we need to update it
b) expose it as attribute in oplog and get max - we only do it at the start as later we just update singleton
especially nice as we have a single oplog


## How to notify UI of related downstream operation

### option 1 - on every object creation create notification
- minus - very granular (batching will need to happen before firing notifications)
- minus - how to deal with crash on in flight notifications?
Process objects on the same serial queue you would be creating and saving them (fire async task so it lands after the save)

### option 2 - use .NSManagedObjectContextDidSave notification
- trouble - it's on every save so I need to filter out the remote sourced ones

### option 3 - use history tracking
- it will be reliable
We can trigger history check after every NSManagedObjectContextDidSave
We update historyToken only after finished processing (transaction
We use author/name to filter out upstream batches


## Should Pointer Array store NSManagedObjectIDs or CRObjectIDs?
A: For now we use CRObjectIDs - revise

So fetchnig object using NSManagedObjectID is about 10x faster then using CRObjectID but generating is the other way around

