#!/util/academic/R/R-3.0.0/bin/Rscript

# Command-line input argument: NUM_CHUNK, the number of splits associated with each centroid
# Read from file: current means
# Read from stdin: full csv data set in Hadoop streaming framework
# Output: two tab-delimited values: (1) key, and (2) distance to nearest
# continuous centroid. The key is (nearest centroidid).(chunk id number), where
# chunk id is an arbitrary integer that serves to split the reducer loads
# among different nodes.

argIn <- commandArgs(TRUE)
NUM_CHUNK <- as.numeric(argIn[1])

load('currentMeans.RData')

if (!exists('myMeans')) stop("Mean RData file not found")
numCentroids <- length(myMeans)
numConVars <- length(myMeans[[1]][['centroid']])

f <- file("stdin")
open(f)
thisChunkNum <- 1
while(length(line <- readLines(f,n=1)) > 0) {
  vec <- as.numeric(unlist(strsplit(line,',')))[1:numConVars]

  # Get nearest continuous centroid number
  smallestDist <- Inf
  closestCent <- -1
  for (i in 1:numCentroids) {
    ithDist <- dist(rbind(myMeans[[i]][['centroid']],vec))
    if (ithDist < smallestDist) {
      smallestDist <- ithDist
      closestCent <- i
    }
  }

  # output <clustNum \t vec>
  # where vec is comma separated numeric values
  cat(
    paste(closestCent,thisChunkNum,sep='.')
   ,'\t'
   ,round(smallestDist,8)
   ,'\n'
   ,sep=''
  )

  # Flip chunk number
  thisChunkNum <- thisChunkNum %% NUM_CHUNK + 1
}
