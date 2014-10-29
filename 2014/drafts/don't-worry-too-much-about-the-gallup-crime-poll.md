Title: Don't Worry _Too_ Much About The 2014 Gallup Crime Poll
Date: 2014-10-29 10:38:55
Category: blog
Tags: survey, datavis, r, rstats, rstat
Slug: don't-worry-too-much-about-the-gallup-crime-poll
Author: Bob Rudis (@hrbrmstr)

Gallup released the [results](http://www.gallup.com/poll/178856/hacking-tops-list-crimes-americans-worry.aspx) of their annual "Crime" poll in their Social Poll series this week and spent much time highlighting the fact that "cyber" was at the top of the list.

<center><img src="http://dds.ec/blog/images/2014/10/summary.svg"  style="max-width:100%"/></center>

(There's nary a visualization on the Gallup post or in the [accompanying PDF](http://www.gallup.com/file/poll/178877/141027CrimeWorry.pdf), so keep that graphic handy or use the [scraped/cleaned poll data and R source code](https://github.com/hrbrmstr/gallup-crime-2014) to make your own :-)

It's a "worry" survey, meaning it's about personal perception &amp; feelings. In this survey, over 25% of the respondents were victims of cyber crime (hopefully they sample well). As anyone in "cyber" knows, it's been a pretty rough year (the past few have been as well) and "cyber" has been in the news quite a bit:

<center><script type="text/javascript" src="//www.google.com/trends/embed.js?hl=en-US&q=%22data+breach%22&date=6/2014+5m&cmpt=q&content=1&cid=TIMESERIES_GRAPH_0&export=5&w=600&h=360"></script></center>

so, on the surface, it makes sense that cyber crimes might be on the top of the worry list. 

The "crime" survey is given once a year, usually in the fall, and there's an interesting correlation between this year's new addition of "cyber" to the question list and what occurred in their 2001 survey when they added "terrorism" to the list. Almost everyone reading this post knows what happed on September 11, 2001 and the revised Gallup poll happend just about a month after the bombings. You can compare 2000-2001 and 2013-2014 survey results in the chart below:

<center><img src="http://dds.ec/blog/images/2014/10/gallup.svg"  style="max-width:100%"/></center>

Looking at those year-pairs, we see a similar pattern: the most recent, top-of-mind, in-the-news item becomes the heavy hitter in the poll results, regardless of whether the worry is really substantiatd (though it was "real" to the respondents).

We can coerce these crimes into a "top 10" rank and plot them across time (i.e. a rank-order parallel coordinate chart), though it's a little tricky to follow the lines in this non-interactive version, so click for larger image:

<a class="mag" href="http://dds.ec/blog/images/2014/10/gallup-rank.png"><img style="max-width:100%" src="http://dds.ec/blog/images/2014/10/gallup-rank.png"></a>

Let's test the "in the news theory" with "Car stolen not present" crime since it has two peaks:

<center><img src="http://dds.ec/blog/images/2014/10/car-stolen.png"  style="max-width:100%"/></center>

that we see mirrored in a Google Trends search:

<code><script type="text/javascript" src="//www.google.com/trends/embed.js?hl=en-US&q=car+stolen,+auto+theft&cmpt=q&content=1&cid=TIMESERIES_GRAPH_0&export=5&w=600&h=360"></script></code>

I didn't poke to see if "home burglaries" were truly greater in 2013 than stolen cars, but the main point is that the "worries" of these survey respondents reflect what makes the news and that doesn't necessarily mean they need to be *your* worries, too. It also doesn't mean that these newsworthy events are likely to impact you. What it may also show is that you may be able to use Google Trends as a proxy for this survey in the future. Sadly, Google Trends doesn't go back beyond 2004, so it's difficult to look at the other "spikes" in the top-rankings.

The last point is to _always dig deeper_ if you can get the data. You can find CSV files for the published survey results (it's not _all_ the data they collected, just what they released) and some R code to make the graphs [over on github](https://github.com/hrbrmstr/gallup-crime-2014).