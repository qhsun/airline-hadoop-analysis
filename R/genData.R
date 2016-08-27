
require(mvtnorm)

set.seed(2)

ndim <- 5
mu2 <- 3

# create data directory
suppressWarnings(dir.create('csv'))

# small continuous dataset
#nn <- 10^3
#dat <- rbind(
#  rmvnorm(nn,sigma=diag(ndim))
# ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
#)
#
#write.table(
#  dat
# ,file="csv/small2clust.csv"
# ,row.names=FALSE
# ,col.names=TRUE
# ,sep = ","
#)

# small mixed data set
nn <- 10^3
dat <- data.frame(
  C1 = c(rnorm(nn),rnorm(nn,mean=mu2)),
  D1 = c(
    sample(c('puma','lion','tiger','serval'),size=nn,replace=T),
    sample(c('puma','lion'),size=nn,replace=T)
  ),
  C2 = c(runif(nn), runif(nn,min=0.5,max=1.5)),
  D2 = c(
    sample(c('common','very common'),size=2*nn - 7,replace=TRUE),
    rep('rare',4),
    rep('super rare', 3)
  ),
  D3 = sample(paste('lev',1:15,sep=''),size=2*nn,replace=TRUE)
)

dat[2,'C1'] <- NA
dat[5,'C2'] <- NA
dat[8,'C1'] <- NA
dat[12,'C2'] <- NA
dat[20,'C2'] <- NA

write.table(
  dat,
  file = 'csv/smallMixed.csv',
  row.names=FALSE,
  col.names=TRUE,
  sep=','
)

# medium dataset ~ 100MB
#nn <- 10^6
#ndim <- 3
#dat <- rbind(
#  rmvnorm(nn,sigma=diag(ndim))
# ,rmvnorm(nn,mean=rep(mu2,ndim),sigma=diag(ndim))
#)
#write.table(
#  dat
# ,file="csv/medium2clust.csv"
# ,row.names=FALSE
# ,col.names=TRUE
# ,sep = ","
#)

# 1GB data set
set.seed(1)
nn <- 10^7
ndim <- 3

#chunkSize <- 10^6
#for (i in 1:(nn/chunkSize)) {
#  cat('\n Now writing chunk',i)
#  thisDat <- rbind(
#    rmvnorm(chunkSize,sigma=diag(ndim))
#   ,rmvnorm(chunkSize,mean=rep(mu2,ndim),sigma=diag(ndim))
#  )
#  write.table(
#    thisDat
#   ,file="csv/clust1GB.csv"
#   ,row.names=FALSE
#   ,col.names=TRUE
#   ,sep = ","
#   ,append = TRUE
#  )
#}


# 5GB data set
set.seed(1)
nn <- 5*10^7
ndim <- 3

#chunkSize <- 10^6
#nChunks <- nn/chunkSize
#for (i in 1:(nChunks)) {
#  cat('\n Now writing chunk',i,'/',nChunks)
#  thisDat <- rbind(
#    rmvnorm(chunkSize,sigma=diag(ndim))
#   ,rmvnorm(chunkSize,mean=rep(mu2,ndim),sigma=diag(ndim))
#  )
#  write.table(
#    thisDat
#   ,file="csv/clust5GB.csv"
#   ,row.names=FALSE
#   ,col.names=TRUE
#   ,sep = ","
#   ,append = TRUE
#  )
#}

# small data set with missing values and non-numbers
#dat <- data.frame(a=rnorm(25),b=sample(letters,size=25,replace=T),stringsAsFactors=F)
#dat[3,1]=NA
#dat[1,2]=1
#dat[2,2]=''
#for (i in 5:24) dat[i,2]=i
#write.table(
#  dat
# ,file='csv/smallMissing.csv'
# ,row.names=FALSE
# ,col.names=TRUE
# ,sep=","
#)

