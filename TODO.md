# TODO


- [] update UI on remote changes
- [] replication container versioning so we can detect remote changes

- [] optimise insert creation on paste - use core data batch API 
- [] implement delete object/attribute
- [] remove recursion (where?)
- [] fix performance of testLoadingPerformanceSinglePaste (5xlorem used to work)


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


