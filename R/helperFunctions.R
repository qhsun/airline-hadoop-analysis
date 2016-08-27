
# deprecated
genMean <- function(dim) {
  runif(n = dim, min = -2, max = 2)
}

mergeHists <- function(histList) {
  # input is a list of histogram objects
  # make sure width is the same
  # replace NAs with zeros
  # pad all to max
  # sum all, create new hist and output
}

# Evaluate multinomial PMF for one observation
evalOneMultin <- function(obs,thet) {
  if (obs > length(thet)) {
    stop('Categorical level is not included in multinomial parameter vector')
  }
  thet[obs]
}

# Evaluate multinomial over several PMFs
# Generates matrix of Q x G probs (Q cat vars and G clusters) and then sums
# log probs over columns to yield a numeric vector of length G with cluster-
# specific log probs.
evalAllMult <- function(dataVec, paramList) {
  probMat <- sapply(
    paramList,
    function(elm) mapply(FUN=evalOneMultin, obs=dataVec, thet=elm[['thetas']])
  )
  clusterCatLogLiks <- apply(probMat, 2, FUN=function(col) sum(log(col)))
  return(clusterCatLogLiks)
}

# Calculate a distance to a centroid and evaluate at kde. Call
# kdeStats$resampler() from outside of the function scope.
evalOneKde <- function(obs, cent) {
  if (length(obs) != length(cent)) {
    stop('Continuous data vector is of different length than the centroid vector')
  }
  thisDist <- dist(rbind(cent, obs))
  kdeStats$resampler(thisDist)
}
# Calculate distance to each centroid and evaluate at radialKDE
evalAllKde <- function(dataVec, paramList, myKde) {
  probVec <- sapply(
    paramList,
    function(elm) {
      evalOneKde(obs=dataVec, cent=elm[['centroid']])
    }
  )
  return(log(probVec))
}
