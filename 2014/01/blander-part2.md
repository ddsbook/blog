Title: Inspecting Internet Traffic: Part 2
Date: 2014-01-23 21:30:00
Category: analysis
Tags: EDA, analysis, honeypot, R
Slug: blander-part2
Author: Jay Jacobs (@jayjacobs)

<style>
.deirfig:hover {
	opacity:0.7;
}
</style>

This is part 2 of a series ([visit part 1](http://datadrivensecurity.info/blog/posts/2014/Jan/blander-part1/)).  I will be looking at destination ports in this post.

Bob and I spent quite a bit of time early on in the [book](http://bit.ly/ddsec) showing what we can learn from IP addresses.  But let's talk about ports. What's interesting about ports is that they appear numeric, but they really are a categorical variable (or in R, a `factor`).  `SSH(22)` isn't one less than `telnet(23) `and one more than `FTP(21),` right?  So whenever you include port numbers in a plot you'll want to convert them to a factor. Port numbers are also protocol specific, we can't group `UDP 1433` with `TCP 1433`.  So let's go back to Daniel Blander's "`marx`" data and look into the destination ports in the data.  Remember our goal here is to simply explore and improve our understanding of the data. As we develop our understanding, questions may naturally arise that we could try to tackle.


```r
csv <- read.csv("marx.csv")
summary(csv$dpt)
```

```
##    Min. 1st Qu.  Median    Mean 3rd Qu.    Max.    NA's 
##       0     445    1430    6680    3390   65500   44811
```


Weird huh.  Just reading in the CSV data, R sees a column of numbers and treats them like a continuous value.  As I mentioned above, this isn't right and not helpful for counting ports seen, so let's convert them to a factor and look at the top 10 or so.


```r
# convert to a factor and only show top 10 groups
summary(factor(csv$dpt), maxsum = 10)
```

```
##    1433     445    3389      80   56338    8080      22    3306 (Other) 
##  109425   40611   30077   19575   18196   15407   15106   14513  143860 
##    NA's 
##   44811
```

Now we're getting somehwere.  Except we didn't filter for just `TCP` traffic, so this may be conflating `TCP` and `UDP` ports.


```r
tcp.ports <- csv$dpt[csv$proto == "TCP"]
tcp.ports <- factor(tcp.ports)
summary(tcp.ports, maxsum = 10)
```

```
##    1433     445    3389      80    8080      22    3306     135      23 
##  109425   40611   30077   19574   15406   15102   14512   10180    8330 
## (Other) 
##   64774
```


And there we have it.  You can see that port 56338 dropped off (and wow, that's a weird `UDP` port). Also notice that a few of the ports dropped a few in numbers, looks like a few wild `UDP` packet on those ports have been removed.  

So `1433 (MS SQL)` is at the top followed by the` "Windows SMB over IP" port (445)`.  Just stop for a moment and think about what we're looking at.  Port 1433 was scanned for more than twice any other port.  What if we take a page from "no default password" and simply changed the default port to 1434?


```r
sum(tcp.ports == 1434)
```

```
## [1] 8
```


Right away, and without any real math to speak of, you should feel safe to recommend that default ports should be avoided if possible.  We haven't created any pretty charts yet, but we'll get to that eventually.

### What do we want to know about ports?

I've been thinking about this for quite a while.  I know there's something in this type of data we could learn from.  I know the ports scanned ebb and flow depending on the weaknesses out there and perceived benefit to the attacker.

I've also looked at other representations and found myself wondering what I was looking at.  For example, look at the [SANS DShield data on port 1433](http://www.dshield.org/port.html?port=1433).  I love that the DShield data is out there and available/searchable like that, but can you look at that plot and understand it's relative importance?  It seems like 40,000 hosts are a lot, but is this out of millions of collection points or twenty? It's hard to tell if this is really scary or just noisy -- a total count (of whatever) isn't helpful if we don't know the context (the sample we are counting within).

So I figured there are a few things I should strive for:

* Measure ports in a scale that has meaning to the reader
* Measurements should be comparable across ports
* Measurements should be mentally scalable (from one to thousands)

The measurement I decided to go with is the average unique hosts that attempt to connect on a port on one machine per day (that's a mouthful).  You should be able to internally picture the difference between 38 hosts scanning port 1433 and 13 hosts scanning for port 3389 on a single host on your network (and scale it to your environment).  This should enable us to internalize these numbers, maybe even remember them in a context.  Compare this to what we see in the dhsield data where the graph should 40,000 hosts per day total.  Is that a lot?  Plus without a notion of context, who knows if changes over time are a result of the host network changing or the threat landscape changing?  We need to include the notion of sample size in this.

So what does this look like?


```r
# convert to a Date value
csv$day <- as.Date(csv$datetime, format = "%Y-%m-%d %H:%M:%S")
# add a freq column
csv$freq <- c(1)  # they all occur once right now
# remove duplicate source IP and port per host, per day
tcp.uniq <- aggregate(freq ~ day + host + src + dpt, data = csv[csv$proto == 
    "TCP", ], FUN = min)
# rough idea of top 10
top.ports <- names(summary(factor(tcp.uniq$dpt), maxsum = 11))[1:10]

# now have unique source address, convert to count per day per host
host.tcp <- aggregate(freq ~ dpt + day + host, data = tcp.uniq, FUN = sum)
avg.tcp <- aggregate(freq ~ day + dpt, data = host.tcp, FUN = mean)
plot.tcp <- avg.tcp[avg.tcp$dpt %in% top.ports, ]
plot.tcp$dpt <- factor(plot.tcp$dpt, levels = top.ports, ordered = T)
library(ggplot2)
gg <- ggplot(plot.tcp, aes(x = dpt, y = freq))
gg <- gg + geom_boxplot(fill = "lightsteelblue")
gg <- gg + xlab("TCP Destination Port")
gg <- gg + ylab("Average Unique Source Addresses per day")
gg <- gg + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/blander/port-box.svg" target="_blank"><img src="/blog/images/2014/01/blander/port-box.svg" style="max-width:100%" class="deirfig"/></a>


So now we are getting somewhere with the above boxplot. If you aren't familiar with the boxplot, this is showing the distribution of values we've recorded.  This is capturing the variance in these readings.  See how 1433 has days (outliers) when they spike up over 60 hosts per day and yet dip down under 20 hosts per day.  Port 135 seems have a lot more variance compared to it's neighbors.  Why?  No idea, but maybe we'll see something if we plot this over time per port.  This is looking at an aggregate over seven montshs, we need to include the element of time and let's ditch the box plot.  Maybe we can visualize this to emphasize the element of time and perhaps make any trends more obvious. 


```r
# add in the month value by hand here.
plot.tcp$month <- factor(months(plot.tcp$day), levels = month.name, ordered = T)

gg <- ggplot(plot.tcp, aes(x = month, y = freq))
gg <- gg + facet_wrap(~dpt, ncol = 2, scales = "free")
# gg <- gg + geom_boxplot(fill='lightsteelblue')
gg <- gg + geom_jitter(size = 1, alpha = 1/2, color = "magenta")
gg <- gg + geom_smooth(aes(group = 1), method = "loess", level = 0.99)
gg <- gg + xlab("TCP Destination Port")
gg <- gg + ylab("Average Unique Source Addresses per day")
gg <- gg + theme_bw()
print(gg)
```

<a href="/blog/images/2014/01/blander/port-smooth.svg" target="_blank"><img src="/blog/images/2014/01/blander/port-smooth.svg" style="max-width:100%" class="deirfig"/></a>


Now that's pretty interesting.  We could start to see trends over time.  What's interesting is that this is averaged across all the hosts.  So dramatic changes are smoothed out across the hosts and overall trends are much easier to see. Now there are many ways we could continue to look at this: we could use each host's values per day (not averaging across hosts), or look for differences across demographics (location, type of hosting if we had it, etc).  

With just this data, we coud explore questions like, why does port 23 increase since May, is that significant? If we added more data like this, we could increase our confidence in the samples, maybe even test more about the demographics of servers.  But right now we could view two or more ports on top of one another, on the same scale and get a feel for their relative differences. 

Wrapping up, I find it quite fun to explore data like this and it'd be nice to dig into other ports and look at the `UDP` ports as well (there was that odd 56338 in there).  But time and space don't enable that.  However, just reading through this, what questions does this raise for you?
