Title: Malicious Cartograpy : Part 1 (Projections, Point Size and Opacity)
Date: 2014-01-16 12:00:00
Category: dataviz
Status: draft
Tags: maps, d3, map, cartography
Slug: malicious-cartography-part-1
Author: Bob Rudis (@hrbrmstr)

<small><i>(This series of posts expands on a topic presented in Chapter 5 of [Data Driven Security : The Book](http://amzn.to/ddsbook))</i></small>

Cartographers (map makers) and infosec professionals both have the unenviable task of figuring out the best way to communite complexity to a diverse audience. Maps hold an unwarranted place of privilege in the minds of viewers and they seem to have taken an equally unwarranted place of status when it comes to infosec folk wanting to show where "badness" comes from. More often than not, these malicious locations are displayed on a Google Map using Google's [maps API](https://developers.google.com/maps/). Now, Google Maps is great for directions and managing specific physical waypoints, but they imply a level of precision that is just not there when attributing IP address malfeasnace. Plus, when you use Google Maps, you're embedding a great deal of third-party code, user tracking and URL calls that just aren't necessary when there are plenty of other ways to get the same points on a map; plus, if you don't delve into the Google Maps API, you're limited to a very *meh* representation of the globe.

This post kicks of a series that will cover the fundamentals of cartographic machinations and&mdash;at various points&mdash;show you how to make maps in D3 (and R/Python if time permits), all in a more accurate way than you can with Google Maps. The data we'll use is from the [`marx` data set](http://datadrivensecurity.info/blog/posts/2014/Jan/blander-part1/) in Jay's "*Inspecting Internet Traffic" series. You'll want to follow along until the final post as we'll be covering the most important aspect of creating map visualizations: when **not** to use them.


###The Making of a Map

Maps have three primary distinct attributes: _scale_, _projection_, and _symbolic representation_.  Any (all, really) of those elements distort reality in some way. _Scale_ distorts size and hides (or overemphasizes) detail. _Projections_ take our very 3D world and mathematically flatten it onto a 2D canvas, requiring numerous tradeoffs between accuracy and readability. _Symbols_ describe and distinguish geographic features and locations and guide viewers into knowing what bits are/aren't relevant. In this post, we're going to focus mainly on the _projection_ and _symbolic representation_ components, but we'll touch a bit on _scale_ as well.

The first thing we need to do is geolocate the honeypot data. There are real pitfalls when geolocating IP addresses that we cover fairly thoroughly in the book, so we'll issue a  *caveat lector*  and move on to adding geographic information to the `marx` data set with a simple Python script that uses the  [MaxMind GeoLite2](http://dev.maxmind.com/geoip/geoip2/geolite2/) database and Python API:

	:::python
	import csv
	import geoip2.database
	
	# yeah, despite having a nice long int, the city lookup function
	# requires a string so we have to do this
    
	def to_string(ip):
	  return ".".join(map(lambda n: str(ip>>n & 0xFF), [24,16,8,0]))
    
	# you'll need to download the city database and point this to it
		
	reader = geoip2.database.Reader('GeoLite2-City.mmdb')
    
	with open('marx.csv', 'rb') as marx:
	  with open('marx-geo.csv', 'w') as f:
	    flyreader = csv.reader(marx, delimiter=',', quotechar='"')
	    for fly in flyreader:
	      strIP = to_string(int(fly[2]))
	      try: # sometimes the city function coughs up blood
	        r = reader.city(strIP)
	        f.write("%s%s,%s,%s,%s,%s,%s,%s,%s\n" % 
	                                    (','.join(fly),
	                                     strIP,
	                                     r.country.iso_code,
	                                     r.country.name, 
	                                     r.subdivisions.most_specific.name,
	                                     r.subdivisions.most_specific.iso_code,
	                                     r.postal.code,
	                                     r.location.latitude,
	                                     r.location.longitude))
	      except:
	        f.write("%s%s,,,,,,,,\n" % (','.join(fly), strIP))

That will produce a new `CSV` file with expanded records that look like this:

	2013-03-03 21:53:59,groucho-oregon,1032051418,TCP,,6000,1433,61.131.218.218,CN,China,Jiangxi Sheng,36,,28.55,115.9333

For this demo we only need latitude and longitude pairs and we really only need unique pairs (_why_ will be explained in a bit). This extract _could_ have easily been done in the Python script, but by bailing out and switching to R for a second, it gives us a chance to introduce a pretty spiffy R libary and some R syntax that folks might not be familiar with.

	:::splus
	library(data.table)
	library(bit64)
    
	# data.table is a wicked fast data.frame compatible object
	# and fread() is a wicked fast file reader that behaves
	# like read.csv(). it's even faster and more efficient if
	# we provide a row count (estimate) so we do that here
    
	marx <- fread("marx-geo.csv", nrows=451582, sep=",", header=TRUE)
    
	# we only need lat/lon columns so we subset the data.table
	# on those columns, remove any missing coordinate pairs
	# and only retrieve unique pairs (since it's not important
	# for this map demo to have duplicate points)
    
	write.csv(unique(na.omit(marx[,14:15,with=FALSE])), "latlon.csv", row.names=FALSE)

Yep, that's it. Four lines of code (and the `library(bit64)` wasn't _technically_ necessary but various `data.table` routines whine on use if they don't see it in the namespace). The `data.table` library, as the comments above point out, provides a `data.frame` compatible object that is wicked fast to work with for large data sets. The `fread()` function is a much speedier and memory efficient alternative to `read.csv()`, especially when we give a hint as to the number of records. To generate our latitude & longitude pairs, we subset the `data.table` we created, extracting only columns 14 and 15. The `with=FALSE` part tells the subset operation to treat the `14:15` as column references versus the integer sequence "`14 15`". Those columns then are passed to `na.omit()` which removes any pairs that do not have complete values and from that set we only extract the unique pairs.

We can easily use the resulting ~5,000 lat/lon pairs to make one of those lovely push pin Google world Maps:

<img src="http://dds.ec/blog/images/2014/01/malmaps/gmaps.png" style="max-width:100%;width:630px"/>

Ugh. We can do better. _Much_ better. _Unless_ our goal is to generate a ZOMGOSH THE WORLD IS PWND! response from our audience.

###Mapping in D3

If you can't tell, we _really_ like the [D3 framework](http://d3js.org/) for data visualization projects, and D3 excels at map making. 

<iframe height="900px" frameborder="0" scrolling="no" seamless="seamless" width="630px" border="0" cellspacing="0" style="border-style: none; width: 100%; padding:0; border:0; height:900px; min-height:900px" src="/blog/vis/malmaps-d3/index.html"/></iframe>test