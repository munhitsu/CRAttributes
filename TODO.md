# TODO


- [x] record local operations in serialised groups (Forests) for CloudKit sync
- [] compress OperationPacks
- [] process remote operations (downstream)
- [] attributedstring persistence (to speed up note opening)
- [] coursor for remote editors (as we have O(1) for local but O(n) for remote)
- [] I think I'm saving to often
- [x] cleanup package dependencies in the project
- [] check for memory leaks
- [] cope with eventuall ObjectID change
- [] optimise UUID comparision
- [] optimise UUID store and restore in protobuf
- [] instrument and optimise
- [] revert to storing peerID with every message in the protobuf / there might be edge cases when user moves between devices
- [] migrate upstream to the background queue / context


## ObjectID can change
- When you create a new object, but it has not yet been committed, its id will be temporary. You can check for this condition with isTemporaryId.
- When the backing store has been mutated, i.e. if you're using iCloud and you migrate to a new version of your database.

