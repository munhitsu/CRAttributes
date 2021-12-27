# Enabling inverse perations for the container of String Operations resulted in a drastic penalty

## test
testCompareStringPerformanceUpstream

## See commit before:
renaming CD models to start from CD and adding CDGhostOp
6232974c8b6b6dda620eab75c75d7858e5b4dfad
50K Is 11.58s


## See commit after:
fixed missing reverse for container operations
d9f9ebf03830fcb65e42b0b0e76729082ef79b68
50K is 217s
20K is 40s
10K is 10s
