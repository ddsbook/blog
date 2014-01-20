Title: Malicious Cartograpy : Part 1 (Projections, Point Size and Opacity)
Date: 2014-01-16 12:00:00
Category: dataviz
Status: draft
Tags: maps, d3, map, cartography
Slug: malicious-cartography-part-1
Author: Bob Rudis (@hrbrmstr)

<style>
.wland {
  fill: #222;
}
.wboundary {
  fill: none;
  stroke: #7f7f7f;
  stroke-width: .15px;
}
.wbot {
	fill-opacity:0.2;
	stroke:#ffffcc;
	stroke-width:0.15;
	fill:#f3b24c;
}
</style>

<small><i>(This series of posts expands on a topic presented in Chapter 5 of [Data Driven Security : The Book](http://amzn.to/ddsbook))</i></small>

Cartographers (map makers) and infosec professionals both have the unenviable task of figuring out the best way to communite complexity to a diverse audience. Maps hold an unwarranted place of privilege in the minds of viewers and they seem to have taken an equally unwarranted place of status when it comes to infosec folk wanting to show where "badness" comes from. More often than not, these malicious locations are displayed on a Google Map using Google's [maps API](https://developers.google.com/maps/). Now, Google Maps is great for directions and managing specific physical waypoints, but they imply a level of precision that is just not there when attributing IP address malfeasnace. Plus, when you use Google Maps, you're embedding a great deal of third-party code, user tracking and URL calls that just aren't necessary when there are plenty of other ways to get the same points on a map; plus, if you don't delve into the Google Maps API, you're limited to a very *meh* representation of the globe.

This post kicks of a series that will cover the fundamentals of cartographic machinations and&mdash;at various points&mdash;show you how to make maps in D3 (and R/Python if time permits), all in a more accurate way than you can with Google Maps. The data we'll use is from the [`marx` data set](http://datadrivensecurity.info/blog/posts/2014/Jan/blander-part1/) in Jay's "*Inspecting Internet Traffic" series. You'll want to follow along until the final post as we'll be covering the most important aspect of creating map visualizations: when **not** to use them.


###The Making of a Map

Maps have three primary distinct attributes: _scale_, _projection_, and _symbolic representation_.  Any (all, really) of those elements distort reality in some way. _Scale_ distorts size and hides (or overemphasizes) detail. _Projections_ take our very 3D world and mathematically flatten it onto a 2D canvas, requiring numerous tradeoffs between accuracy and readability. _Symbols_ describe and distinguish geographic features and locations and guide viewers into knowing what bits are/aren't relevant. In this post, we're going to focus mainly on the _projection_ and _symbolic representation_ components, but we'll touch a bit on _scale_ as well.

The first thing we need to do is geolocate the honeypot data. There are real pitfalls when geolocating IP addresses that we cover fairly thoroughly in the book, so we'll issue a  *caveat lector*  and move on to adding geographic information to the `marx` data set with a simple Python script that uses the  [MaxMind GeoLite2](http://dev.maxmind.com/geoip/geoip2/geolite2/) database and Python API:

	:::PythonLexer
	import csv
	import geoip2.database
	 
	# sadly the geoip2 city() function expects a string, 
	# so we have to waste cycles converting our nice
	# long int to a string
	
	def to_string(ip):
	  return ".".join(map(lambda n: str(ip>>n & 0xFF), [24,16,8,0]))
	 
	# point this to wherever you downloaded the city database
	reader = geoip2.database.Reader('~/.maxmind/GeoLite2-City.mmdb')
	 
	with open('marx.csv', 'rb') as marx:
	
	  with open('marx-geo.csv', 'w') as f:
	  
	    flyreader = csv.reader(marx, delimiter=',', quotechar='"')
	    
	    for fly in flyreader:
	    
	      longIP = fly[2]
	      strIP = to_string(int(fly[2]))

	      # geoip2 can throw exceptions, so we need to handle that
	      
	      try:
	        r = reader.city(strIP)
	        f.write("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" % 
	                                    (fly[0], fly[1], longIP, fly[3], fly[4], fly[5], fly[6],
	                                     strIP,
	                                     r.country.iso_code,
	                                     r.country.name, 
	                                     r.subdivisions.most_specific.name,
	                                     r.subdivisions.most_specific.iso_code,
	                                     r.postal.code,
	                                     r.location.latitude,
	                                     r.location.longitude))
	      except:
	        f.write("%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n" % 
	                                     (fly[0], fly[1], longIP, fly[3], fly[4], fly[5], fly[6],
	                                      strIP, "", "", "", "", "", "", ""))
                                      
