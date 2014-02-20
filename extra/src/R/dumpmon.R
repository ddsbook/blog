library(stringr)
library(plyr)
library(reshape2)
library(ggplot2)

# read in last 3K tweets
dumpmon <- read.csv("dumpmon.csv", stringsAsFactors=FALSE)

# only leave yyyy-mm-dd so we can aggregate by day
dumpmon$Posted.at <- gsub(" .*$", "", dumpmon$Posted.at)

# extract data from tweet using str_extract() to find the patterns we want
# and then gsub() to just give us the values
dumpmon$emails <- as.numeric(gsub("Emails: ", "", 
                                   str_extract(dumpmon$Text, "Emails: [0-9]+")))
dumpmon$keywords <- as.numeric(gsub("Keywords: ", "", 
                                    str_extract(dumpmon$Text, "Keywords: [0-9\\.]+")))
dumpmon$hashes <- as.numeric(gsub("Hashes: ", "", 
                                  str_extract(dumpmon$Text, "Hashes: [0-9]+")))

# the previous extracts will produce NAs where there were no values,
# so we need to turn those  NAs to 0 for our calculations
dumpmon[is.na(dumpmon)] <- 0

# aggregate records & leaks via the plyr count() function
emails.agg <- count(dumpmon, c("Posted.at"), "emails")
hashes.agg <- count(dumpmon, c("Posted.at"), "hashes")

# where the previous aggregations countd a particular value
# this one just counts total tweets per day
dump.count <- count(dumpmon, c("Posted.at"))

# first convert the date string to an actual Date object
emails.agg$Posted.at <- as.Date(emails.agg$Posted.at)
hashes.agg$Posted.at <- as.Date(hashes.agg$Posted.at)
dump.count$Posted.at <- as.Date(dump.count$Posted.at)

# create a new data frame that is just a sequence of all the 
# days so we can fill in missing time series dates (if any)
# for that we'll need the min & max date from the tweet extract
min.date <- min(emails.agg$Posted.at, hashes.agg$Posted.at, dump.count$Posted.at)
max.date <- max(emails.agg$Posted.at, hashes.agg$Posted.at, dump.count$Posted.at)
all.days <- data.frame(Posted.at=seq(min.date, max.date, "days"))

# now do the time series fill for each of the previous aggregations
emails.agg <- merge(emails.agg, all.days, all=TRUE)
colnames(emails.agg) <- c("Date", "Emails")

hashes.agg <- merge(hashes.agg, all.days, all=TRUE)
colnames(hashes.agg) <- c("Date", "Hashes")

dump.count <- merge(dump.count, all.days, all=TRUE)
colnames(dump.count) <- c("Date", "DumpCount")

# and turn NAs to 0 (again)
emails.agg[is.na(emails.agg)] <- 0
hashes.agg[is.na(hashes.agg)] <- 0
dump.count[is.na(dump.count)] <- 0

# compute time series diff()'s (give us a feel for change between days
emails.diff <- emails.agg
emails.diff$Emails <- c(0, diff(emails.diff$Emails))
colnames(emails.diff) <- c("Date", "EmailsDiff")

hashes.diff <- hashes.agg
hashes.diff$Hashes <- c(0, diff(hashes.diff$Hashes))
colnames(hashes.diff) <- c("Date", "HashesDiff")

dump.count.diff <- dump.count
dump.count.diff$DumpCount <- c(0, diff(dump.count.diff$DumpCount))
colnames(dump.count.diff) <- c("Date", "DumpCountDiff")

# now buld new data frame for 'melting'
# we're doing scaling of the diff() deltas to see how 
# "out of norm" they are. We could just plot the raw values
# but this scaling might let us see if a particular day was
# out of the ordinary and worth poking at more
dumps <- data.frame(Date=emails.agg$Date,
                    Emails=emails.agg$Emails,
                    EmailsDiff=scale(emails.diff$EmailsDiff),
                    Hashes=hashes.agg$Hashes,
                    HashesDiff=scale(hashes.diff$HashesDiff),
                    DumpCount=dump.count$DumpCount,
                    DumpCountDiff=scale(dump.count.diff$DumpCountDiff))

# 'melting' is just turning the data from wide to long
# since we want to use the individual columns as facets for our plot
dumps.melted <- melt(dumps, id.vars=c("Date"))

# setup a substitution list for prettier facet labels
facet_names <- list(
  'Emails'="Emails Daily Raw Count",
  'EmailsDiff'="Emails Daily Change (Diff+Scaled)",
  'Hashes'="Hashes Daily Raw Count",
  'HashesDiff'="Hashes Daily Change (Diff+Scaled)",
  'DumpCount'="# Dumps/Day Raw Count",
  'DumpCountDiff'="# Dumps/Day Change (Diff+Scaled)"
)

# this will do the actual substitution. it's a good pattern to follow
# since facet_grid() actually as a 'labeller' parameter.
facet_labeller <- function(value) {
  return(as.character(facet_names[value]))
}

# but, facet_wrap() (which we're using) does not have a 'labeller'
# parameter, so we just munge the data directly
dumps.melted$variable <- facet_labeller(dumps.melted$variable)

# and then produce the final plot. Note that we are using
# free scales, so each chart stand on it's own value-wise, but we 
# group the diff/scaled ones together via the ncol=2 parameter
gg <- ggplot(dumps.melted, aes(x=Date))
gg <- gg + geom_line(aes(y=value, color=variable), alpha=0.65)
gg <- gg + geom_point(aes(y=value, color=variable), size=2, alpha=0.5)
gg <- gg + facet_wrap(~variable, scales="free_y", ncol=2)
gg <- gg + labs(x="", y="", title=sprintf("@dumpmon Statistics as of %s",format(Sys.time(), "%Y-%m-%d")))
gg <- gg + scale_color_manual(values=c("#0074d9", "#0074d9", "#2ecc40", "#2ecc40", "#FF851B", "#FF851B"))
gg <- gg + theme_bw()
gg <- gg + theme(legend.position="none")
gg <- gg + theme(plot.title=element_text(face="bold", size=13))
gg <- gg + theme(strip.background=element_blank())
gg <- gg + theme(strip.text=element_text(face="bold", size=11))

# save it out for posterity
ggsave(filename="dumpmon.svg", plot=gg, width=9, height=7)
