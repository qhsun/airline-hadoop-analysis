#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate cluster-level means, multinomial thetas
#
# Input file: clust/chunk id, distance to centroid, cat log lik, data vec
# 1.1 \t 3.42 \t 2.99 \t datavec
# 1.2 \t 2.74 \t 5.03 \t datavec
# 2.1 \t 6.25 \t 2.28 \t datavec
# 2.2 \t 3.36 \t 1.42 \t datavec
# ...
#
# write out file:
# 1.1 \t "robj"
# 1.2 \t "robj"
# 2.1 \t "robj"
# 2.2 \t "robj"
# ...
#
# Where first col is (cluster id).(chunk id number) and robj is deparsed
# list object with continuous sums and categorical level tallies for that
# cluster/chunk combo.

load('currentMeans.RData') # for myMeans; number of continuous vars
numConVars <- length(myMeans[[1]][['centroid']])
numCatVars <- length(myMeans[[1]][['thetas']])

# Summary object: A list of the similar structure as an element of myMeans.
# One object will keep track of info for each cluster
# A list with 3 elements:
#	1) con: Running min, max, and totals, for continuous vars
#	2) cat: Running categorical var counts
#	3) count: Overall count 
# A simple constructor-like function. Output should be named totalList.
# Alternately, could in get count from cat var sums and gain a bit of speed.
makeSummaryObject <- function() {
  return(list(
    con = list(min=rep(Inf,numConVars), max=rep(-Inf,numConVars), totals=rep(0,numConVars)),
    cat = lapply(myMeans[[1]][['thetas']], FUN=function(elm) rep(0,length(elm))),
    totalDistToCentroid = 0,
    totalCatLogLik = 0,
    count = 0
  ))
}

# Add vec to total; a poor man's mutator method for totalList, an object
# initialized by makeSummaryObject(). Global assignment is used to avoid
# passing the modified object.
addVecToTotal <- function(newVec, newDist, newCatLogLik) {
  # update count
  totalList$count  <<- totalList$count + 1
  # update total distance to centroid
  totalList$totalDistToCentroid <<- totalList$totalDistToCentroid + newDist
  # udpate total cat log lik
  totalList$totalCatLogLik <<- totalList$totalCatLogLik + newCatLogLik
  # update continuous
  thisConVec <- newVec[1:numConVars]
  totalList$con$totals <<- totalList$con$totals + thisConVec
  totalList$con$min    <<- pmin(totalList$con$min, thisConVec)
  totalList$con$max    <<- pmax(totalList$con$max, thisConVec)
  # update categorical
  myCatVars <- newVec[(numConVars+1):(numConVars+numCatVars)]
  for (i in 1:numCatVars) {
    totalList$cat[[i]][myCatVars[i]] <<- totalList$cat[[i]][myCatVars[i]] + 1
  }
}

# Print cluster summary info to stdout where Hadoop's machinery takes over.
logClustInfo <- function(clusterNum, robj) {
  cat(clusterNum,'\t',paste(deparse(robj),collapse=''),'\n',sep='')
}

# Ingest data rows from stdin and process them.
f <- file("stdin")
open(f)

last_key <- Inf

while(length(line <- readLines(f,n=1)) > 0) {
  # Unpack data streaming into stdin from Hadoop
  this_kvtuple <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvtuple[1]
  eucDist <- as.numeric(this_kvtuple[2])
  catLogLik <- as.numeric(this_kvtuple[3])
  dataVec <- as.numeric(unlist(strsplit(this_kvtuple[4],split=",")))

  if (last_key == this_key) {
    # executed if still within same cluster
    addVecToTotal(dataVec,eucDist,catLogLik)
  } else { # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logClustInfo(last_key, totalList)
    }
    # executed when starting any cluster, including the first
    totalList <- makeSummaryObject()
    last_key <- this_key
  }

}
close(f)

if (exists('this_key') && last_key == this_key) {
  logClustInfo(last_key, totalList)
}


