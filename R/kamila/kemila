#!/util/academic/R/R-3.0.0/bin/Rscript

# Input arguments:
# [1] NUM_CLUST, the number of clusters in the data
# [2] OUT_DIR, the pathway for the output.

# get input args
argIn <- commandArgs(TRUE)
NUM_CLUST <- as.integer(argIn[1])
OUT_DIR <- argIn[2]

# Load objects for generating pseudorandom vecs. Loading this automatically
# resets the current RNG state as needed. The file seeding.RData contains
# .Random.seed, the list currentQueue, and the function advanceQueue.
load(file.path(OUT_DIR, 'seeding.RData'))

myMeans <- list()
for (i in 1:NUM_CLUST) {
  currentQueue <- advanceQueue(currentQueue)
  myMeans[[i]] <- list(centroid = currentQueue$selectedCentroid, thetas = currentQueue$selectedThetas)
}

#dir.create(OUT_DIR) # already created in kmeans.slurm script
save(myMeans, file=file.path(OUT_DIR, 'currentMeans.RData')) # iteratively updated file
save(myMeans, file=file.path(OUT_DIR, 'initialMeans.RData')) # permanent log file

# Save state of RNG and source of centroid vecs.
# This is kind of clunky, but wrapping this save in a function treads on 
# risky ground regarding environments and manipulating .Random.seed directly.
save(
  .Random.seed,
  currentQueue,
  advanceQueue,
  file=file.path(OUT_DIR, 'seeding.RData')
)

