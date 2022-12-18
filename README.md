# CRAttributes

Enables colaboration on text field (and other fields) across multiple iOS devices.

It's based on operation based CRDT with replication leveraging native CoreData CloudKit sync.
A nearly vanilla implementation of CRDT RGA (operation per character).

## demo app
https://github.com/munhitsu/CRAttributesDemo

## project status
Work in progress (WIP) / Request for comments (RFC)


## milestones/roadmap
- [x] serialisation and deserialisation of basic attributes using LWW and Mutable String using RGA
- [x] replication primitives
- [x] live merging of remote changes
  - [x] LWW
  - [x] MutableString Insert
  - [x] MutableString Delete
- [x] demo app (CRAttributesDemo)
- [ ] enable user to reference character?
- [ ] sharing (native)
- [ ] Foreign key
- [ ] ORM?
- [ ] optimisations - never ending


## research
Source:
- RGA Tree Split (w/o tree, w/o split) from - Marc Shapiro at other - "High Responsiveness for Group Editing CRDTs" [2016]
- "CloudKit - Structured Storage for Mobile Applications" [2018]
- Project research notes https://docs.google.com/document/d/1uqFflQRgwTvOWul4fZWYizLxk7GSO8wC_x6HfBoAGyg

## warning
This code is not produciton ready. Data structures and api may change


## usage
You need to build your model using CR primitives. See tests.


## Goal
To describe text as an operation graph where adding operation does not modify exiting nodes (no foreign key updates, but leveraging reverse foreign key updates).
10K characters note needs to load with low latency - below 0.1s (tested on M1)

Source: https://www.nngroup.com/articles/response-times-3-important-limits/
"0.1 second is about the limit for having the user feel that the system is reacting instantaneously, meaning that no special feedback is necessary except to display the result."


## Performance/benchmark goal
### high
Opening a note that’s been previously locally edited
Every local operation (upstream) needs to be performed instantly (aim for the refresh rate speed)

### medium
Rendering 1st remote operation on the note since opening
Rendering remote operation backlog on the freshly opened note that’s been previously locally edited (might be a duplicate)
Rendering note that only have remote operations and has never been opened

### low
Sync to CloudKit


## Tasks
rebuilding protobuf model
```
cd Sources/CRAttributes/ReplicationModel
protoc --swift_out=. ProtoModel.proto --swift_opt=Visibility=Public
```
