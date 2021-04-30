#  ADL

13. we keep lamport and peerid for consistent ordering for all replicas

12. use core data references
but monitor fo updated objects as it's uknown what sync will do

11. drop transformation from core data to operation to node

10. I'm considering dropping protobuf as we only have one operation type to focus on
and coredata is your in memory database

9. pivot
make implementation compatible with the native coredata+cloudkit sync
focus on mutable string
lww is about the same as a native cloudkit merge resolution
cloudkit is for near real time, delay with native cloud kit can be 10s (see: https://developer.apple.com/forums/thread/131696) and that's ok

reintroduce container later

this approach means we are ready to introduce our own sync if needed but for now we have a solid foundation and Apple may introduce Sharing

--------------

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

