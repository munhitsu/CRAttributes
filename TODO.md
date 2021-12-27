# TODO


- [] update rendered string for the opened container(attribute/object) (CRAttribute should subscribe to changes where it is a container)
- [] update rendered string optimisations
- [] background fast update of all not yet opened MutableStrings - O(n) as it's a linked list to string
- [] instant MutableStrings open and async update with the new unrendered changes (animated?)
- [] update UI on the remote changes
- [] background slow update of all MutableStrings (if still needed)

- [] optimise insert creation on paste - use core data batch API 
- [] implement delete object/attribute
- [] remove recursion (where?)
- [] fix performance of testLoadingPerformanceSinglePaste (5 x lorem used to work)
- [] migrate deprecated "withUnsafeBytes { (pointer: UnsafePointer"
- [] performance test and solution for big paste

- [x] track replication container history so we can detect and process remote changes (NSPersistentHistoryTrackingKey)
- [x] ensure we can receive duplicates of downstream operations
- [x] restoreLinkedList vs linkedlist.restore - 2 implementations
- [x] flatten CDOperations into one object so we can cahge the type on flight (e.g. have ghost Op whose type materialises when it arrives)
- [x] ship string upstream op to the replication container
- [x] merge downstream string op
- [x] 2 different delete operation types for strings.... and protobuf impact - merged
- [x] on string upstream - update rendered form
- [x] update model to RGA
- [x] on string upstream - create insert unprocessed op - RGA - slow
- [x] on string upstream - create delete unprocessed op - RGA
- [x] process string upstream op into the RGA


## later (optimisations)
- [] compress oplog
- [] maybe - Should Pointer Array store NSManagedObjectIDs or CRObjectIDs - try NSManagedObjectIDs again
- [] Locally compress PeerID from UUID to int, but ensure that it sorts on all platforms the same.
- [] try batch operations on paste

## evaluations
- [] evaluate obtainPermanentIDs - to return linked objects from the UI
- [] evaluate linking in UI (very likely it's a no as big paste will be slow)
- [] evaluate moving all UI writes to background


