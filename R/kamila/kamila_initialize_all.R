#!/util/academic/R/R-3.0.0/bin/Rscript

# These objects and functions are only intended to be used by kamila.slurm.
#
# This script creates a preselected and pseudo-randomized object that contains
# all centroids and multinomial parameter estimates that may be used for
# initializing the kamila runs. Randomization is controlled by the input seed.
# If, during the kamila runs, the number of centroids is exhausted, then they
# are re-randomized and reused. Centroids are a random subset of points in the
# larger data set, and multinomial params are randomly sampled from the flat
# dirichlet distribution.

# Input arguments:
# [1] SEED, an integer giving the initial seed for R's RNG state.
# [2] OUT_DIR, where the RData file will be saved.
# [3] SUBSAMP, the directory and filename of a csv subsampled version of the 
#     data set of interest. Here SUBSAMP must be only con vars.
# [4] CATINFO, the path and filename to tsv metadata file describing, among
#     other things, the number of categorical levels per categorical variable.

library(gtools) # for rdirichlet

argIn <- commandArgs(TRUE)
INITIAL_SEED <- as.integer(argIn[1])
OUT_DIR <- argIn[2]
SUBSAMP <- argIn[3]
CATINFO <- argIn[4]

set.seed(INITIAL_SEED)

subsampledConData <- read.csv(SUBSAMP)
nSamples <- nrow(subsampledConData)

# generate randomly permuted row indices
randInds <- sample(nSamples)

# load categorical metadata
catMetaData <- read.table(CATINFO,stringsAsFactors=F,header=T,sep='\t')
varCounts <- catMetaData$NumLev
names(varCounts) <- catMetaData$VarName

# Generate random multinomial params: This is a list of lists of vectors.
# The outer list is length nSamples, each inner list has length equal to the
# number of categorical variables. The contents of each inner list is a
# numeric vector containing randomly initialized multinomial parameters (one
# number per categorical level).
randThetas <- replicate(
  expr = lapply(
    varCounts,
    FUN = function(cnt) {
      rdirichlet(n = 1, alpha = rep(1,cnt))
    }
  ),
  n = nSamples,
  simplify = FALSE
)

# create list to hold all info needed to generate random vecs
currentQueue <- list(
  selectedCentroid = NULL,
  selectedThetas   = NULL,
  inds = randInds,
  conParams = subsampledConData,
  catParams = randThetas
)

# create function to advance the queue and return a vec
# modify to accomodate the above structure.
advanceQueue <- function(queue) {
  # if the current inds is empty, regenerate
  if (length(queue$inds) == 0) {
    queue$inds <- sample(nrow(queue$data))
  }
  # pull the first ind
  thisInd <- queue$inds[1]
  queue$inds <- queue$inds[-1]
  # access and store the selected vector
  queue$selectedCentroid <- as.numeric(queue$conParams[thisInd,])
  queue$selectedThetas   <- queue$catParams[[thisInd]]
  return(queue)
}

save(
  .Random.seed,
  currentQueue,
  advanceQueue,
  file=file.path(OUT_DIR, 'seeding.RData')
)

