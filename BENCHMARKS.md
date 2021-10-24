#  <#Title#>


# baseline
## 50K operations loaded from oplog (snapshot + 5K ops)
'-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceUpstreamOperations]' measured [Time, seconds] average: 0.574, relative standard deviation: 1.905%, values: [0.605923, 0.567923, 0.570225, 0.569838, 0.571132, 0.569306, 0.570992, 0.573713, 0.569352, 0.567170],

## 50K characters in single op loaded from oplog
'-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceSinglePaste]' measured [Time, seconds] average: 0.226, relative standard deviation: 5.790%, values: [0.265494, 0.224175, 0.222242, 0.222327, 0.221308, 0.221605, 0.221434, 0.221513, 0.219938, 0.223092]




# step 1
## operations
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceUpstreamOperations]' measured [Time, seconds] average: 0.261, relative standard deviation: 4.321%, values: [0.294717, 0.254677, 0.256325, 0.257521, 0.257947, 0.257707, 0.258107, 0.256476, 0.258008, 0.259063]

## snapshot only
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceSinglePaste]' measured [Time, seconds] average: 0.226, relative standard deviation: 4.809%, values: [0.258921, 0.222463, 0.222781, 0.222912, 0.222889, 0.225582, 0.222221, 0.223184, 0.221152, 0.222070]

# step 2
moving from JSON encoder for array to unsafe memory mapping

## operations
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceUpstreamOperations]' measured [Time, seconds] average: 0.103, relative standard deviation: 9.086%, values: [0.131255, 0.099498, 0.101042, 0.101839, 0.099097, 0.099704, 0.099064, 0.100359, 0.099478, 0.101066]

## snapshot only
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceSinglePaste]' measured [Time, seconds] average: 0.010, relative standard deviation: 37.112%, values: [0.017772, 0.014696, 0.010791, 0.009419, 0.008419, 0.008625, 0.007204, 0.007037, 0.006626, 0.006217]

# step 3
bringing down the oplog depth to 1234 max (with 640 ops)
## operations (640 ops)
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceUpstreamOperations]' measured [Time, seconds] average: 0.016, relative standard deviation: 34.241%, values: [0.029890, 0.019985, 0.015865, 0.013768, 0.012832, 0.012998, 0.012606, 0.012478, 0.012247, 0.012346]

### sqlite on filesystem
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceUpstreamOperations]' measured [Time, seconds] average: 0.016, relative standard deviation: 41.532%, values: [0.035091, 0.020017, 0.015882, 0.014065, 0.013019, 0.013210, 0.012641, 0.012578, 0.012509, 0.012367]

## snapshot only
no impact expected
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceSinglePaste]' measured [Time, seconds] average: 0.010, relative standard deviation: 42.713%, values: [0.020734, 0.014002, 0.011471, 0.009880, 0.008773, 0.007821, 0.007240, 0.006707, 0.006785, 0.006369]

### sqlite on filesystem
-[CRAttributesTests.CRLocalOperationsTests testLoadingPerformanceSinglePaste]' measured [Time, seconds] average: 0.011, relative standard deviation: 39.036%, values: [0.020249, 0.014730, 0.012780, 0.011494, 0.009526, 0.007999, 0.007307, 0.007544, 0.006591, 0.007412]

