library(data.table)
library(bit64)

marx <- fread("marx-geo.csv", 
              nrows=451582,
              sep=",", header=TRUE)

write.csv(unique(na.omit(marx[,14:15,with=FALSE])), "latlon.csv", row.names=FALSE)
