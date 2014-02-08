Title: Reproducible Security Domain Research With Sucuri Darkleech Data
Date: 2014-02-08 12:00:00
Category: analysis
Tags: R, reproducible research, botnet
Slug: reproducible-research-sucuri-darkleech-data
Author: Bob Rudis (@hrbrmstr)

It's super-`#spiffy` to see organizations like [Sucuri](http://sucuri.net/) share data and insight. Since they did some great work (both in data capture and sharing of their analyses), I thought it might be fun (yes, Jay & I have a strange notion of "fun") to "show the work" in R. You should read [their post](http://blog.sucuri.net/2014/02/darkleech-bitly-com-insightful-statistics.html) first before playing along at home. We'll provide links to the data file at the end of this post.

I combined the three Darkleech bit.ly files and stuck a proper header it, which makes it much easier to handle with `read.csv()`. I also normalized all the timestamp formats (they are all "`%Y:%m:%d %H:%M:%S`" now).

	:::r
	library(plyr)
	require(RCurl)

	grantdad.URL = "https://raw.github.com/ddsbook/blog/master/data/2014/02/sucuri/grantdad.txt"
	grantdad <- read.csv(textConnection(getURL(grantdad.URL)), stringsAsFactors = FALSE, sep = "\t")
	# to factor by host
	grantdad$host <- factor(gsub("^[a-zA-Z0-9]*\\.", "", gsub("(http[s]*://|/.*$)", "", grantdad$long.url)))
	# for aggregating by minute
	grantdad$ts.min <- as.POSIXct(gsub("\\:[0-9][0-9]$", "", grantdad$ts))

I'm initially made an assumption the timestamp in the original files is the creation date+time of the short URL and that the click count is there just for convenience (neither the post nor pastebin 'splains). Looking at the `long.url` field, though, it seems that if this assumption is right, we might have an issue with the way the data was collected:

	:::r
	# show duplicate long URLs entries short link and time stamp
	g.dups <- grantdad[grantdad$long.url %in% grantdad[duplicated(grantdad$long.url),]$long.url, c(2, 3, 1)]
	g.dups[order(g.dups$bitly.link.id), ]

	##                        ts click.count bitly.link.id
	## 6431  2014-01-28 18:50:17           2       19YJNDs
	## 6433  2014-01-28 18:50:17           2       19YJNDs
	## 9812  2014-01-28 10:05:05           2       1bu6vhO
	## 9813  2014-01-28 10:05:05           2       1bu6vhO
	## 9802  2014-01-28 10:05:07          13       1bu6vyj
	## 9804  2014-01-28 10:05:07          13       1bu6vyj
	## 9442  2014-01-28 11:00:12          33       1budiYU
	## 9444  2014-01-28 11:00:12          33       1budiYU
	## 9332  2014-01-28 11:15:07           0       1bueQ57
	## 9333  2014-01-28 11:15:07           0       1bueQ57
	## 9322  2014-01-28 11:15:09           8       1bueT0T
	## 9323  2014-01-28 11:15:09           8       1bueT0T
	## 9212  2014-01-28 11:30:07          19       1bugqnt
	## 9214  2014-01-28 11:30:07          19       1bugqnt
	## 9222  2014-01-28 11:30:05           2       1bugsvy
	## 9224  2014-01-28 11:30:05           2       1bugsvy
	## 9032  2014-01-28 11:55:09           0       1buixrs
	## 9033  2014-01-28 11:55:09           0       1buixrs
	## 9020  2014-01-28 11:55:12           1       1buizPW
	## 9023  2014-01-28 11:55:12           1       1buizPW
	## 8631  2014-01-28 13:00:05           8       1bunIb1
	## 8633  2014-01-28 13:00:05           8       1bunIb1
	## 8622  2014-01-28 13:00:09           0       1bunIrx
	## 8623  2014-01-28 13:00:09           0       1bunIrx
	## 10618 2014-02-05 02:15:10           3       1c0EVcm
	## 10619 2014-02-05 02:15:10           3       1c0EVcm
	## 11672 2014-02-04 23:35:15           0       1evhUT3
	## 11675 2014-02-04 23:35:15           0       1evhUT3
	## 10796 2014-02-05 01:50:09           3       1evyC4O
	## 10797 2014-02-05 01:50:09           3       1evyC4O
	## 4400  2014-01-25 07:40:05           3       1hUgqCn
	## 4410  2014-01-25 07:40:05           3       1hUgqCn
	## 3671  2014-01-25 09:25:15           0       1hUyNHt
	## 3675  2014-01-25 09:25:15           0       1hUyNHt
	## 5490  2014-01-28 21:40:10          12       1i7jPOj
	## 5496  2014-01-28 21:40:10          12       1i7jPOj
	## 5485  2014-01-28 21:40:10           4       1i7jRFX
	## 5494  2014-01-28 21:40:10           4       1i7jRFX
	## 5487  2014-01-28 21:40:08           2       1i7jScV
	## 5498  2014-01-28 21:40:08           2       1i7jScV
	## 1652  2014-01-25 14:45:12           2        KTOyCl
	## 1654  2014-01-25 14:45:12           2        KTOyCl
	## 1053  2014-01-25 16:25:03           4        KU505B
	## 1055  2014-01-25 16:25:03           4        KU505B
	## 952   2014-01-25 16:40:13           0        KU7i4F
	## 954   2014-01-25 16:40:13           0        KU7i4F
	## 172   2014-01-25 18:45:06           0        LVmfEb
	## 174   2014-01-25 18:45:06           0        LVmfEb
	## 163   2014-01-25 18:45:08           0        LVmgYU
	## 166   2014-01-25 18:45:08           0        LVmgYU

Those `click.count` numbers are close enough (OK, *exact*) that it looks like it might be a data collection/management issue (these RESTful APIs can be annoying at times). From my own examination of the bit.ly API, I'm pretty sure it's supposed to be the creation time of the link, so we'll remove the duplicates before continuing:

	:::r
	grantdad <- grantdad[!duplicated(grantdad$long.url), ]

With the data cleaned up we can aggregate `clicks` and `counts` (short URL creations) by anything we want. We'll start with by-minute aggregation:

	:::r
	# aggregate URL creation and clicks by minute
	clicks <- count(grantdad, c("ts.min", "host"), wt_var = "click.count")
	colnames(clicks) <- c("ts", "host", "clicks")
	counts <- count(grantdad, c("ts.min", "host"))
	colnames(counts) <- c("ts", "host", "counts")
	by.min <- merge(clicks, counts)

	# across all hosts
	summary(by.min$counts)

	##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
	##     1.0    58.0    59.0    57.8    59.0    60.0

	# per-host
	by(by.min, by.min$host, function(x) {
	    summary(x$counts)
	})

	## by.min$host: myftp.biz
	##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
	##     1.0    58.0    58.0    57.6    59.0    60.0 
	## -------------------------------------------------------- 
	## by.min$host: myftp.org
	##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
	##    54.0    58.0    59.0    58.5    59.0    60.0 
	## -------------------------------------------------------- 
	## by.min$host: serveftp.com
	##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
	##    12.0    58.0    58.0    57.2    59.0    60.0

	gg <- ggplot(by.min, aes(factor(host), counts))
	gg <- gg + geom_boxplot(aes(fill = host))
	gg <- gg + theme_bw()
	gg <- gg + labs(x = "Target Host", y = "Click Count (per min)", title = "Click Counts (per-host, by minute)")
	gg <- gg + theme(legend.position = "none")
	gg

![plot of chunk ByMinuteBoxPlot](/blog/images/2014/02/ByMinuteBoxPlot.svg) 

The [bit.ly API best practices](http://dev.bitly.com/best_practices.html) page does not explicitly state what the per-minute link-creation rate limit is, but it *sure* looks like `grantdad` at least *assumed* it was 60 short-links per minute. (NOTE: `grantdad` could have been under a `no-ip.com` API rate limit threshold requirement as well&hellip;I didn't look at `no-ip.com` API details)

Before we do further work with per-minute information (i.e. try do hourly aggregation), we should examine the source data a bit more closely. Since the original post documents that the time periods are:

- 18:30 and 19:10 (Jan 25)
- 09:40 and 22:10 (Jan 28)
- 23:20 and 23:59 (Feb 04)
- 00:00 and 03:40 (Feb 05)

let's look at block of the complete hours of January 28<sup>th</sup> (the longest contiguous stretch in the data set) to see if there might be more methods to `grantdad`'s maliciousness (and to get a feel for how we should do any extrapolation):

	:::r
	# extract 10:00 up to (but not including) 20:00
	jan28 <- grantdad[grep("2014-01-28 1[0-9]", grantdad$ts), ]
	by(jan28, jan28$host, function(x) {
	    summary(factor(gsub("(^2014-01-28 |\\:00$)", "", as.character(x$ts.min))))
	})

	## jan28$host: myftp.biz
	## 10:05 11:00 11:20 11:30 12:20 13:40 14:35 14:55 15:30 15:40 16:15 16:40 
	##    57    58    59    57    59    59    59    59    59    59    59    59 
	## 17:15 17:20 17:30 18:00 18:10 18:25 19:20 19:25 19:30 19:50 
	##    59    59    59    59    59    59    59     1    60    60 
	## -------------------------------------------------------- 
	## jan28$host: myftp.org
	## 10:20 10:30 10:40 10:50 11:15 11:40 11:50 12:05 12:30 12:40 12:50 13:05 
	##    59    59    59    59    57    59    59    59    59    59    59    59 
	## 13:25 13:50 14:05 14:15 14:30 15:50 16:25 16:30 16:50 17:50 18:15 18:35 
	##    59    59    59    59    59    59    59    59    59    59    59    59 
	## 19:10 
	##    59 
	## -------------------------------------------------------- 
	## jan28$host: serveftp.com
	## 10:15 11:05 11:55 12:10 13:00 13:20 14:00 14:45 15:10 15:20 16:00 16:05 
	##    59    59    57    59    57    59    59    59    59    59    59    59 
	## 17:05 17:40 18:45 18:50 19:00 19:40 
	##    59    59    59    58    59    60

While this continues to show `grantdad` kept below the (again, assumed) 60 link creations per minute rate limit, he/she also spaced out the creation&mdash;albeit somewhat inconsistently&mdash;to every 5- or 10-minutes (and needed a bathroom break or fell asleep at 19:25, perhaps suggesting they were firing a script off by hand). 

We can look at each "minute chunk" in aggregate for that time period as well:

	:::r
	jan28.bymin <- factor(gsub("(^2014-01-28 1[0-9]\\:|\\:00$)", "", as.character(jan28$ts.min)))
	summary(jan28.bymin)

	##  00  05  10  15  20  25  30  35  40  45  50  55 
	## 351 411 236 352 413 178 471 118 473 118 531 116

	plot(jan28.bymin, col = "steelblue", xlab = "Minute", ylab = "Links Created", 
	    main = "Links Created", sub = "Jan 28 (1000-1959) grouped by Minute-in-hour")

![plot of chunk BarGraphLinksCreated](/blog/images/2014/02/BarGraphLinksCreated.svg) 

This is either the world's most inconsistent (or crafty) cron-job or `grantdad` like to press &#8593; + `ENTER` alot.

We can use this summary to get get an idea of the average number of links being created in a five-minute period:

	:::r
	# nine days
	summary(as.numeric(table(jan28.bymin)/9))

	##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
	##    12.9    18.1    39.1    34.9    47.5    59.0

If we use the `mean`, we then have **~35** links created every five minutes and can use that fact to do the extrapolation over the Jan 25-Feb 5 time period suggested in the article to get **120,576** total estimated links created during that 12-day period which is **about 10K more than estimated** in the Sucuri post and puts the complete estimate of created malicious links (assuming a start on Dec 16<sup>th</sup>) at **512,448**.

It looks like my assumption of the fields in the data files was accurate and both Sucuri and DDSec came to roughly the same conclusions (both are estimates, so neither is "right").

We may delve into the rest of the data provided by Sucuri, but want to express kudos again for sharing it and helping further the [reproducible research](http://reproducibleresearch.net/index.php/Main_Page) movement in the security domain.

You can grab all of the data files, including our combined `grantdad.txt` file over on [github](https://github.com/ddsbook/blog/tree/master/data/2014/02/sucuri). We stuck the `Rmd` [file](https://raw.github.com/ddsbook/blog/master/data/2014/02/sucuri/grantdad.Rmd) used to create this post there as well. `#reproducibleresearch`