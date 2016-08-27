#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate binned min distances from points to centroids
# write out file:
# 1.1 \t "robj"
# 1.2 \t "robj"
# 2.1 \t "robj"
# 2.2 \t "robj"
# ...
#
# where first col is (cluster id).(chunk id number), and robj is deparsed
# histogram object with min distance tallies for that cluster/chunk combo.

load('currentMeans.RData') # for myMeans; number of continuous vars

# Two functions to create and update histograms on the
# interval [0, 8*sqrt(ndim)] where ndim is the dimensionality
# of the data
initHist <- function(ndim,nbin=1e4) {
  maxVal <- 8*sqrt(ndim)
  width <- maxVal / nbin
  myHist <- list(
    counts = rep(0,nbin),
    width = width
  )
  return(myHist)
}
updateHist <- function(myHist, val) {
  ind <- floor(val/myHist$width) + 1
  myHist$counts[ind] = myHist$counts[ind] + 1
  # Note: if val exceeds threshold of the histogram, it is automatically
  # appended with NA padding. These should be changed to zeros, but after all
  # aggregation is done for computational efficiency.
  return(myHist)
}

numConVars <- length(myMeans[[1]][['centroid']])

f <- file("stdin")
open(f)

logHistInfo <- function(clusterNum, robj) {
  cat(clusterNum, '\t', paste(deparse(robj),collapse=''),'\n',sep='')
}

last_key <- Inf

while(length(line <- readLines(f,n=1)) > 0) {
  this_kvpair <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvpair[1]
  value <- as.numeric(this_kvpair[2])

  if (last_key == this_key) {
    # executed if still within same cluster
    thisHist <- updateHist(thisHist, value)
  } else {
    # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logHistInfo(last_key,thisHist)
    }
    # executed when starting any cluster, including the first
    thisHist <- initHist(numConVars)
    last_key <- this_key
  }

}
close(f)

if (exists('this_key') && last_key == this_key) {
  logHistInfo(last_key,thisHist)
}


