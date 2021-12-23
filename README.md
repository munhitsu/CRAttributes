# CoOpAttributes

Enables colaboration on text field across multiple iOS devices.

It's based on operation based CRDT with replication leveraging native CoreData CloudKit sync.
A nearly vanilla implementation of CRDT RGA (operation per character).


## research
Source:
- RGA Tree Split (w/o tree) from - Marc Shapiro at other - "High Responsiveness for Group Editing CRDTs" [2016]
- "CloudKit - Structured Storage for Mobile Applications" [2018]


## warning
This code is not produciton ready. Data structures and api may change


## usage
You need to build your model using CR primitives. See tests.


## Goal
To describe text as an operation graph where adding operation does not modify exiting nodes (no foreign key updates, but leveraging reverse foreign key updates).
10K characters note needs to load with low latency - below 0.1s (tested on M1)

Source: https://www.nngroup.com/articles/response-times-3-important-limits/
"0.1 second is about the limit for having the user feel that the system is reacting instantaneously, meaning that no special feedback is necessary except to display the result."


# Tasks
rebuilding protobuf model
```
cd Sources/CRAttributes/ReplicationModel
protoc --swift_out=. ProtoModel.proto
```
