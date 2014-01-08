Title: Data Exploration of a publicly available dataset (in R)
Date: 2014-01-06 12:00:00
Category: dataviz
Status: draft
Tags: book, blog, R, python, ipython, pandas
Slug: data-exploration-in-r
Author: Bob Rudis (@hrbrmstr)

<style>
.deirfig:hover {
	cursor:ne-resize;
	opacity:0.4;
}
</style>
[ClickSecurity](http://www.clicksecurity.com) has been doing a `#spiffy` job spreading the security data science love with there [data hacking series](http://www.clicksecurity.com/blog/engaging-the-security-community-with-data-hacking-project/). They're using the [Python data science stack](http://datacommunitydc.org/blog/2013/07/python-for-data-analysis-the-landscape-of-tutorials/) and using [iPython notebooks](http://ipython.org/notebook.html) for their work and I felt compelled to reproduce at least one of their examples in [R](http://www.r-project.org/). Jay & I used Chapter 3 in our [upcoming book](http://amzn.to/ddsbook) to show the similarities and differences between Python (pandas) and R. That chapter provides far more exposition, but this post should prove to be an equally good cross-reference between the two analytics environments.

So, what follows is an R version of ClickSecurity's [Data Exploration of a publicly available dataset](http://nbviewer.ipython.org/github/ClickSecurity/data_hacking/blob/master/mdl_exploration/MDL_Data_Exploration.ipynb). You'll need to have that handy to follow along with the rest of this post. If at all possible, I strongly suggest working through their post **before** following along with our example.

You can grab the full [R source file](http://datadrivensecurity.info/blog/extra/src/R/maldomains.R) as well.

###It all begins with data

I have to agree with the ClickSecurity (*CS* from now on) folk in that many data sets available on the internet are rubbish. It takes quite a bit of work to massage data into a format you can work with. Even when you get a workable data set, it may be like the [Malware Domain List](http://www.malwaredomainlist.com/) where it's _kinda_ good, but&mdash;as we'll see&mdash;still has some warts.

As the original post states, this exercise mostly exists to show how to understand what kind of data we have and then run some simple stats on the fields/values in the data. <strike>Pandas</strike> **R** will be great for that.

First, we're going to need some help from some R libraries. These will all be used throughout the code for this example. The `stringr` and `plyr` libraries give us some enhanced data munging/manipulation ability. The `MASS` library helps us with some stats work. The `data.table` library optimizes work with large data frames and the `reshape2` library help us transform the shape of our data. Finally, `ggplot2` gives us some `#spiffy` graphics tools.

	:::SLexer
	library(stringr)
	library(plyr)
	library(MASS)
	library(data.table)
	library(ggplot2)
	library(reshape2)

I grabbed the Malware Domain List from the same source the CS folks did, namely at [http://www.malwaredomainlist.com/mdlcsv.php](http://www.malwaredomainlist.com/mdlcsv.php). Since the CS folks suggested the data was in a gnarly format, I took a look at it in `bash`:

	:::BashLexer
	$ file mdl-export.csv
	mdl-export.csv: ISO-8859 text, with CRLF line terminators

Well, that's not *too* gnarily encoded (pretty much Latin-1), but it's easy enough to convert to something modern with [`iconv`](http://www.gnu.org/software/libiconv/):

	:::BashLexer
	$ iconv --to-code UTF-8 --from-code ISO-8859-15 mdl-export.csv > mdl.csv

**Note that R could have read it in the original format**. You can try it yourself by just substituting the data files used in the `read.csv()` call. I'm just following along with the crutches Python seems to need. Now, let's hoover up the data and start exploring. 

	:::SLexer
	mdl.df <- read.csv(file="mdl.csv", 
	                   col.names=c('date', 'domain', 'ip', 'reverse',
	                               'description', 'registrant', 'asn',
	                               'inactive','country'))

 First, we take a look at the overall structure of the data and peek at the start and end of the data set.

	:::SLexer
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

R uses the value `NA` to signal when data is missing so we'll need to replace all of the `'-'`'s in the source data set with `NA` values to ensure the proper functionality of many of the functions we'll be using. (We're at about `In [13]` on the CS iPython notebook for folks keeping both of them up.)

	:::SLexer
	mdl.df[mdl.df == "-"] <- NA

That will initially let us use `complete.cases()` to remove all incomplete records from our data set.

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

We'll follow the lead of the CS folks (`In [17]`) and push everything to lowercase, since nothing we're working with really is case sensitive.

	:::SLexer
	mdl.df <- data.frame(sapply(mdl.df, tolower))
	summary(mdl.df$description)

	head(summary(mdl.df$domain))

	##    uol.com.br    woyo8g.com geocities.com     y83h2.com        ipq.co 
	##           458           310           263           105            70 
	##     dnset.com 
	##            69

I haven't found an R that has the equivalent functionality of the [`tldextract`](https://github.com/john-kurkowski/tldextract) Python module, so we'll cheat and just use that module in the form of a helper script to do the domain converisons. After all, true data scientists are first and foremost pragmatists. If this were a production script, I'd've take the extra steps to do proper temporary file generation. Since it's just for me (well, us) and this post&hellip;

	:::SLexer
	# sub-optimal, but didn't feel like writing it in R
	write.table(str_extract(mdl.df$domain, perl("^[a-zA-Z0-9\\-\\._]+")),
	            file="/tmp/indomains.txt",
	            quote=FALSE,
	            col.names=FALSE,
	            row.names=FALSE)
	# grab tlds.py from https://gist.github.com/hrbrmstr/8275775
	system("tlds.py", ignore.stdout=TRUE)
	mdl.df$domain <- factor(scan(file="/tmp/outdomains.txt", 
	                             what=character(), 
	                             quiet=TRUE))

R is a bit more formal about data types than Python is, so we'll convert the `inactive` and `country` columns before correlating them.

	:::SLexer
	mdl.df$inactive <- as.numeric(mdl.df$inactive)
	mdl.df$country <- as.numeric(mdl.df$country)
    
	cor(mdl.df$inactive, mdl.df$country)

	## [1] 1

I didn't feel like making an R package version of ClickSecurity's `g_test` library, so I just made `gtest()` and `highest.gtest.scores()` functions {[ref](http://en.wikipedia.org/wiki/G_test)} along with a helper `gtest.plot()` charting function.

	:::SLexer
	# gtest() related to chi-squared, multinomial and Fisher's exact test
	# see the ClickSecuity library for caveats to the whole process, however
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
	#' @param min.volume for some data you only want to see values with reasonable volume
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

We can use `highest.gtest.scores()` to see how various exploits are related to their associated source ASN and then the result to visualize whether exploits are highly correlated to particular ASNs. I *really* hate stacked bar charts, but, if that's what Python folks have to live with, I can go data vis slumming for a while `#grin`. Note that most plots are selectable to bring up a standalone version which may be larger and definitely easier to scale up and save out.

Start with the "top 5" malware/ASN&hellip;

	:::SLexer
	top5 <- highest.gtest.scores(mdl.df$description, mdl.df$asn, 5, 5)
	gtest.plot(top5, "ASN", "Expected")

<a href="/blog/images/2014/01/explore/fig01.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig01.svg" style="max-width:100%" class="deirfig"/></a>

Then take a look at the "bottom 7" malware/ASN&hellip;

	:::SLexer
	bottom7 <- highest.gtest.scores(mdl.df$description, mdl.df$asn, 7, 20, TRUE, 500)
	gtest.plot(bottom7, "ASN", "Expected")

<a href="/blog/images/2014/01/explore/fig02.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig02.svg" style="max-width:100%" class="deirfig"/></a>

And, finish by looking at the "top 5" malware/domain&hellip;

	:::SLexer
	top5.dom <- highest.gtest.scores(mdl.df$description, mdl.df$domain, 5)
	gtest.plot(top5.dom, "Domain", "Expected")

<a href="/blog/images/2014/01/explore/fig03.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig03.svg" style="max-width:100%" class="deirfig"/></a>

If you take a look at the `gtest.plot()` function, it shows the pattern Jay &amp; I both like to follow when crafting `ggplot2` graphics: 

- build a base plot object with the main data set/plot elements
- add the `geom`'s (the actual layers being plotted) in the order needed
- add any `facet`s (see further down in the post)
- incorporate `scale` colors and other `theme` elements
- finish the theme formatting
- display or save the graphic

as it makes it *way* easier to modify/tweak/refine them. `gest.plot()` also returns the `ggplot` object, so you can further manipulate/use the chart.

Following the lead of the CS example at `In [53]`, we drill down on one particular exploit, namely `trojan banker`s.

	:::SLexer
	# drilling down to one particluar exploit
	banker <- mdl.df[mdl.df$description == "trojan banker",]
	banker.gt <- highest.gtest.scores(banker$description, banker$domain, N=5)
	banker.gt[,c(1:3)]

	## 1  trojan banker            uol.com.br   361
	## 2  trojan banker dominiotemporario.com    14
	## 3  trojan banker           tempsite.ws    10
	## 4  trojan banker            hpg.com.br     9
	## 5  trojan banker           feevida.com     7
	## 6  trojan banker         avisosphp.com     6
	## 7  trojan banker      shopbrand.com.br     6
	## 8  trojan banker            hotmail.ru     5
	## 9  trojan banker       modulosnovs.com     5
	## 10 trojan banker  sarahbrightman.co.uk     5

So at this point the CS post switches gears, and looks at date range, volume over time, etc. we can do date conversion equally as simply in R and I think it's more straightforward to do aggregations in R, but I'm biased.

	:::SLexer
	# what do we have to work with string-format-wise?
	head(as.character(mdl.df$date))

	## [1] "2009/01/01_10:00" "2009/01/01_10:00" "2009/01/01_10:00"
	## [4] "2009/01/02_00:00" "2009/01/03_00:00" "2009/01/03_00:00"

	# underscores...in dates...yeah...in what universe?
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

<a href="/blog/images/2014/01/explore/fig04.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig04.svg" style="max-width:100%" class="deirfig"/></a>

Total volume is easy peasy as well:

	:::SLexer
	# if you already haven't notices, count() is wicked-cool
	extract.total <- count(mdl.df, vars=c("ym"))

	gg <- ggplot(extract.total, aes(x=ym, y=freq, group=NA))
	gg <- gg + geom_line()
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1),
	                 legend.position="none")
	gg

<a href="/blog/images/2014/01/explore/fig05.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig05.svg" style="max-width:100%" class="deirfig"/></a>

At this point, I probably would have stopped working with the data set. It's clear something is amiss and that the data set stopped being usable sometime in 2012. However, we press on soley to show the parallels between `pandas` and R.

This next figure is a time series correlation plot. There are &hellip;[issues](http://empslocal.ex.ac.uk/people/staff/dbs202/cat/stats/corr.html)&hellip;with time series correations that are not addressed in the CS post. A *ton* of assumptions are being made by the CS folks, but those assumptions started many code blocks ago, so we'll forge ahead with blinders on and see what we come up with.

Let's work with the top 20 pieces of malware and see what they have in common. We have to do a bit more reformatting and data crunching (steps that the `pandas` `corr()` function hides from us).

	:::SLexer
	top20 <- count(mdl.df,vars=c("ym","description"))
	top20 <- top20[top20$description %in% head(desc.tot.df$description,20),]
	# dcast() will take our "long" data frame and make a "wide" one
	# examine it before/after to see the difference
	top20 <- dcast(ym~description, data=top20)
	top20$ym <- as.numeric(factor(top20$ym))

	top20.cor <- cor(top20[,-1], use="pairwise.complete.obs")
	top20.cor.df <- data.frame(top20.cor)
	top20.cor.df$description <- rownames(top20.cor.df)
	# melt() takes our wide data frame and makes it long again, primarily
	# so that ggplot() can use the values as group/factor elements
	top20.cor.df <- melt(top20.cor.df)

I should have spent more time on breaks and colors (I just tried to match the CS graphic without going overboard), but it shows how to produce a similar graphic as `In [41]` does. I also think that "showing the work" adds a bit of transparencey that `pandas` masks.

	:::SLexer
	gg <- ggplot(top20.cor.df, aes(x=description, y=variable))
	gg <- gg + geom_tile(aes(fill=value), color="#7f7f7f")
	gg <- gg + scale_fill_gradient(limits=range(top20.cor.df$value,na.rm=TRUE),
	                               low="#EDF8FB",high="#005824",na.value="white")
	gg <- gg + labs(x="", y="")
	gg <- gg + theme_bw()
	gg <- gg + theme(axis.text.x=element_text(angle = 90, vjust = 0.5, hjust=1))
	gg 

<a href="/blog/images/2014/01/explore/fig06.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig06.svg" style="max-width:100%" class="deirfig"/></a>

We can dive into specific correlations (note, that I downloaded the malware data well after the CS post went live, so the data isn't 1:1 and neither are the correlatons).

ZeuS v1 correlation:

	:::SLexer
	zeus <- count(mdl.df,vars=c("ym","description"))
	zeus <- zeus[zeus$description %in% c('zeus v1 trojan','zeus v1 config file','zeus v1 drop zone'),]
	zeus.df <- zeus
	zeus <- dcast(ym~description, data=zeus)

	zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
	zeus.cor.df <- data.frame(zeus.cor)
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

<a href="/blog/images/2014/01/explore/fig07.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig07.svg" style="max-width:100%" class="deirfig"/></a>

ZeuS v2 correlation:

	:::SLexer
	zeus <- count(mdl.df,vars=c("ym","description"))
	zeus <- zeus[zeus$description %in% c('zeus v2 trojan','zeus v2 config file','zeus v2 drop zone'),]
	zeus.df <- zeus
	zeus <- dcast(ym~description, data=zeus)

	zeus.cor <- cor(zeus[,-1], use="pairwise.complete.obs")
	zeus.cor.df <- data.frame(zeus.cor)
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

<a href="/blog/images/2014/01/explore/fig08.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig08.svg" style="max-width:100%" class="deirfig"/></a>

Trojan and Phoenix Exploit Kit correlation:

	:::SLexer
	trojan.phoenix <- count(mdl.df,vars=c("ym","description"))
	trojan.phoenix <- trojan.phoenix[trojan.phoenix$description %in% c('trojan','phoenix exploit kit'),]
	trojan.phoenix.df <- trojan.phoenix
	trojan.phoenix <- dcast(ym~description, data=trojan.phoenix)

	trojan.phoenix.cor <- cor(trojan.phoenix[,-1], use="pairwise.complete.obs")
	trojan.phoenix.cor.df <- data.frame(trojan.phoenix.cor)
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

<a href="/blog/images/2014/01/explore/fig09.svg" target="_blank"><img src="/blog/images/2014/01/explore/fig09.svg" style="max-width:100%" class="deirfig"/></a>

###Conclusions

So, this exercise was an exploration of the dataset and a display of how to perform the CS `pandas` analysis in R. As the ClickSecurity post indicated, at this point we have a good idea about what's in the dataset, what cleanup issues we might have and the overall quality of the dataset. We've run some simple correlative statistics and produced some nice plots. Most importantly we should have a good feel for whether this dataset is going to suit our needs for whatever use case we may have.
