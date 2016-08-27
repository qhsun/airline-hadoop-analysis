#!/util/academic/R/R-3.0.0/bin/Rscript

# Read in individual chunk histograms from stdin, and combine them. Calculate
# n, IQR, s^2, h, and full KDE function.

# Input arguments:
# [1] OUT_DIR, directory of current means file

# get input arguments
argIn <- commandArgs(TRUE)
OUT_DIR <- argIn[1]

load(file.path(OUT_DIR,'currentMeans.RData')) # for myMeans; number of continuous vars
numConVars <- length(myMeans[[1]][['centroid']])

# function to aggregate histograms
addHists <- function(hist1,hist2) {
  if (is.null(hist2)) return(hist1)
  if (hist1$width != hist2$width) {
    stop("Width of first histogram doesn't match width of second")
  }
  len1 <- length(hist1$counts)
  len2 <- length(hist2$counts)
  newCounts <- rep(0,max(len1,len2))
  for (i in 1:max(len1,len2)) {
    newCounts[i] <- sum(hist1$counts[i],hist2$counts[i],na.rm=TRUE)
  }
  return(list(
    counts = newCounts,
    width = hist1$width
  ))
}

# convert output from reducing step (centroid totals formatted as plaintext parsed R objects) into actual R object
f <- file("stdin")
open(f)

totalHist <- NULL
while (length(line <- readLines(f,n=1)) > 0) {
  this_kvtuple <- unlist(strsplit(line,split="\t"))
  #keysplit <- unlist(strsplit(this_kvtuple[1], split="\\."))
  #key1 <- as.integer(keysplit[1])
  thisHist <- eval(parse(text=this_kvtuple[2]))
  totalHist <- addHists(thisHist,totalHist)
}

# calc stats of interest on data set
cc <- totalHist$counts
cumulativeCounts <- cumsum(cc)
vv <- seq(from=totalHist$width/2, by=totalHist$width, length.out=length(totalHist$counts))
kdeStats <- list(
  n = sum(cc)
)
kdeStats$mean <- sum(cc * vv) / kdeStats$n

# Variance with Sheppard's correction
# http://mathworld.wolfram.com/SheppardsCorrection.html
sheppardVarianceCorr <- totalHist$width^2 / 12
kdeStats$var  <- sum(cc * (vv - kdeStats$mean)^2) / (kdeStats$n - 1) - sheppardVarianceCorr

# function to reference binned data by rank order index
indexHist <- function(histValues, cucounts, ind) {
  histInd <- which(cucounts >= ind)[1]
  histValues[histInd]
}

# iqr calculation; using R's stats::quantile default type 7 calculation
#n = 10; p = 0.27; yy = sort(rnorm(n)); quantile(yy,probs=p)
#m = 1-p; j = floor(n*p + m); gam = n*p + m - j; (1 - gam)*yy[j] + gam*yy[j+1]
m25 <- 1 - 0.25
m75 <- 1 - 0.75
j25 <- floor(kdeStats$n * 0.25 + m25)
j75 <- floor(kdeStats$n * 0.75 + m75)
gam25 <- kdeStats$n * 0.25 + m25 - j25
gam75 <- kdeStats$n * 0.75 + m75 - j75
x_j_25 <-   indexHist(vv, cumulativeCounts, j25)
x_j_75 <-   indexHist(vv, cumulativeCounts, j75)
x_jp1_25 <- indexHist(vv, cumulativeCounts, j25 + 1)
x_jp1_75 <- indexHist(vv, cumulativeCounts, j75 + 1)
kdeStats$q25 <- (1 - gam25)*x_j_25 + gam25*x_jp1_25
kdeStats$q75 <- (1 - gam75)*x_j_75 + gam75*x_jp1_75
kdeStats$iqr <- kdeStats$q75 - kdeStats$q25

# bandwidth calculation from Silverman's 1986 book on kernel density estimation
# page 48, eq. 3.31
# h = 0.9 * A * n^(-1/5)
# A = min(sd, iqr/1.34)
kdeStats$h <- 0.9 * min(sqrt(kdeStats$var), kdeStats$iqr/1.34) * kdeStats$n^(-1/5)

#######################################################
# Kernel density estimation using weighted estimator.
# Consider folding this into the radialKDE function in the kamila R package,
# however the radialKDE incorporates the evaluation points which we do not
# need here, so some fairly deep refactoring would be needed.
#######################################################

# only use values with observations
vv_gt0 <- vv[cc > 0]
cc_gt0 <- cc[cc > 0]

radKDE <- density(
  x = vv_gt0,
  weights = cc_gt0 / sum(cc_gt0),
  bw = kdeStats$h,
  adjust = 1,
  kernel = 'gaussian',
  from = 0
)

# remove any zero and negative density estimates to avoid -Inf logs
newY <- radKDE$y
nonnegTF <- newY > 0
minPos <- min(newY[nonnegTF]) / 100
if (any(!nonnegTF)) {
  newY[!nonnegTF] <- minPos
}
  
# radial Jacobian transformation; up to proportionality constant
radY <- c(newY / radKDE$x^(numConVars-1))
  
## replace densities over MAXDENS with MAXDENS
MAXDENS <- 1
overMax <- radY > MAXDENS
radY[overMax] <- MAXDENS

# normalize to area 1
densR <- radY/(radKDE$bw * sum(radY))
  
# now create resampling function
kdeStats$resampler <- approxfun(x=radKDE$x, y=densR,rule=1:2, method='linear')

with(kdeStats,
  cat(
    '
    -------------------
    n = ', n, '
    mean = ', mean, '
    var = ', var, '
    q25 = ', q25, '
    q75 = ', q75, '
    iqr = ', iqr, '
    h = ', h, '
    -------------------
    '
  )
)

# debugging ascii plots
#with(radKDE,txtplot::txtplot(x,y))
#with(radKDE,txtplot::txtplot(x,newY))
#txtplot::txtcurve(kdeStats$resampler(x), from=0, to=max(radKDE$x))
txtplot::txtcurve(log(kdeStats$resampler(x)), from=0, to=max(radKDE$x))

save(myMeans,kdeStats,file=file.path(OUT_DIR,'currentMeans.RData'))

