Title: The Basics of Bot Cartograpy (R + D3)
Date: 2014-01-06 12:00:00
Category: dataviz
Status: draft
Tags: book, blog, maps, R, d3
Slug: basics-of-bot-cartography
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

(This post expands on a topic presented in Chapter 5 of [Data Driven Security : The Book](http://amzn.to/ddsbook))

Cartographers (map makers) and infosec folk both have the unenviable task of figuring out the best way to communite complexity. 
Maps hold an unwarranted place of privilege in the minds of viewers and they seem to have taken an equally unwarranted place of 
status when it comes to infosec folk wanting to show where "badness" comes from. More often than not, these locations are displayed 
on a Google Map using the [maps API](https://developers.google.com/maps/). Google Maps is great for directions and managing 
specific physical waypoints but, they imply a pecision that is just not there when attributing IP address malfeasnace. Plus, 
when you use Google Maps, you're embedding a great deal of third-party code, tracking and URL calls that just aren't necessary when 
there are plenty of other ways to get points on a map and you're limited to a very "meh" projection.

This post will show you how to place points on a map in both R &amp; D3 in a slightly more accurate way than you can with Google Maps
and using a saner projection than the ubiquitous Mercator projection. The data we'll use is from the [@abuse_ch](https://zeustracker.abuse.ch/) [ZeuS Tracker](https://zeustracker.abuse.ch/). If you already know these mechanics, you can jump to the end 
of the post. Both the resultant R and D3 maps will be SVG images vs static bitmaps you may be used to generating and the D3 map 
can be extended to enable panning and zooming similar to Google Maps.

The R code is embedded in the post can also be found on [our github repo](https://github.com/ddsbook/blog/blob/master/extra/src/R/zeusmap.R),
and the D3 code is inhenently available via <code>view-source</code> in your browser.

###The Making of a Map

<script src="/blog/extra/d3.geo.projection.v0.min.js"></script>
<script src="/blog/exgtra/topojson.v1.min.js"></script>


    :::LassoXmlLexer
	<marker name="(encoded HTML for the Google Maps push-pin popup) " 
    address="(encoded HTML for the Google Maps push-pin popup)" 
		lat="44.4333" 
		lng="26.1" 
		type="bot" />
	</markers>


Original abuse.ch zeus tracker google map:

<img src="/blog/images/2014/01/abuse-gmap.png" width="630" height="394"/>

    :::SLexer
	library(XML)
	library(maptools)
	library(rgdal)
	library(sp)
	library(plyr)
	library(ggplot2)
	library(ggthemes)
  
	# data orignally from:
	# https://zeustracker.abuse.ch/images/googlemaps/googledb.php
  
	# read in the XML file
	zeus <- xmlTreeParse("~/Dropbox/R/zeus.xml", useInternalNodes=TRUE)
  
	# convert the XML data to an R data frame
	zeus.ls <- xmlToList(zeus)
	suppressWarnings(zeus.df <- data.frame(do.call(rbind, zeus.ls), 
	                                      stringsAsFactors=FALSE))
  
	# need lat/lng as numbers vs strings
	zeus.df$lat <- as.numeric(zeus.df$lat)
	zeus.df$lng <- as.numeric(zeus.df$lng)
  
	# convert lat/lng pair to Winkel tripel projection since it's #spiffy
	zeus.pts <- project(cbind(zeus.df$lng, zeus.df$lat), proj="+proj=wintri") 
	zeus.pts <- data.frame(zeus.pts)
	colnames(zeus.pts) <- c("lon", "lat")
  
  
	# make the world!
	# start with a shapefile from http://www.naturalearthdata.com/downloads/
	world <- readOGR(dsn="/path/to/ne_110m_admin_0_countries/", 
	                 layer="ne_110m_admin_0_countries")
  
	# and bend the data to the will of our fav projection
	world <- spTransform(world, CRS("+proj=wintri"))
  
	# fortify() makes it into a data frame we can use with ggplot()
	ff = fortify(world)
  
	# now plot the map with the bots
	# group=group keeps each polygon's points together
	gg <- ggplot(data=ff, aes(x=long, y=lat, group=group))
	# this adds the map layer using the overall data specified above
	gg <- gg + geom_polygon(fill="black",color="#7f7f7f", size=0.15)
	# intercourse Antarctica
	gg <- gg + coord_equal(ylim=c(-6600000,9500000),xlim=c(-14500000,16300000)) 
	# add the zeus bot points, using alpha to make it easer to see clusters
	gg <- gg + geom_point(data=zeus.pts, aes(x=lon, y=lat, group=NULL),
	                      shape=21, size=2, fill="#f3b24c",  
	                      color="#ffffcc", alpha=I(2/10))
	# don't need chart labels unless you're from off-planet
	gg <- gg + labs(x="", y="")
	# clear out most of the chart junk, but using an 'ocean' bg color
	gg <- gg + theme_bw()
	gg <- gg + theme(plot.background = element_rect(fill = "transparent",colour = NA),
	                 panel.border = element_blank(),
	                 panel.background =element_rect(fill = "#1C6BA0",colour = NA),
	                 panel.grid = element_blank(),
	                 axis.text = element_blank(),
	                 axis.ticks = element_blank(),
	                 legend.position="right",
	                 legend.title=element_blank())
	gg

R generated SVG:

<img src="/blog/images/2014/01/r-zeus.svg" width="630" height="400"/>

D3 bot map:

https://zeustracker.abuse.ch/

<center>
<div id="d3botmap" style="width:630px;padding:0;margin:0">
</div>
</center>	

<script>

makeBots = function() {
	
	// setup sizes so it fits in our blog post :-)
	
	var width = 630,
	    height = 500;

	// setup Winkel tripel projection, again sizing
	// it properly so the portion of the world we care
	// about fits in our blog post div

	var projection = d3.geo.winkel3()
	    .scale(145)
	    .translate([(width / 2)-30, height / 2])
	    .precision(.1);

	// auto-apply our new projection to paths we make

	var path = d3.geo.path()
	    .projection(projection);

	// append a startng svg, trimming view to get rid of Antarctica

	var svg = d3.select("#d3botmap").append("svg")
	    .attr("width", width)
	    .attr("height", height-90);
		
		
	// we'll need this helper function to convert our maker points
	// to the projection coordinate system
	
	pts = function(d) {
		return([+d3.select(d).attr("lng"), +d3.select(d).attr("lat")]);
	}

  // build the world from the topojson data

	d3.json("/blog/data/maps/world-50m.json", function(error, world) {

		// make the ocean
	
		svg.append("rect")
			  .attr("width", width)
			  .attr("height", height-90)
				.attr("fill","#1C6BA0");

		// make the land 
	
	  svg.insert("path", ".graticule")
	      .datum(topojson.feature(world, world.objects.land))
	      .attr("class", "wland")
	      .attr("d", path);

	  svg.insert("path", ".graticule")
	      .datum(topojson.mesh(world, world.objects.countries, function(a, b) { return a !== b; }))
	      .attr("class", "wboundary")
	      .attr("d", path);

		// add the bots
		// https://zeustracker.abuse.ch/images/googlemaps/googledb.php
		//
		// use d3.xml() to read in XML data then extract lat/lng from
		// each <marker> element

		d3.xml("/blog/data/zeus.xml", function(error, zeus) {
		
		  svg.selectAll(".wbot")
		    .data(zeus.documentElement.getElementsByTagName("marker"))
		    .enter()
				.append("circle")
				.attr("class", "wbot")
	      .attr("cx", function(d) { return projection(pts(d))[0]; })
	      .attr("cy", function(d) { return projection(pts(d))[1]; })
	      .attr("r", function(d) { return 2; });
							
		});

	});

	d3.select(self.frameElement).style("height", height + "px");
}

makeBots();
</script>