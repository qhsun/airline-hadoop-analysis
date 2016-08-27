#!/util/academic/R/R-3.0.0/bin/Rscript

# Calculate cluster-level means, multinomial thetas
#
# Input file:
# 1.1 \t datavec
# 1.2 \t datavec
# 2.1 \t datavec
# 2.2 \t datavec
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

# Results object: A list of the similar structure as an element of myMeans
# A list with 2 elements:
#	1) con: Running totals and counts for continuous vars
#	2) cat: Running categorical var counts
# A simple constructor-like function. Output should be named totalList.
# Alternately, could in get count from cat var sums and gain a bit of speed.
makeResultsObject <- function() {
  return(list(
    con = list(totals=rep(0,numConVars), count=0),
    cat = lapply(myMeans[[1]][['thetas']], FUN=function(elm) rep(0,length(elm)))
  ))
}

# Add vec to total; a poor man's mutator method for totalList, an object
# initialized by makeResultsObject().
addVecToTotal <- function(newVec) {
  # update continuous
  totalList$con$totals <<- totalList$con$totals + newVec[1:numConVars]
  totalList$con$count  <<- totalList$con$count  + 1
  # update categorical
  myCatVars <- newVec[(numConVars+1):(numConVars+numCatVars)]
  for (i in 1:numCatVars) {
    totalList$cat[[i]][myCatVars[i]] <<- totalList$cat[[i]][myCatVars[i]] + 1
  }
}

f <- file("stdin")
open(f)

# Print cluster summary info to stdout where Hadoop's machinery takes over.
logClustInfo <- function(clusterNum, robj) {
  cat(clusterNum,'\t',paste(deparse(robj),collapse=''),'\n',sep='')
}

last_key <- Inf

while(length(line <- readLines(f,n=1)) > 0) {
  # Unpack data streaming into stdin from Hadoop
  this_kvpair <- unlist(strsplit(line,split="\t"))
  this_key <- this_kvpair[1]
  value <- as.numeric(unlist(strsplit(this_kvpair[2],split=",")))

  if (last_key == this_key) {
    # executed if still within same cluster
    addVecToTotal(value)
  } else { # executed when ending a cluster or starting the first
    if (last_key!=Inf) {
      # executed when ending a cluster
      logClustInfo(last_key, totalList)
    }
    # executed when starting any cluster, including the first
    totalList <- makeResultsObject()
    last_key <- this_key
  }

}
close(f)

if (exists('this_key') && last_key == this_key) {
  logClustInfo(last_key, totalList)
}


