# TODO


- [] record local operations in serialised groups (OperationPack) for CloudKit sync
- [] compress OperationPacks
- [] process remote operations (downstream)
- [] attributedstring persistence (to speed up note opening)
- [] coursor for remote editors (as we have O(1) for local but O(n) for remote)
- [] I think I'm saving to often
- [] cleanup package dependencies in the project


- [] check for memory leaks


- [] cope with eventuall ObjectID change




## ObjectID can change
- When you create a new object, but it has not yet been committed, its id will be temporary. You can check for this condition with isTemporaryId.
- When the backing store has been mutated, i.e. if you're using iCloud and you migrate to a new version of your database.

