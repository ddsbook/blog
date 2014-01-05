Title: Data Exploration of a publicly available dataset (in R)
Date: 2014-01-06 12:00:00
Category: dataviz
Status: draft
Tags: book, blog, R, python, ipython, pandas
Slug: data-exploration-in-r
Author: Bob Rudis (@hrbrmstr)

ClickSecurity has been doing a #spiffy job spreading the security data science love with there [data hacking series](http://www.clicksecurity.com/blog/engaging-the-security-community-with-data-hacking-project/). They're using the [Python data science stack](http://datacommunitydc.org/blog/2013/07/python-for-data-analysis-the-landscape-of-tutorials/) and using [iPython notebooks](http://ipython.org/notebook.html) for their work and I felt compelled to reproduce at least one of their examples in [R](http://www.r-project.org/). So, what follows is an R version of ClickSecurity's [Data Exploration of a publicly available dataset](http://nbviewer.ipython.org/github/ClickSecurity/data_hacking/blob/master/mdl_exploration/MDL_Data_Exploration.ipynb). You'll need to have that handy to follow along with the rest of this post. If at all possible, I strongly suggest working through their post **before** following along with our example.

####It all beings with data

I have to agree with the ClickSecurity (*CS* from now on) folk in that most data sets available on the internet are rubbish. It takes quite a bit of work to massage data into a format you can work with. Even when you get a workable data set, it may be like the [Malware Domain List](http://www.malwaredomainlist.com/) where it's _kinda_ good, but still has some warts.

As the original post states, this exercise is mostly for us to understand what kind of data we have and then run some simple stats on the fields/values in the data. <strike>Pandas</strike> R will be great for that.

First, we're going to need some help from some R libraries. These will all be used throughout the code for this example. The `stringr` and `plyr` libraries give us some enhanced data manipulation ability. The `MASS` library helps us with some stats. The `data.table` and `reshape2` libraries help us work with data in different ways than `stringr` and `plyr` and `ggplot2` give us some #spiffy graphics tools.

	:::SLexer
	library(stringr)
	library(plyr)
	library(MASS)
	library(data.table)
	library(ggplot2)
	library(reshape2)

I grabbed the Malware Domain List from the same source the CS folks did, namely at [http://www.malwaredomainlist.com/mdlcsv.php](http://www.malwaredomainlist.com/mdlcsv.php). Since the CS folks suggested the data was in a gnarly format, I took a look at it in `bash`:

	$ file mdl-export.csv
	mdl-export.csv: ISO-8859 text, with CRLF line terminators

Well, it is truly gnarily encoded, but it's easy enough to convert with `iconv`:

	$ iconv -t UTF-8 -f ISO-8859-15 mdl-export.csv > mdl.csv

Now that R can read it, let's read the data in and start exploring. 

	:::SLexer
	mdl.df <- read.csv(file="~/Desktop/mdl.csv", 
	                   col.names=c('date', 'domain', 'ip', 'reverse',
	                               'description', 'registrant', 'asn',
	                               'inactive','country'))

	# take a look at the structure of the data
	str(mdl.df)


	## 'data.frame':    31015 obs. of  9 variables:
	##  $ date       : Factor w/ 6892 levels "2009/01/01_10:00",..: 1 1 1 2 3 3 4 4 5 5 ...
	##  $ domain     : Factor w/ 18342 levels ".s3.amazonaws.com",..: 15880 17246 17852 5181 7239 7858 7271 9309 1741 12194 ...
	##  $ ip         : Factor w/ 9337 levels "100.42.49.200",..: 6057 5464 1879 5107 5972 3405 5971 7578 5745 6763 ...
	##  $ reverse    : Factor w/ 8788 levels ".","*.blogs.old.sapo.pt.",..: 3811 2625 6743 5982 1674 899 1673 4334 792 7558 ...
	##  $ description: Factor w/ 1300 levels "- fake scanner",..: 122 834 122 59 316 566 566 310 835 835 ...
	##  $ registrant : Factor w/ 10909 levels ""," - "," / ",..: 743 986 10633 3454 8014 8014 8014 9457 7455 10044 ...
	##  $ asn        : int  21844 11798 8358 36752 23136 10316 23136 16265 22576 24940 ...
	##  $ inactive   : int  2 2 2 2 2 2 2 2 2 2 ...
	##  $ country    : int  2 2 2 2 2 2 2 2 2 2 ...


	# examine the start and end of the data
	head(mdl.df)

	##               date          domain             ip
	## 1 2009/01/01_10:00 thick-click.com    74.52.59.66
	## 2 2009/01/01_10:00       webfo.biz   69.89.27.211
	## 3 2009/01/01_10:00        xtipp.hu   195.70.48.68
	## 4 2009/01/02_00:00       epeiy.com  68.180.151.74
	## 5 2009/01/03_00:00   har5launo.com 74.213.167.191
	## 6 2009/01/03_00:00   ihgcxianj.com 216.55.163.216
	##                             reverse                           description
	## 1           gator126.hostgator.com. compromised site/redirects to mebroot
	## 2               box211.bluehost.com                                   rfi
	## 3                 s5.mediacenter.hu compromised site/redirects to mebroot
	## 4         p2p.geo.vip.sp1.yahoo.com             backdoor.win32.keystart.m
	## 5   74-213-167-191.ultrahosting.com                      exploits/mebroot
	## 6 216-55-163-216.dedicated.abac.net                    mebroot calls home
	##                                   registrant   asn inactive country
	## 1                    alvin slap30_1@juno.com 21844        2       2
	## 2 anthony stebbing stebbing@omen-designs.com 11798        2       2
	## 3                            wolf center kft  8358        2       2
	## 4                            epeiy@yahoo.com 36752        2       2
	## 5         prokofyev yaroslav weksya@gmail.ru 23136        2       2
	## 6         prokofyev yaroslav weksya@gmail.ru 10316        2       2

	tail(mdl.df)

	##                   date                 domain             ip
	## 31010 2013/12/21_23:07         prpservices.in  216.45.55.181
	## 31011 2013/12/21_23:07       schliessmeyer.de  212.223.22.42
	## 31012 2013/12/21_23:07 alternativakademin.com   72.29.66.179
	## 31013 2013/12/25_00:10         evitunisie.com 212.83.151.246
	## 31014 2013/12/29_17:53       aippnetworks.com  195.74.65.196
	## 31015 2013/12/29_17:53        micropure.co.in 173.254.28.141
	##                                   reverse            description
	## 31010              congo.serversfarm.com.     (compromised site)
	## 31011                      helm03.inl.de.     (compromised site)
	## 31012                manu10.manufrog.com.     (compromised site)
	## 31013 212-83-151-246.rev.poneytelecom.eu. win32/trojan.poisonivy
	## 31014          195-74-65-196.ip.aleto.nl.              to trojan
	## 31015               just141.justhost.com.                  shell
	##                                           registrant   asn inactive
	## 31010      rajneesh dawar / rajneesh_dawar@yahoo.com 29761        1
	## 31011                     mail@kunststoffboerse24.de  8741        1
	## 31012                email........: kiave03@yahoo.se 33182        1
	## 31013 technet tunisie / direction@technettunisie.net 12876        2
	## 31014          registrant sloopymikegyamfi@gmail.com 25459        1
	## 31015                amit / india.amit0099@gmail.com 46606        1
	##       country
	## 31010       1
	## 31011       1
	## 31012       1
	## 31013       2
	## 31014       1
	## 31015       1

R uses the value `NA` to signal when data is missing so we'll need to replace all of the `'-'`'s in the source data set with `NA` values to ensure the sane functionality of many of the functions we'll be using.

	:::SLexer
	mdl.df[mdl.df == "-"] = NA

That will initially let us use `complete.cases()` to remove all incomplete records.

	:::SLexer
	mdl.df <- mdl.df[complete.cases(mdl.df),]

	# re-explore the data
	str(mdl.df)

	## 'data.frame':    31005 obs. of  9 variables:
	##  $ date       : Factor w/ 6892 levels "2009/01/01_10:00",..: 1 1 1 2 3 3 4 4 5 5 ...
	##  $ domain     : Factor w/ 18342 levels ".s3.amazonaws.com",..: 15880 17246 17852 5181 7239 7858 7271 9309 1741 12194 ...
	##  $ ip         : Factor w/ 9337 levels "100.42.49.200",..: 6057 5464 1879 5107 5972 3405 5971 7578 5745 6763 ...
	##  $ reverse    : Factor w/ 8788 levels ".","*.blogs.old.sapo.pt.",..: 3811 2625 6743 5982 1674 899 1673 4334 792 7558 ...
	##  $ description: Factor w/ 1300 levels "- fake scanner",..: 122 834 122 59 316 566 566 310 835 835 ...
	##  $ registrant : Factor w/ 10909 levels ""," - "," / ",..: 743 986 10633 3454 8014 8014 8014 9457 7455 10044 ...
	##  $ asn        : int  21844 11798 8358 36752 23136 10316 23136 16265 22576 24940 ...
	##  $ inactive   : int  2 2 2 2 2 2 2 2 2 2 ...
	##  $ country    : int  2 2 2 2 2 2 2 2 2 2 ...

	head(mdl.df$description)

	## [1] compromised site/redirects to mebroot
	## [2] rfi                                  
	## [3] compromised site/redirects to mebroot
	## [4] backdoor.win32.keystart.m            
	## [5] exploits/mebroot                     
	## [6] mebroot calls home                   
	## 1300 Levels: - fake scanner - trojan fakesmoke ... zues trojan

	tail(mdl.df$description)

	## [1] (compromised site)     (compromised site)     (compromised site)    
	## [4] win32/trojan.poisonivy to trojan              shell                 
	## 1300 Levels: - fake scanner - trojan fakesmoke ... zues trojan

	summary(mdl.df$description)

	##                                               trojan 
	##                                                 3674 
	##                                                  rfi 
	##                                                 1600 
	##                                  zeus v1 config file 
	##                                                 1322 
	##                                              fake av 
	##                                                 1164 
	##                                blackhole exploit kit 
	##                                                 1079 
	##                                  zeus v2 config file 
	##                                                  974 
	##                                redirects to exploits 
	##                                                  916 
	##                                       zeus v1 trojan 
	##                                                  900
	... 

We'll follow the lead of the CS folks and push everything to lowercase since nothing we're working with really is case sensitive.

	:::SLexer
	mdl.df <- data.frame(sapply(mdl.df, tolower))
	summary(mdl.df$description)

	head(summary(mdl.df$domain))

	##    uol.com.br    woyo8g.com geocities.com     y83h2.com        ipq.co 
	##           458           310           263           105            70 
	##     dnset.com 
	##            69

R doesn't have an library that has the equivalent functionality of the `tldextract` Python module, so we'll cheat and just use that module in the form of a helper script to do the domain converisons. After all, true data scientists are first and foremost pragmatists.

	:::SLexer
	# sub-optimal, but didn't feel like writing it in R
	write.table(str_extract(mdl.df$domain, perl("^[a-zA-Z0-9\\-\\._]+")),
	            file="/tmp/indomains.txt",
	            quote=FALSE,
	            col.names=FALSE,
	            row.names=FALSE)
	system("~/Desktop/tlds.py", ignore.stdout=TRUE)
	mdl.df$domain <- factor(scan(file="/tmp/outdomains.txt", 
	                             what=character(), 
	                             quiet=TRUE))


R is a bit more sensitive about data types than Python is, so we'll convert the `inactive` and `country` columns before correlating them.

	:::SLexer
	mdl.df$inactive <- as.numeric(mdl.df$inactive)
	mdl.df$country <- as.numeric(mdl.df$country)
    
	cor(mdl.df$inactive, mdl.df$country)

	## [1] 1


I didn't feel like creating an `g_test` library, so I just made a `gtest` function {[ref](http://en.wikipedia.org/wiki/G_test)} and used R code outright each time the CS post relied on `g_test.highest_gtest_scores()`. In reality, after the second use I should have made it a function, but it serves as a great introduction to the `*apply()`'s for R n00bs.

	:::SLexer
	# gtest() related to chi-squared, multinomial and Fisher's exact test
	gtest <- function(count, expected) {
	  if (count == 0) {
	    return(0)
	  } else {
	    return(2*count*log(count/expected))
	  }
	}


The premise here is to generate a maximum likelihood statistical significance value for each salient set of values. We first generate a `table` of the malware `description` field.

	:::SLexer
	desc.tot <- table(mdl.df$description)
	desc.tot.df <- data.frame(sort(desc.tot,decreasing=TRUE))
	desc.tot.df$description <- rownames(desc.tot.df)
	row.names(desc.tot.df) <- NULL
	colnames(desc.tot.df) <- c("freq","description")

We then generate expected counts per assuming a uniform distribution. I'm not convinced that's an appropriate assumption, but we're duplicating/replicating an example, not enhancing an example, so let's assume a uniform distribution of malware across the ASNs.

	:::SLexer
	asn.cats <- length(unique(mdl.df$asn))
	desc.asn.expected <- desc.tot / asn.cats
	desc.asn.expected.df <- as.data.frame(desc.asn.expected)
	colnames(desc.asn.expected.df) <- c("description","expected")

Now we build a [contingency table](http://en.wikipedia.org/wiki/Contingency_table) between the malware `description` and `asn` fields and then generate an aggregated data frame based on those two columns.

	:::SLexer
	desc.asn.ct <- table(mdl.df$description, mdl.df$asn) 
	desc.asn.ct.df <- as.data.frame.matrix(desc.asn.ct)
	desc.asn.ct.df$description <- rownames(desc.asn.ct.df)
	desc.asn.ct.df <- data.table(desc.asn.ct.df)
	desc.asn.ct.sum <- count(mdl.df,vars=c("description","asn"))

We now add some columns to the summary we've built, letting us have both `expected` and `actual` values at hand. I *highly* recommend reviewing the CS [data hacking](https://github.com/ClickSecurity/data_hacking/blob/master/data_hacking/simple_stats/simple_stats.py) Python code since it has some additional comments behind the thought process.

	:::SLexer
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

With the base summary data generated, we now extract the top 5 malware strains and compare the expected values vs actual values.

	:::SLexer
	top5 <- head(desc.asn.expected.df[order(-desc.asn.expected.df$actual),],5)
	exp.v.asn <- desc.asn.ct.sum[(desc.asn.ct.sum$description %in% top5$description),]
	exp.v.asn <- exp.v.asn[exp.v.asn$actual > exp.v.asn$expected,]
	exp.v.asn <- ldply(top5$description, function(x) {
	  a <- exp.v.asn[exp.v.asn$description==x,]
	  head(a[order(-a$actual),],5)
	})

Then we plot them. I *really* hate stacked bar charts, but, if that's what Python folks have to live with, I can go data vis slumming for a while #grin.

	:::SLexer
	gg <- ggplot(data=exp.v.asn, aes(x=asn, y=freq))
	gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
	gg

<img src="/blog/images/2014/01/explore/fig01.svg" width="630"/>

We then do the same for the bottom 7...

	:::SLexer
	# bottom 7 malware v asn

	tmp <- desc.asn.expected.df[desc.asn.expected.df$total.freq > 500,]
	bottom7 <- tail(tmp[order(-tmp$actual),],7)
	exp.v.asn <- desc.asn.ct.sum[(desc.asn.ct.sum$description %in% bottom7$description),]
	exp.v.asn <- exp.v.asn[exp.v.asn$actual > exp.v.asn$expected,]
	exp.v.asn <- ldply(bottom7$description, function(x) {
	  a <- exp.v.asn[exp.v.asn$description==x,]
	  head(a[order(-a$actual),],20)
	})

	:::SLexer
	gg <- ggplot(data=exp.v.asn, aes(x=asn, y=freq))
	gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
	gg

<img src="/blog/images/2014/01/explore/fig02.svg" width="630"/>

We lather/rinse/repeat for `malware` ~ `domain`:

	:::SLexer
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

	:::SLexer
	gg <- ggplot(data=exp.v.dom, aes(x=domain, y=freq))
	gg <- gg + geom_bar(stat="identity", position="stack", aes(fill=description))
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
	gg

<img src="/blog/images/2014/01/explore/fig03.svg" width="630"/>

Following the lead of the CS example at `In [53]`, we drill down on one particular exploit, namely `trojan banker`s.

	:::SLexer
	exp.v.dom[exp.v.dom$description == "trojan banker", c("domain","freq")]

	##                      domain freq
	## 1                uol.com.br  361
	## 2     dominiotemporario.com   14
	## 3               tempsite.ws   10
	## 4                hpg.com.br    9
	## 5               feevida.com    7
	## 6             avisosphp.com    6
	## 7          shopbrand.com.br    6
	## 8                hotmail.ru    5
	## 9           modulosnovs.com    5
	## 10     sarahbrightman.co.uk    5
	## 11     araccconsultoria.net    4
	## 12      ascessoriaaracc.com    4
	## 13 componentenetempresa.com    4
	## 14     hospedagemdesites.ws    4
	## 15    webpresencamaster.com    4
	## 16             classjar.com    3
	## 17         freewebhostx.com    3
	## 18                 front.ru    3
	## 19              krovatka.su    3
	## 20           lantorpedo.com    361

So at this point the CS post switches gears, and looks at date range, volume over time, etc. we can do date conversion equally as simply in R and I think it's more straightforward to do aggregations in R, but I'm biased.

	:::SLexer
	head(as.character(mdl.df$date))

	## [1] "2009/01/01_10:00" "2009/01/01_10:00" "2009/01/01_10:00"
	## [4] "2009/01/02_00:00" "2009/01/03_00:00" "2009/01/03_00:00"

	mdl.df$date <- as.POSIXct(as.character(mdl.df$date),format="%Y/%m/%d_%H:%M")
	mdl.df$ym <- strftime(mdl.df$date, format="%Y-%m")

	# sum by year & month
	extract <- count(mdl.df,vars=c("ym","description"))
	extract <- extract[extract$description %in% head(desc.tot.df$description,7),]

I draw the line (heh) at gnarly line grahps, so we choose to facet them here vs munge them all into one mess of spaghetti.

	:::SLexer
	gg <- ggplot(extract, aes(x=ym, y=freq, group=description))
	gg <- gg + geom_line(aes(color=description))
	gg <- gg + facet_wrap(~description,ncol=1)
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<img src="/blog/images/2014/01/explore/fig04.svg" width="630"/>

Total volume is easy peasy as well:

	:::SLexer
	extract.total <- count(mdl.df, vars=c("ym"))

	gg <- ggplot(extract.total, aes(x=ym, y=freq, group=NA))
	gg <- gg + geom_line()
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<img src="/blog/images/2014/01/explore/fig05.svg" width="630"/>

At this point, I probably would have stopped working with the data set. It's clear something is amiss and that the data set stopped being usable sometime in 2012. However, we press on soley to show the parallels.

This next figure is a time series correlation plot. There are ...[issues](http://empslocal.ex.ac.uk/people/staff/dbs202/cat/stats/corr.html)...with time series correations that are not addressed in the CS post. A *ton* of assumptions are being made by the CS folks, but they started many code blocks previous, so we'll forge ahead with blinders on and see what we come up with.

Let's work with the top 20 pieces of malware and see what they have in common. We have to do a bit more reformatting and data crunching (steps that the `pandas` `corr()` function hides from us).

	:::SLexer
	top20 <- count(mdl.df,vars=c("ym","description"))
	top20 <- top20[top20$description %in% head(desc.tot.df$description,20),]
	top20 <- dcast(ym~description, data=top20)
	top20$ym <- as.numeric(factor(top20$ym))

	top20.cor <- cor(top20[,-1], use="pairwise.complete.obs")
	top20.cor.df = data.frame(top20.cor)
	top20.cor.df$description <- rownames(top20.cor.df)
	top20.cor.df <- melt(top20.cor.df)

I should have spent more time on breaks and colors, but it shows how to produce a similar graphic as `In [41]` does. I also think that "showing the work" adds a bit of transparencey that `pandas` masks.

	:::SLexer
	gg <- ggplot(top20.cor.df, aes(x=description, y=variable))
	gg <- gg + geom_tile(aes(fill=value), color="#7f7f7f")
	gg <- gg + scale_fill_gradient(limits=range(top20.cor.df$value,na.rm=TRUE),
	                               low="#EDF8FB",high="#005824",na.value="white")
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
	gg 

<img src="/blog/images/2014/01/explore/fig06.svg" width="630"/>

We can dive into specific correlations (note, that I pulled the data way after the CS post went live, so the data isn't 1:1 and neither are the correlaton coefficents).

ZeuS v1 correlation:

	:::SLexer
	zeus <- count(mdl.df,vars=c("ym","description"))
	zeus <- zeus[zeus$description %in% c('zeus v1 trojan','zeus v1 config file','zeus v1 drop zone'),]
	zeus.df <- zeus
	zeus <- dcast(ym~description, data=zeus)

	zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
	zeus.cor.df = data.frame(zeus.cor)
	zeus.cor.df$description <- rownames(zeus.cor.df)
	zeus.cor.df <- melt(zeus.cor.df)

	zeus.cor

	##                     zeus v1 config file zeus v1 drop zone zeus v1 trojan
	## zeus v1 config file              1.0000            0.8151         0.9119
	## zeus v1 drop zone                0.8151            1.0000         0.7582
	## zeus v1 trojan                   0.9119            0.7582         1.0000

ZeuS v1 time series plot:

	:::SLexer
	gg <- ggplot(zeus.df, aes(x=ym, y=freq, group=description))
	gg <- gg + geom_line(aes(color=description))
	gg <- gg + facet_wrap(~description,ncol=1)
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<img src="/blog/images/2014/01/explore/fig07.svg" width="630"/>

ZeuS v2 correlation:

	:::SLexer
	zeus <- count(mdl.df,vars=c("ym","description"))
	zeus <- zeus[zeus$description %in% c('zeus v2 trojan','zeus v2 config file','zeus v2 drop zone'),]
	zeus.df <- zeus
	zeus <- dcast(ym~description, data=zeus)

	zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
	zeus.cor.df = data.frame(zeus.cor)
	zeus.cor.df$description <- rownames(zeus.cor.df)
	zeus.cor.df <- melt(zeus.cor.df)

	zeus.cor

	##                     zeus v2 config file zeus v2 drop zone zeus v2 trojan
	## zeus v2 config file              1.0000            0.7174         0.4850
	## zeus v2 drop zone                0.7174            1.0000         0.2434
	## zeus v2 trojan                   0.4850            0.2434         1.0000

ZeuS v2 time series plot:

	:::SLexer
	gg <- ggplot(zeus.df, aes(x=ym, y=freq, group=description))
	gg <- gg + geom_line(aes(color=description))
	gg <- gg + facet_wrap(~description,ncol=1)
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<img src="/blog/images/2014/01/explore/fig08.svg" width="630"/>

Trojan and Phoenix Exploit Kit correlation:

	:::SLexer
	trojan.phoenix <- count(mdl.df,vars=c("ym","description"))
	trojan.phoenix <- trojan.phoenix[trojan.phoenix$description %in% c('trojan','phoenix exploit kit'),]
	trojan.phoenix.df <- trojan.phoenix
	trojan.phoenix <- dcast(ym~description, data=trojan.phoenix)

	trojan.phoenix.cor <- cor(trojan.phoenix[,-1], use="pairwise.complete.obs")
	trojan.phoenix.cor.df = data.frame(trojan.phoenix.cor)
	trojan.phoenix.cor.df$description <- rownames(trojan.phoenix.cor.df)
	trojan.phoenix.cor.df <- melt(zeus.cor.df)

	trojan.phoenix.cor

	##                     phoenix exploit kit trojan
	## phoenix exploit kit              1.0000 0.4117
	## trojan                           0.4117 1.0000

Trojan and Phoenix Exploit Kit time series plot:

	:::SLexer
	gg <- ggplot(trojan.phoenix.df, aes(x=ym, y=freq, group=description))
	gg <- gg + geom_line(aes(color=description))
	gg <- gg + facet_wrap(~description,ncol=1)
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<img src="/blog/images/2014/01/explore/fig09.svg" width="630"/>

###Conclusions

*(complete riff of the CS post)*

So this exercise was an exploration of the dataset. At this point we have a good idea about what's in the dataset, what cleanup issues we might have and the overall quality of the dataset. We've run some simple correlative statistics and produced some nice plots. Most importantly we should have a good feel for whether this dataset is going to suite our needs for whatever use case we may have.
