


# initial implementation was RGA tree split with dumb op replicaiton and graph build on load
core data was just a mere log replication...
so load of note was taking notable time

also CoreData CK sync timing is unpredictible


# native CloudKit approach
well it's... cumbersome to implement and Apple is constantly improving their CoreData Sync

CoreData and CoreData CloudKit Sync are the official supported pattern


# started from character based RGA
where all ops are part of a replicated graph already
with an intention to introduce later node split

...but core data is a graph serialisation with cross device replication


# re-reading Yu 2014 - time to add coursor and linked list
we don't need to optimise for repeated numeric position to op search as it's only for the remote operations
position search is user driven, so cursor and linked list seems... optimal


# meeting with Nick - back to the drawing board
