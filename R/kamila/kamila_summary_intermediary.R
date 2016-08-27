#!/util/academic/R/R-3.0.0/bin/Rscript
#
# Note: should only be used in the context of kamila.slurm.
# Takes current chunk summary stats as input on stdin, along with command line
# arguments listed below. Outputs a csv line (run #, con diff, and cat diff)
# to stdout.
#
# Input arguments:
# [1] FILE_DIR, location for output RData file
#
# Each stdin line input is of the format:
# 1.1 \t "robj"
# 1.2 \t "robj"
# 2.1 \t "robj"
# 2.2 \t "robj"
# ...
#

# get input arguments
argIn <- commandArgs(TRUE)
FILE_DIR <- argIn[1]

# Convert output from reducing step (centroid totals formatted as plaintext
# parsed R objects) into actual R object.
f <- file("stdin")
open(f)

myTotals <- list()

# Functions to update totals and counts, while preserving NULL/NA values
# for empty clusters.
updateTotalList <- function(totalList, newVal, keyInt) {
  # if key greater than length, insert new value and done
  if (keyInt > length(totalList)) {
    totalList[[keyInt]] <- newVal
    return(totalList)
  }
  # if existing position is NULL, insert new value and done
  if (is.null(totalList[[keyInt]])) {
    totalList[[keyInt]] <- newVal
    return(totalList)
  }
  # otherwise, add existing to new values and done
  # update count
  totalList[[keyInt]]$count <- (
    totalList[[keyInt]]$count + newVal$count)
  # update total dist
  totalList[[keyInt]]$totalDistToCentroid <- (
    totalList[[keyInt]]$totalDistToCentroid + newVal$totalDistToCentroid)
  # update total cat log lik
  totalList[[keyInt]]$totalCatLogLik <- (
    totalList[[keyInt]]$totalCatLogLik + newVal$totalCatLogLik)
  # update con stats
  totalList[[keyInt]]$con$totals <- (
    totalList[[keyInt]]$con$totals + newVal$con$totals)
  totalList[[keyInt]]$con$min <- (
    pmin(totalList[[keyInt]]$con$min, newVal$con$min))
  totalList[[keyInt]]$con$max <- (
    pmax(totalList[[keyInt]]$con$max, newVal$con$max))
  # update cat totals
  for (i in 1:length(totalList[[keyInt]]$cat)) {
    totalList[[keyInt]]$cat[[i]] <- (
      totalList[[keyInt]]$cat[[i]] + newVal$cat[[i]])
  }
  return(totalList)
}

#
# Note that the major key is of interest, and the minor isn't
while (length(line <- readLines(f,n=1)) > 0) {
  this_kvtuple <- unlist(strsplit(line,split="\t"))
  keysplit <- unlist(strsplit(this_kvtuple[1], split="\\."))
  key1 <- as.integer(keysplit[1])
  centroidTotals <- eval(parse(text=this_kvtuple[2]))
  # tally totals, counts
  myTotals <- updateTotalList(myTotals, centroidTotals, key1)
}

# convert totals to means
clustSummary <- lapply(
  X = myTotals,
  FUN = function(elm) {
    clusterInfo <- list()
    clusterInfo$count <- elm$count
    clusterInfo$totalDistToCentroid <- elm$totalDistToCentroid
    clusterInfo$totalCatLogLik <- elm$totalCatLogLik
    clusterInfo$con$means <- elm$con$totals / elm$count
    clusterInfo$con$min <- elm$con$min
    clusterInfo$con$max <- elm$con$max
    clusterInfo$catfreq <- lapply(
      elm$cat,
      FUN = function(varcount) {
        varcount / elm$count
      }
    )
    return(clusterInfo)
  }
)

#calculate overall internal metric of cluster quality
summedDistToCentroid <- sum(sapply(
  clustSummary,
  function(elm) elm[['totalDistToCentroid']]
))
summedCatLogLik <- sum(sapply(
  clustSummary,
  function(elm) elm[['totalCatLogLik']]
))
clusterQualityMetric <- summedDistToCentroid * summedCatLogLik

runSummary <- list(
  clusterQualityMetric = clusterQualityMetric,
  totalEucDistToCentroid = summedDistToCentroid,
  totalCatLogLik = summedCatLogLik
)

cat('
Cluster Summary Info:
')
str(clustSummary)

cat('
Run Summary Info:
')
str(runSummary)

save(clustSummary,runSummary,file=file.path(FILE_DIR,'finalRunStats.RData'))

