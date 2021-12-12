# TODO



- [] restoreLinkedList vs linkedlist.restore - 2 implementations

- [] ensure that every self.state = .inDownstreamQueueMergedUnrendered - defines state
- [] merge deletes
- [] flatten CDOperations into one object so we can cahge the type on flight (e.g. have ghost Op whose type materialises when it arrives)
- [] ship string upstream op to the replication container
- [] 2 different delete operat type for strings.... and protobuf impact

- [] replication container versioning so we can detect remote changes
- [] merge downstream string op

- [] optimise insert creation on paste - use core data batch API 

- [] implement delete object/attribute

- [] remove recursion
- [x] on string upstream - update rendered form
- [x] update model to RGA
- [x] on string upstream - create insert unprocessed op - RGA - slow
- [x] on string upstream - create delete unprocessed op - RGA
- [x] process string upstream op into the RGA


## deprecated due to pivot to RGA

- [x] on string upstream - create delete unprocessed op - RGA Split
- [x] on string upstream - create insert unprocessed op - RGA Split



## old

- [] benchmark fetch using objectID vs fetch using OperationID -> write down results / benchmark as separate project maybe
- [] benchmark - compare flat object with inheritend one
- [] benchmark fetch on nsmanagedobjectID vs linked list
- [] ask apple how to optimise further fetching based on the primary key

- [x] add os.signpost to printTimeElapsedWhenRunningCode
- [] serialise and deserialise attributed string

- [x] record local operations in serialised groups (Forests) for CloudKit sync
- [-] introduce ghost operation
- [] process remote operations (downstream)
- [] compress OperationPacks
- [] coursor for remote editors (as we have O(1) for local but O(n) for remote)
- [] I think I'm saving to often
- [x] cleanup package dependencies in the project
- [] check for memory leaks
- [] cope with eventuall ObjectID change
- [] optimise UUID comparision
- [] optimise UUID store and restore in protobuf
- [] instrument and optimise
- [] revert to storing peerID with every message in the protobuf / there might be edge cases when user moves between devices
- [] migrate upstream amd downstream to the background queue / context
- [x] reverse relation of container makes String Operations slow - eg from 2s for 10K and 12s for 50K it jumps to 10s for 10K and 220s for 50K

- [] context in app vs in test - should we use singleton and with what defaults


## ObjectID can change
- When you create a new object, but it has not yet been committed, its id will be temporary. You can check for this condition with isTemporaryId.
- When the backing store has been mutated, i.e. if you're using iCloud and you migrate to a new version of your database.

