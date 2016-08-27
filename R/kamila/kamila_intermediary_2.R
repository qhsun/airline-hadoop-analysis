#!/util/academic/R/R-3.0.0/bin/Rscript
#
# Note: should only be used in the context of kamila.slurm.
# Takes current chunk summary stats as input on stdin, along with command line
# arguments listed below. Outputs a csv line (run #, con diff, and cat diff)
# to stdout.
#
# Input arguments:
# [1] JOBID, the id of the current SLURM job
# [2] CURR_RUN, the index of the current kamila run (outer loop)
# [3] CURR_IND, the index of the current kamila iteration (inner loop)
# [4] FILE_DIR, directory of current means file

# get input arguments
argIn <- commandArgs(TRUE)
JOBID <- argIn[1]
CURR_RUN <- as.integer(argIn[2])
CURR_IND <- as.integer(argIn[3])
FILE_DIR <- argIn[4]

# Load objects for generating pseudorandom vecs. Loading this automatically
# resets the current RNG state as needed. The file seeding.RData contains
# .Random.seed, the list currentQueue, and the function advanceQueue.
load(file.path(FILE_DIR, 'seeding.RData'))
load(file.path(FILE_DIR, 'currentMeans.RData'))

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
  totalList[[keyInt]]$con$count <- (
    totalList[[keyInt]]$con$count + newVal$con$count)
  # update con totals
  totalList[[keyInt]]$con$totals <- (
    totalList[[keyInt]]$con$totals + newVal$con$totals)
  # update cat totals
  for (i in 1:length(totalList[[keyInt]]$cat)) {
    totalList[[keyInt]]$cat[[i]] <- (
      totalList[[keyInt]]$cat[[i]] + newVal$cat[[i]])
  }
  return(totalList)
}

# Input has the format:
# 1.1 \t "robj"
# 1.2 \t "robj"
# 2.1 \t "robj"
# 2.2 \t "robj"
# ...
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


if (length(myTotals) == 0) {
  cat('NA')
  stop(paste('Stopped in iteration ',CURR_IND,'; no means detected.', sep=''))
}

# now loop through totals,counts to calculate myMeans
# in the event of empty clusters, NULLs propagate correctly.
myMeans <- list()
for (i in 1:length(myTotals)) {
  if (is.null(myTotals[[i]])) next
  myMeans[[i]] <- list(
    centroid = myTotals[[i]]$con$totals / myTotals[[i]]$con$count,
    thetas = lapply(
      myTotals[[i]]$cat,
      FUN = function(elm) elm / myTotals[[i]]$con$count
    )
  )
}

# Calculate distance between these centroids and previous
currentMeans <- myMeans
currentKde <- kdeStats
rm(myMeans)

# load previous means. Yes, index of RData file is one plus the index of the
# iter_[0-9]+ directory that contains it.
# Loaded file contains the variable stored as "myMeans"
load(file.path(
  paste('output-kamila-',JOBID,sep=''),
  paste('run_',CURR_RUN,sep=''),
  paste('iter_',CURR_IND - 1,sep=''),
  paste('currentMeans_i',CURR_IND,'.RData',sep='')
))
prevMeans <- myMeans

# If a cluster had zero points, initialize new random replacements
dataDim <- length(prevMeans[[1]])
for (i in 1:length(currentMeans)) {
  if (length(currentMeans[[i]]) == 0) {
    currentQueue <- advanceQueue(currentQueue)
    currentMeans[[i]] <- list(centroid = currentQueue$selectedCentroid, thetas = currentQueue$selectedThetas)
    warning('Empty internal centroid detected in intermediary script; regenerating: number of empty elements is now ',sum(vapply(currentMeans,is.null,NA)),'.')
  }
}

# make sure to initialize new replacement means if the last clusters were empty
lenPrevMeans <- length(prevMeans)
while( length(currentMeans) < lenPrevMeans ) {
  currentQueue <- advanceQueue(currentQueue)
  currentMeans[[length(currentMeans)+1]] <- list(centroid = currentQueue$selectedCentroid, thetas = currentQueue$selectedThetas)
  warning('Empty final centroid detected in intermediary script; regenerating: length is now ',length(currentMeans),'.')
}

myMeans <- currentMeans
kdeStats <- currentKde
save(myMeans,kdeStats,file=file.path(FILE_DIR,'currentMeans.RData'))

# Save state of RNG and source of centroid vecs.
# This is kind of clunky, but wrapping this save in a function treads on 
# risky ground regarding environments and manipulating .Random.seed directly.
save(
  .Random.seed,
  currentQueue,
  advanceQueue,
  file=file.path(FILE_DIR, 'seeding.RData')
)

# calculate and output the parameter differences
l1NormCon <- function(x1, x2) {
  sum(abs(x1-x2))
}
l1NormCat <- function(x1, x2) {
  sum(mapply(function(x,y) sum(abs(x-y)), x1, x2))
}

conParamDiff <- 0
catParamDiff <- 0
for (i in 1:length(currentMeans)) {
  conParamDiff <- conParamDiff + l1NormCon(currentMeans[[i]]$centroid,prevMeans[[i]]$centroid)
  catParamDiff <- catParamDiff + l1NormCat(currentMeans[[i]]$thetas,prevMeans[[i]]$thetas)
}

# write to stdout
cat(CURR_IND, ',', conParamDiff, ',', catParamDiff, '\n',sep='')

