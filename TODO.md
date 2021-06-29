# TODO

- [x] implement cursor
 - [x] view triggered selection update
 - [x] text replace views selection update
- [x] bug: tree walk is execuded one each edit (was debug)
- [x] bug: it's faulting on every operation on inserts and deletes
- [x] remove recursion
- [] ensure that cache update combined with linked list update is atomic (https://www.avanderlee.com/swift/concurrent-serial-dispatchqueue/)
- [] speed up long note load
- [] check for memory leaks
[] process externall operations (re-link, update cursor, re-render)






## legacy
- make all operations as children of Container



- (low) bug when running form commandline swift test "'NSInternalInconsistencyException', reason: 'Can't modify an immutable model.'"


## maybe
// TODO (post): maybe replace peer ID with... nothing and use ophash as 3rd item to compare




## Done
- try model on top of a model so we can cross link
