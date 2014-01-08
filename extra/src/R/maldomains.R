library(stringr)
library(plyr)
library(MASS)
library(data.table)
library(ggplot2)
library(reshape2)


mdl.df <- read.csv(file="~/Desktop/mdl.csv", 
                   col.names=c('date', 'domain', 'ip', 'reverse',
                               'description', 'registrant', 'asn',
                               'inactive','country'))

# take a look at the structure of the data
str(mdl.df)

# examine the start and end of the data
head(mdl.df)
tail(mdl.df)

mdl.df[mdl.df == "-"] <- NA

mdl.df <- mdl.df[complete.cases(mdl.df),]

# re-explore the data
str(mdl.df)

head(mdl.df$description)
tail(mdl.df$description)

summary(mdl.df$description)

mdl.df <- data.frame(sapply(mdl.df, tolower))
summary(mdl.df$description)

head(summary(mdl.df$domain))

# sub-optimal way to get TLDs, but didn't feel like writing it in R
write.table(str_extract(mdl.df$domain, perl("^[a-zA-Z0-9\\-\\._]+")),
            file="/tmp/indomains.txt",
            quote=FALSE,
            col.names=FALSE,
            row.names=FALSE)
system("~/Desktop/tlds.py", ignore.stdout=TRUE)
mdl.df$domain <- factor(scan(file="/tmp/outdomains.txt", 
                             what=character(), 
                             quiet=TRUE))

mdl.df$inactive <- as.numeric(mdl.df$inactive)
mdl.df$country <- as.numeric(mdl.df$country)

cor(mdl.df$inactive, mdl.df$country)

# R version of ClickSecurity's gtest() functions
# http://l.rud.is/1dvNxHQ

gtest <- function(count, expected) {
  if (count == 0) {
    return(0)
  } else {
    return(2*count*log(count/expected))
  }
}

#' Categorical contingency table + G-test
#' 
#' \code{highest.gtest.scores} takes two categorical vectors and 
#' returns a contingency table data.frame with max G-test scores
#' 
#' @param series.a a vector of categorical data the same size as series.b
#' @param series.b a vector of categorical data the same size as series.a
#' @param N how many of the top N keys in series.a should be returned
#' @param matches how many matches for each key should be returned
#' @param reverse reverse sort (high to low)
#' @param min.volume for some data you only want to see values wiht reasonable volume
#' @return a data.frame object (contingency table + max G-test score)
#' 
#' This differes from the ClickSecurity highest_gtest_scores() function since
#' we don't return the keys or match_list since they are pretty simple/quick to
#' retrieve from the resultant data.frame and won't always be needed

highest.gtest.scores <- function(series.a, series.b, 
                                 N=10, matches=10, 
                                 reverse=FALSE, min.volume=0) {
  
  # assume series.a categories are equally distributed among series.b categories
  
  series.a.tab <- table(series.a)
  series.a.tab.df <- data.frame(a=names(series.a.tab), 
                                a.freq=as.numeric(series.a.tab), 
                                stringsAsFactors=FALSE)
  series.a.tab.df$expected <- series.a.tab.df$a.freq / 
    length(unique(as.character(series.b)))
  
  # build base data.frame of series.a & series.v vectors, adding
  # series.a's frequency counts and computed expected value
  
  series.df <- data.frame(a=series.a, b=series.b)
  series.df <- merge(series.df, series.a.tab.df)    
  
  # build a contingency table of pairs with series.a min.volume counts
  # and calculate a gtest() score for each pair
  
  con.tab.df <- count(series.df[series.df$a.freq > min.volume, c("a","b")], 
                      vars=c("a","b"))
  con.tab.df <- join(con.tab.df, series.a.tab.df)
  con.tab.df$gscore <- mapply(gtest, con.tab.df$freq, con.tab.df$expected)
  
  # add the max gscore() to the original series.a contingency table
  
  series.a.tab.df <- merge(series.a.tab.df, 
                           aggregate(gscore ~ a, data=con.tab.df, max))
  
  # categories from series.a from the top or bottom?
  
  n.cats <- NA
  if (reverse) {
    n.cats <- tail(series.a.tab.df[order(-series.a.tab.df$gscore),], N)
  } else {
    n.cats <- head(series.a.tab.df[order(-series.a.tab.df$gscore),], N)
  }
  
  # compare counts against expected counts (given the setup null hypothesis
  # that each category should have a uniform distribution across all other
  # categories)
  
  a.v.b <- con.tab.df[(con.tab.df$a %in% n.cats$a),]
  #   a.v.b <- a.v.b[a.v.b$gscore > a.v.b$expected,]
  a.v.b <- ldply(n.cats$a, function(x) { # only extract top/bottom N cats
    tmp <- a.v.b[a.v.b$a==x,] # only looking for thes
    head(tmp[order(-tmp$gscore),], matches) # return 'matches' # of pairs
  })
  
  return(a.v.b)
  
}

# helper plot function for the gtest() data frame

gtest.plot <- function(gtest.df, xlab="x", ylab="count", title="") {
  gg <- ggplot(data=gtest.df, aes(x=b, y=freq))
  gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=a))
  gg <- gg + theme_bw()
  gg <- gg + labs(x=xlab, y=ylab, title=title)
  gg <- gg + theme(axis.text.x=element_text(angle=90,vjust=0.5,hjust=1),
                   legend.title=element_blank())
  return(gg)
}

# top 5 malware v asn
top5 <- highest.gtest.scores(mdl.df$description, mdl.df$asn, 5, 5)
gtest.plot(top5, "ASN", "Explot Occurrences")

# bottom 7 malware v asn
bottom7 <- highest.gtest.scores(mdl.df$description, mdl.df$asn, 7, 20, TRUE, 500)
gtest.plot(bottom7, "ASN", "Explot Occurrences")

# top 5 malware v domain
top5.dom <- highest.gtest.scores(mdl.df$description, mdl.df$domain, 5)
gtest.plot(top5.dom, "Domain", "Explot Occurrences")

# drilling down to one particluar exploit
banker <- mdl.df[mdl.df$description == "trojan banker",]
banker.gt <- highest.gtest.scores(banker$description, banker$domain, N=5)
colnames(banker.gt) <- c("description", "domain", "count", "a.count", "expected", "gscore")
banker.gt[,c(1:3)]

# let's look at the dates
mdl.df$date <- as.POSIXct(as.character(mdl.df$date),format="%Y/%m/%d_%H:%M")
mdl.df$ym <- strftime(mdl.df$date, format="%Y-%m")

# hack to sum by year & month
extract <- count(mdl.df,vars=c("ym","description"))

desc.tot <- table(mdl.df$description)
desc.tot.df <- data.frame(sort(desc.tot,decreasing=TRUE))
desc.tot.df$description <- rownames(desc.tot.df)
row.names(desc.tot.df) <- NULL
colnames(desc.tot.df) <- c("freq","description")
head(as.character(mdl.df$date))

extract <- extract[extract$description %in% head(desc.tot.df$description,7),]

gg <- ggplot(extract, aes(x=ym, y=freq, group=description))
gg <- gg + geom_line(aes(color=description))
gg <- gg + facet_wrap(~description,ncol=1)
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
                 legend.position="none")
gg

extract.total <- count(mdl.df, vars=c("ym"))

gg <- ggplot(extract.total, aes(x=ym, y=freq, group=NA))
gg <- gg + geom_line()
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
                 legend.position="none")
gg

top20 <- count(mdl.df,vars=c("ym","description"))
top20 <- top20[top20$description %in% head(desc.tot.df$description,20),]
top20 <- dcast(ym~description, data=top20)
top20$ym <- as.numeric(factor(top20$ym))

top20.cor <- cor(top20[,-1], use="pairwise.complete.obs")
top20.cor.df <- data.frame(top20.cor)
top20.cor.df$description <- rownames(top20.cor.df)
top20.cor.df <- melt(top20.cor.df)

gg <- ggplot(top20.cor.df, aes(x=description, y=variable))
gg <- gg + geom_tile(aes(fill=value), color="#7f7f7f")
gg <- gg + scale_fill_gradient2(limits=range(top20.cor.df$value,na.rm=TRUE),
                                low="#34419a", mid="#fdfec1", high="#9f0024", na.value="white")
gg <- gg + theme_bw()
gg <- gg + labs(x="", y="")
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
gg 

zeus <- count(mdl.df,vars=c("ym","description"))
zeus <- zeus[zeus$description %in% c('zeus v1 trojan','zeus v1 config file','zeus v1 drop zone'),]
zeus.df <- zeus
zeus <- dcast(ym~description, data=zeus)

zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
zeus.cor.df = data.frame(zeus.cor)
zeus.cor.df$description <- rownames(zeus.cor.df)
zeus.cor.df <- melt(zeus.cor.df)

zeus.cor

gg <- ggplot(zeus.df, aes(x=ym, y=freq, group=description))
gg <- gg + geom_line(aes(color=description))
gg <- gg + facet_wrap(~description,ncol=1)
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
                 legend.position="none")
gg

zeus <- count(mdl.df,vars=c("ym","description"))
zeus <- zeus[zeus$description %in% c('zeus v2 trojan','zeus v2 config file','zeus v2 drop zone'),]
zeus.df <- zeus
zeus <- dcast(ym~description, data=zeus)

zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
zeus.cor.df = data.frame(zeus.cor)
zeus.cor.df$description <- rownames(zeus.cor.df)
zeus.cor.df <- melt(zeus.cor.df)

zeus.cor

gg <- ggplot(zeus.df, aes(x=ym, y=freq, group=description))
gg <- gg + geom_line(aes(color=description))
gg <- gg + facet_wrap(~description,ncol=1)
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
                 legend.position="none")
gg

trojan.phoenix <- count(mdl.df,vars=c("ym","description"))
trojan.phoenix <- trojan.phoenix[trojan.phoenix$description %in% c('trojan','phoenix exploit kit'),]
trojan.phoenix.df <- trojan.phoenix
trojan.phoenix <- dcast(ym~description, data=trojan.phoenix)

trojan.phoenix.cor <- cor(trojan.phoenix[,-1], use="pairwise.complete.obs")
trojan.phoenix.cor.df = data.frame(trojan.phoenix.cor)
trojan.phoenix.cor.df$description <- rownames(trojan.phoenix.cor.df)
trojan.phoenix.cor.df <- melt(zeus.cor.df)

trojan.phoenix.cor

gg <- ggplot(trojan.phoenix.df, aes(x=ym, y=freq, group=description))
gg <- gg + geom_line(aes(color=description))
gg <- gg + facet_wrap(~description,ncol=1)
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
                 legend.position="none")
gg
