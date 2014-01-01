						
function bookGitCommits() { 

	var col ;

	var format = d3.time.format("%Y-%m-%d");
	var margin = {top: 10, right: 15, bottom: 40, left: 15}
	var width = 630 - margin.left - margin.right ;
  var height = 400 - margin.top - margin.bottom ;

	var commits = d3.select("#commits").append("svg")
					    .attr("width", width + margin.left + margin.right)
					    .attr("height", height + margin.top + margin.bottom)
					    .append("g")
					    .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
	
	d3.csv("/blog/data/201401-dds-github2.csv", function(d) {
	  return {
	    Day: format.parse(d.Day),
	    Chapter: d.Chapter,
	    CommitCount: +d.CommitCount
	  };
	}, function(error, rows) {

    // get extents for ranges
		
    var dayExtents = d3.extent(rows, function(d){return d.Day});
    var commitCountExtents = d3.extent(rows, function(d){return d.CommitCount});

		var Y = d3.scale.linear()
          .domain(commitCountExtents)
          .range([height, 0]);
		var X = d3.time.scale()
          .domain(dayExtents)
          .range([margin.left, width]);
					
		var month_format = d3.time.format("%b");							

    var xAxis = d3.svg.axis().scale(X).ticks(6).tickFormat(month_format);
    var yAxis = d3.svg.axis().scale(Y).ticks(6).orient("left");

		 commits.append("g")
		      .attr("class", "y axis")
		      .attr("transform", "translate(5,0)")
		      .call(yAxis);

		 commits.append("g")
		      .attr("class", "x axis")
		      .attr("transform", "translate(0," + (height+margin.top) + ")")
		      .call(xAxis);
												
		
		 var col = d3.scale.category20().domain(d3.set(rows.map(function(d) { return(d.Chapter);})).values())

	 	 var g = commits.append("g")
		            .attr("transform", "translate(0,0)");

	   g.selectAll(".dot")
	       .data(rows)
	       .enter()
	 			.append("circle")
	 			.attr("class", function(d) { return("dot d-" + d.Chapter.replace("\.","")) })
	       .attr("cx", function(d) { return(X(d.Day)); })
	       .attr("cy", function(d) { return(Y(0)); })
	       .attr("r", function(d) { return(5); })
	       .style("fill", function(d) { return(col(d.Chapter)); })
	       .style("stroke", "white")
	       .style("stroke-width", "1.5px");

		 // gratituitious animation

	   g.selectAll(".dot")
       .data(rows)
	 	   .transition()
			 .ease("bounce")
	 	   .duration(1000)
       .attr("cy", function(d) { return(Y(d.CommitCount)); });
		 
		 var chapters = d3.set(rows.map(function(d) { return(d.Chapter) })).values().sort() ;
		 
		 d3.select("#ch")
		   .selectAll("li")
			 .data(chapters)
			 .enter()
			 .append("li")
			 .style("border","1px solid white")
			 .on("mouseover",function(d) {
				 
				 $(this).css("border","1px solid black");
				 
				 $.each(chapters, function(i, e) { 
					 
					 if (e != d) {
						 d3.selectAll(".d-" + e.replace("\.",""))
							 .transition()
							 .duration(500)
							 .attr("r", function(f) { 
								 return(2) ;
							 });
					 }
					 
					 d3.selectAll(".d-" + d.replace("\.",""))
						 .transition()
						 .duration(500)
						 .attr("r",10)
						 .each("end", function(d) { d3.select(this.parentNode.appendChild(this)).transition().duration(150)	; })
				 })
									 
				 var chDays = 0, chCommits = 0 ;
				 $.each(rows, function(i, r) {
					 if (r.Chapter == d) {
						 chDays++ ;
						 chCommits += r.CommitCount ;
					 }
				 });
				 
				 $("#info").css("color", col(d));
				 $("#info").text(d + " had " + chCommits + " commits across " + chDays + " days")  
				 					 
			 })
			 .on("mouseout", function(d) {
				 $("#info").text("")  
				 $(this).css("border","1px solid white");
				 d3.selectAll(".dot")
					 .transition()
					 .duration(500)
		       .style("fill", function(d) { return(col(d.Chapter)); })
		       .attr("r", function(d) { return(5); })
			 })
			 .text(function(d) { return(d) })
			 .style("background-color", function(d) { return(col(d)) })
			
	});					
};

bookGitCommits();