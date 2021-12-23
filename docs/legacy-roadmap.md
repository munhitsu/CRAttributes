



### future roadmap
- split string from "A String-Wise CRDT for Group Editing" [2012]
- potentially undo support from "Supporting String-Wise Operations and Selective Undo for Peer-to-Peer Group Editing" [2014]

## Missign cloudkit core data functionality
- sharing of object trees between users (changed in 2021)
- exclusion of specific attributes from the sync (forces to have separate sync store)
- exclusion of specific objects from the sync (forces to have separate sync store)
- fine tuning cloudkit sync to prioritise specific objects
- easy hook for a code block on every remote object creation, object update, object delete

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

