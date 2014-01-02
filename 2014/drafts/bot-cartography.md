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

<script src="/blog/extra/d3.geo.projection.v0.min.js"></script>
<script src="/blog/exgtra/topojson.v1.min.js"></script>

D3 bot map:

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