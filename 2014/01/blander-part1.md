Title: Inspecting Internet Traffic: Part 1
Date: 2014-01-16 22:30:00
Category: analysis
Tags: EDA, analysis
Slug: blander-part1
Status: draft
Author: Jay Jacobs (@jayajacobs)

<style>
.deirfig:hover {
	opacity:0.4;
}
</style>

Inspecting Internet Traffic: Part 1
========================================================

I like honeypots.  Not so much for what they show about individual attackers, but for what they can show about the trends across attackers.  I've struggled to get much honeypot data though, so if anyone has access and would like some help making sense of it, please let me know.

I recently got some data from my friend Daniel Blander.  He and I were talking about learning from honeypots some time ago, and he spun up several instances across the world and just let iptables capture packets.  He let these run from March to September last year and shared the data so we can play around with it.  I'm going to break this up over a three-part blog series.

Eventually I'll want to ask questions of this data.  Before I get to that, I'll want to explore this data, figure out what we have and what kinds of questions the data would be able to answer.  This is officially called exploratory data analysis (EDA) and it's attributed to [John Tukey](http://en.wikipedia.org/wiki/John_Tukey).  We'll use whatever we can to figure out what we've got in this data and simply improve our intuition about the data.  This should help use make connections and discoveries we wouldn't normally see.

I wrote a quick parser (in python) to convert the iptables log to a CSV, so I want to load the output of that up.

```r
csv <- read.csv("http://datadrivensecurity.info/data/2014/01/marx.csv")
# let's look at the first few rows.
head(csv)
```

```
##              datetime              host       src proto type   spt  dpt
## 1 2013-03-03 21:53:59    groucho-oregon 1.032e+09   TCP   NA  6000 1433
## 2 2013-03-03 21:57:01    groucho-oregon 1.348e+09   UDP   NA  5270 5060
## 3 2013-03-03 21:58:10    groucho-oregon 2.948e+09   TCP   NA  2489 1080
## 4 2013-03-03 21:58:09   groucho-us-east 8.418e+08   UDP   NA 43235 1900
## 5 2013-03-03 21:58:20 groucho-singapore 3.588e+09   TCP   NA 56577   80
## 6 2013-03-03 21:58:41     groucho-tokyo 3.323e+09   TCP   NA 32628 2323
```


If you'd like to follow along at home, use the URL above or the [csv is available for download]("/data/2014/01/marx.csv").

In case you don't recognize those source (src) and destination (dst) fields those are IP addresses.  They are much easier to store (and manipulate) in a long integer format than as a string in the dotted quad formats.  If you work with large data sets too or store these in a database, please convert to long first!

R provides a really nice summary() function that gives us a nice overall view of the data we have.

```r
summary(csv)
```

```
##                 datetime                     host       
##  2013-08-26 23:39:53:    96   groucho-tokyo    :126189  
##  2013-08-26 23:38:52:    81   groucho-oregon   : 94076  
##  2013-03-21 02:51:27:    78   groucho-singapore: 78151  
##  2013-07-24 07:55:02:    67   groucho-us-east  : 31779  
##  2013-04-28 04:10:16:    63   groucho-norcal   : 24566  
##  2013-04-28 04:10:19:    63   groucho-sydney   : 24456  
##  (Other)            :451133   (Other)          : 72364  
##       src            proto             type             spt       
##  Min.   :1.68e+07   ICMP: 44811   Min.   : 0       Min.   :    0  
##  1st Qu.:1.17e+09   TCP :327991   1st Qu.: 8       1st Qu.: 6000  
##  Median :2.03e+09   UDP : 78779   Median : 8       Median : 6000  
##  Mean   :2.15e+09                 Mean   : 8       Mean   :18685  
##  3rd Qu.:3.16e+09                 3rd Qu.: 8       3rd Qu.:33461  
##  Max.   :3.76e+09                 Max.   :13       Max.   :65535  
##                                   NA's   :406770   NA's   :44811  
##       dpt       
##  Min.   :    0  
##  1st Qu.:  445  
##  Median : 1433  
##  Mean   : 6684  
##  3rd Qu.: 3389  
##  Max.   :65500  
##  NA's   :44811
```

Looks like the host names are also going to help us determine the location of the hosts (that will be handy later).  Also the protocols (in the "proto" field) show that we had around 4 times as many TCP packets as UDP and even less ICMP packets.  Also, the source and destination ports (spt and dpt) show what's known as a five-number summary with the mean included.  It gives us an idea of the spread of ports used. 

R naturally converted the numeric fields to numbers but we may not want that on all the fields.  TCP and UDP ports are not really numbers and the ICMP type field (type) has an integer that represents the type of ICMP packet.  Let's convert that back to factor and look at the summary of the ICMP packet types.

```r
csv$type <- factor(csv$type)
summary(csv$type)
```

```
##      0      3      5      8     11     12     13   NA's 
##    536   4251    127  38597   1156      2    142 406770
```

The NA's are produced when there is no value (the protocol was not ICMP), but we can see that ICMP type 8 (ping) is the most seen icmp type. We could make a bar chart of that later perhaps, but it's enough to just see the numbers. Okay, now what?  Let's use the timestamp on the entries and plot the activity on each host over time.  We will want to look for any stretches of missing data, etc.


```r
csv$day <- as.Date(csv$datetime, format = "%Y-%m-%d %H:%M:%S")
# add a freq column
csv$freq <- c(1)  # they all occur once right now
hosts <- aggregate(freq ~ day + host, data = csv, FUN = sum)
head(hosts)
```

```
##          day       host freq
## 1 2013-03-03 groucho-eu    6
## 2 2013-03-04 groucho-eu  104
## 3 2013-03-05 groucho-eu   99
## 4 2013-03-06 groucho-eu   71
## 5 2013-03-07 groucho-eu  112
## 6 2013-03-08 groucho-eu   73
```

You can see the effect of aggregate() on the data.  It counted up the how many unique hosts for each day and put that into the freq column.  Now we can plot these just to see if we have any obvious holes or missing data.  Because the "day" column is a date field, the ggplot library will be smart about handling it on the x-axis.

```r
library(ggplot2)
# set up a ggplot instance, pretty color for each host
gg <- ggplot(hosts, aes(x = day, y = freq, fill = host))
# add in a simple bar plot
gg <- gg + geom_bar(stat = "identity", width = 1)
# create individual plots for each host with free scales
gg <- gg + facet_wrap(~host, scales = "free")
# simple theme, with no legend
gg <- gg + theme_bw() + theme(legend.position = "none")
print(gg)
```

<a href="/blog/images/2014/01/blander/all-packets.svg" target="_blank"><img src="/blog/images/2014/01/blander/all-packets.svg" style="max-width:100%" class="deirfig"/></a>


Now we're getting somewhere.  Pay attention to the scales on the y-axis, because they change and we can't just compare the heights across hosts here.  You can also see some really large spikes in traffic and the edges are quite jagged.  One thing we could apply is a moving average across this to smooth out the peaks and valleys, but we are just looking at total packet count.  What we might be seeing are more exhaustive scans by just a handful of hosts throwing off our counts here (one host sending thousands of packets).  Let's go back to our source data and aggregate again, but this time aggregate by unique source addresses per day.


```r
# remove duplicate source IP per host, per day
u.hosts <- aggregate(freq ~ day + host + src, data = csv, FUN = min)
# now we can aggregate nicely
hosts <- aggregate(freq ~ day + host, data = u.hosts, FUN = sum)
```


Now we can plot that.


```r
# and create that same plot
gg <- ggplot(hosts, aes(x = day, y = freq, fill = host))
gg <- gg + geom_bar(stat = "identity", width = 1)
gg <- gg + facet_wrap(~host, scales = "free")
gg <- gg + theme_bw() + theme(legend.position = "none")
print(gg)
```

<a href="/blog/images/2014/01/blander/unique-hosts.svg" target="_blank"><img src="/blog/images/2014/01/blander/unique-hosts.svg" style="max-width:100%" class="deirfig"/></a>




And let's take a seven day moving average, and let's remove the free scales on the y-axis.  This will allow us to compare the heights across each panel  directly by it's height in the panel.

 A moving average will apply take an average of moving window (in our case, 7 days) and the result is a reduction and widening of the spikes and smoothing of the valleys.  We'd do this to see trends over time.


```r
# need to reshape, (melt, cast)
library(reshape)
```


```r
# cast this into a data.frame so we can operate on individual hosts
hmatrix <- cast(hosts, day ~ host, value = "freq")
# now loop on each host and apply a 7-day moving average
host.ma <- apply(hmatrix[, -1], 2, filter, filter = rep(1/7, 7))
# bring the days back in.
host.ma <- cbind(hmatrix$day, as.data.frame(host.ma))
# fix the column names
colnames(host.ma) <- colnames(hmatrix)
# get it back into a data frame for ggplot
hosts.ma <- melt(host.ma, id = c("day"), na.rm = T)
# and fix the names on it.
colnames(hosts.ma) <- c("day", "host", "freq")
gg <- ggplot(hosts.ma, aes(x = day, y = freq, fill = host))
gg <- gg + geom_bar(stat = "identity", width = 1)
gg <- gg + facet_wrap(~host)
gg <- gg + theme_bw() + theme(legend.position = "none")
print(gg)
```

<a href="/blog/images/2014/01/blander/unique-seven-day.svg" target="_blank"><img src="/blog/images/2014/01/blander/unique-seven-day.svg" style="max-width:100%" class="deirfig"/></a>

This is interesting, looks like the hosts in Oregon, Singapore and Tokyo are seeing about twice as many hosts as the others.  It might be nice to attribute that to geographical differences or perhaps these IP addresses have a history (prior to Daniel getting them), but we can't really assume any of those at this point.  

This post got long quick, so in the next post, we will continue to explore this data by looking at the ports...
