library(stringr)
library(plyr)
library(MASS)
library(data.table)
library(ggplot2)
library(reshape2)

mdl.df <- read.csv(file="mdl.csv", 
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

# sub-optimal, but didn't feel like writing it in R
write.table(str_extract(mdl.df$domain, perl("^[a-zA-Z0-9\\-\\._]+")),
            file="/tmp/indomains.txt",
            quote=FALSE,
            col.names=FALSE,
            row.names=FALSE)
# get tlds.py from https://gist.github.com/hrbrmstr/8275775
system("tlds.py", ignore.stdout=TRUE)
mdl.df$domain <- factor(scan(file="/tmp/outdomains.txt", 
                             what=character(), 
                             quiet=TRUE))

mdl.df$inactive <- as.numeric(mdl.df$inactive)
mdl.df$country <- as.numeric(mdl.df$country)

cor(mdl.df$inactive, mdl.df$country)

# gtest() related to chi-squared, multinomial and Fisher's exact test
gtest <- function(count, expected) {
  if (count == 0) {
    return(0)
  } else {
    return(2*count*log(count/expected))
  }
}

desc.tot <- table(mdl.df$description)
desc.tot.df <- data.frame(sort(desc.tot,decreasing=TRUE))
desc.tot.df$description <- rownames(desc.tot.df)
row.names(desc.tot.df) <- NULL
colnames(desc.tot.df) <- c("freq","description")

asn.cats <- length(unique(mdl.df$asn))
desc.asn.expected <- desc.tot / asn.cats
desc.asn.expected.df <- as.data.frame(desc.asn.expected)
colnames(desc.asn.expected.df) <- c("description","expected")

desc.asn.ct <- table(mdl.df$description, mdl.df$asn) 
desc.asn.ct.df <- as.data.frame.matrix(desc.asn.ct)
desc.asn.ct.df$description <- rownames(desc.asn.ct.df)
desc.asn.ct.df <- data.table(desc.asn.ct.df)
desc.asn.ct.sum <- count(mdl.df,vars=c("description","asn"))

desc.asn.ct.sum <- join(desc.asn.ct.sum, desc.asn.expected.df)
desc.asn.ct.sum$actual <- mapply(gtest, desc.asn.ct.sum$freq, desc.asn.ct.sum$expected)

desc.asn.ct.sum$total.freq <- sapply(desc.asn.ct.sum$description, function(x) {
desc.tot.df[desc.tot.df$description == x,]$freq
})

tmp <- desc.asn.ct.sum[order(-desc.asn.ct.sum$actual),]
desc.asn.expected.df$actual <- sapply(desc.asn.expected.df$description, function(x) { 
max(tmp[tmp$description == x,]$actual)
})

desc.asn.expected.df$total.freq <- sapply(desc.asn.expected.df$description, function(x) {
desc.tot.df[desc.tot.df$description == x,]$freq
})

top5 <- head(desc.asn.expected.df[order(-desc.asn.expected.df$actual),],5)
exp.v.asn <- desc.asn.ct.sum[(desc.asn.ct.sum$description %in% top5$description),]
exp.v.asn <- exp.v.asn[exp.v.asn$actual > exp.v.asn$expected,]
exp.v.asn <- ldply(top5$description, function(x) {
a <- exp.v.asn[exp.v.asn$description==x,]
head(a[order(-a$actual),],5)
})

gg <- ggplot(data=exp.v.asn, aes(x=asn, y=freq))
gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
gg

# bottom 7 malware v asn

tmp <- desc.asn.expected.df[desc.asn.expected.df$total.freq > 500,]
bottom7 <- tail(tmp[order(-tmp$actual),],7)
exp.v.asn <- desc.asn.ct.sum[(desc.asn.ct.sum$description %in% bottom7$description),]
exp.v.asn <- exp.v.asn[exp.v.asn$actual > exp.v.asn$expected,]
exp.v.asn <- ldply(bottom7$description, function(x) {
  a <- exp.v.asn[exp.v.asn$description==x,]
  head(a[order(-a$actual),],20)
})

gg <- ggplot(data=exp.v.asn, aes(x=asn, y=freq))
gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
gg

# top 5 malware v domain

domain.cats <- length(unique(mdl.df$domain))
desc.dom.expected <- desc.tot / domain.cats
desc.dom.expected.df <- as.data.frame(desc.dom.expected)
colnames(desc.dom.expected.df) <- c("description","expected")

desc.dom.ct <- table(mdl.df$description, mdl.df$domain) 
desc.dom.ct.df <- as.data.frame.matrix(desc.dom.ct)
desc.dom.ct.df$description <- rownames(desc.dom.ct.df)
desc.dom.ct.df <- data.table(desc.dom.ct.df)
desc.dom.ct.sum <- count(mdl.df,vars=c("description","domain"))

desc.dom.ct.sum <- join(desc.dom.ct.sum, desc.dom.expected.df)
desc.dom.ct.sum$actual <- mapply(gtest, desc.dom.ct.sum$freq, desc.dom.ct.sum$expected)

desc.dom.ct.sum$total.freq <- sapply(desc.dom.ct.sum$description, function(x) {
  desc.tot.df[desc.tot.df$description == x,]$freq
})

tmp <- desc.dom.ct.sum[order(-desc.dom.ct.sum$actual),]
desc.dom.expected.df$actual <- sapply(desc.dom.expected.df$description, function(x) { 
  max(tmp[tmp$description == x,]$actual)
})

desc.dom.expected.df$total.freq <- sapply(desc.dom.expected.df$description, function(x) {
  desc.tot.df[desc.tot.df$description == x,]$freq
})

top5 <- head(desc.dom.expected.df[order(-desc.dom.expected.df$actual),],5)
exp.v.dom <- desc.dom.ct.sum[(desc.dom.ct.sum$description %in% top5$description),]
exp.v.dom <- ldply(top5$description, function(x) {
  a <- exp.v.dom[exp.v.dom$description==x,]
  head(a[order(-a$actual),],20)
})

gg <- ggplot(data=exp.v.dom, aes(x=domain, y=freq))
gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
gg <- gg + theme_bw()
gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
gg

exp.v.dom[exp.v.dom$description == "trojan banker",c("domain","freq")]


head(as.character(mdl.df$date))
mdl.df$date <- as.POSIXct(as.character(mdl.df$date),format="%Y/%m/%d_%H:%M")
mdl.df$ym <- strftime(mdl.df$date, format="%Y-%m")

# hack to sum by year & month
extract <- count(mdl.df,vars=c("ym","description"))
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
# gg <- gg + scale_fill_gradient2(limits=range(top20.cor.df$value,na.rm=TRUE),
#                                 low="#06072b", mid="orange", high="red", na.value="white")
# gg <- gg + scale_fill_gradient(limits=range(top20.cor.df$value,na.rm=TRUE),
#                                low="#EDF8FB",high="#005824",na.value="white")
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
