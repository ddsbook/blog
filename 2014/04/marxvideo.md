Title: Visualizing countries from the Marx data
Date: 2014-04-16 22:15:04
Category: R
Tags: R, video, Marx
Slug: marxvideo
Author: Jay Jacobs (@jayjacobs)

Last month at the local R user group, I offered up the ["marx" data we host on this site](http://datadrivensecurity.info/blog/pages/dds-dataset-collection.html) as a data challenge to the group.  The data is quite fun to play with and is (I hope) relatively straight forward to understand, even for non-infosec folks.  It's just 9 computers on the internet recording the network packets they recieve.

The data challenge we set up is very open-ended as the only "challenge" was just to explore the data and try to pull something interesting from it.  I offered up some things I've done before with the "Inspecting Internet Traffic" posts of [Part 1](http://datadrivensecurity.info/blog/posts/2014/Jan/blander-part1/) and [Part 2](http://datadrivensecurity.info/blog/posts/2014/Jan/blander-part2/).  Then Bob touched on the data with his interesting [Malicious Cartography in D3 : Part 1](http://datadrivensecurity.info/blog/posts/2014/Jan/malicious-cartography-part-1/) post.

My original plan was to create a shiny application that enabled the user to select and compare multiple destimation ports over time but time was not on my side for that one.  Earlier this week, I posted a [short tutorial](http://datadrivensecurity.info/blog/posts/2014/Apr/video-in-R/) on creating data-driven videos in R and I figured creating a video of the marx data would be rather fun (and perhaps a little challenging).  

Within the marx data, we have 28 weeks and chances are good the first and last are partial weeks.  For this exercise I am just picking out a subset so it's somewhat manageable.  I first pick out the source countries and destination hosts within that time period and the aggregate the date into time series data at 5-minute intervals.

### The Payload

The "trick" to the this whole thing is to create a blank plot and add each data element using the base graphics within R.  No fancy ggplot for this one.  Each point is added with points(), the bar charts on the each side are created with rect(), the labels are all text() elements and each frame of this video is created individually and sequentially numbered.   I ended up creating 8,134 frames and it took just over 40 minutes (I think the png size here took a lot of time).  Once all of the images were created, I used the avconv tool (just like in the [tutorial](http://datadrivensecurity.info/blog/posts/2014/Apr/video-in-R/) I posted earlier) and generated an HD image to upload to youtube. 

This is the end result:

<iframe width="560" height="315" src="//www.youtube.com/embed/1fLHh7axV7A" frameborder="0" allowfullscreen></iframe>

The colors are unique for each source and the size of the balls are relative to the number of packets in a 5-minute window.  One interesting little twist I did is for each ball: I do a tiny rnorm() on the destination, giving a little sense of randomness to the video.  Without that it looked too machine-like as they just went in a straight and repeating line.

Some things that are interesting about this:

* Vietnam kicks off two sustained scans of almost all the hosts at 1:12 and 4:04 in the video.  This is rather interesting because these hosts are spread out all over the world and the source would have no way to know that these hosts were related.  This means they either scanned all AWS space across the world or they were scanning the whole internet.  No idea which.
* At 4:28, a source in Iran did a massive port scan of the single host in Tokyo creating a __huge__ point on the screen and the counts for each to jump way up.  At first it filled the whole screen and I had no idea why the screen was filling with a single color.  I ended up taking the square root of the packet count to feed into the size parameter.

The full source code is here:

<script src="https://gist.github.com/jayjacobs/10610909.js"></script>

