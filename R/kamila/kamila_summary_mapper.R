#!/util/academic/R/R-3.0.0/bin/Rscript

# Command-line input argument: NUM_CHUNK, the number of splits associated with each centroid
# Read from file: current means
# Read from stdin: full csv data set in Hadoop streaming framework
# Output: four tab-delimited values:
#  (1) key: The key is (nearest centroidid).(chunk id number), where chunk id
#      is an arbitrary integer that serves to split the reducer loads among
#      different nodes.
#  (2) Euclidean distance to nearest cluster
#  (3) categorical log-likelihood
#  (4) comma delimited data vector

argIn <- commandArgs(TRUE)
NUM_CHUNK <- as.numeric(argIn[1])

# Load current centroid stats
load('currentMeans.RData')

# load helper functions.
source('helperFunctions.R') # load evalAllMult, evalAllKde

if (!exists('myMeans') || !exists('kdeStats')) stop("Mean RData file not complete.")

numClusts <- length(myMeans)
numConVars <- length(myMeans[[1]][['centroid']])
numCatVars <- length(myMeans[[1]][['thetas']])

f <- file("stdin")
open(f)
thisChunkNum <- 1
while(length(line <- readLines(f,n=1)) > 0) {
  vec <- as.numeric(unlist(strsplit(line,',')))
  conVec <- vec[1:numConVars]
  catVec <- vec[(numConVars+1):(numConVars+numCatVars)]

  # Get distances to each continuous centroid evaluated at radialKDE, posterior
  # probability of categorical vector, and multiply. Use to assign to best
  # cluster.
  # Continuous distances: Could have stored this the first MR run, but the
  # additional costs of writing all to file is unappealing.
  conLogLiks <- evalAllKde(
    dataVec=conVec,
    paramList=myMeans
  )
  catLogLiks <- evalAllMult(dataVec=catVec, paramList=myMeans)
  objectiveFuns <- conLogLiks + catLogLiks
  closestCent <- which.max(objectiveFuns)
  eucDist <- dist(rbind(
    conVec,
    myMeans[[closestCent]][['centroid']]
  ))

  # output <clustNum \t vec>
  # where vec is comma separated numeric values
  cat(
    paste(closestCent,thisChunkNum,sep='.')
   ,'\t'
   ,eucDist
   ,'\t'
   ,catLogLiks[closestCent]
   ,'\t'
   ,paste(vec,collapse=',')
   ,'\n'
   ,sep=''
  )

  # Flip chunk number
  thisChunkNum <- thisChunkNum %% NUM_CHUNK + 1
}
