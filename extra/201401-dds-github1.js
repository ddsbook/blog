var dataset; // a global
var values = [];
d3.csv("/blog/data/201401-dds-github1.csv", function(error, csv) {
        if (error) return console.warn(error);
        dataset = csv;
        for(var i=0;i<dataset.length;i++){
            values.push(dataset[i].all);
        }
        genVis();
  });
function genVis() {
    var margin = { top: 50, right: 0, bottom: 0, left: 30 },
        width = 660 - margin.left - margin.right,
        height = 240 - margin.top - margin.bottom,
        gridSize = Math.floor(width / 24),
        days = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"],
        times = ["12p", "1a", "2a", "3a", "4a", "5a", "6a", "7a", "8a", "9a", "10a", "11a", "12a", "1p", "2p", "3p", "4p", "5p", "6p", "7p", "8p", "9p", "10p", "11p"];
    var colorScale = d3.scale.linear()
        .domain([0, 2, d3.max(dataset, function(d) { return +d.all; }) ])
        .range(["#FFFFFF", "#B0C4DE", "purple"]);
    var svg = d3.select("#chart").append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
    svg.append("text")
        .text("Show commits for:")
        .attr("x", width - 270)
        .attr("y", 0)
        .attr("transform", "translate(-6,-20)")
        .attr("font-family", "sans-serif")
        .attr("font-size", "15px")
        .attr("fill", "black");
    var alltoggle = svg.append("text")
        .text("Both")
        .attr("x", width - 120)
        .attr("y", 0)
        .attr("transform", "translate(-6,-20)")
        .attr("font-family", "sans-serif")
        .attr("font-size", "15px")
        .attr("fill", "limegreen")
        .style("cursor", "pointer")
        .on("click", function(d) {
            colorScale.domain([0, 2, d3.max(dataset, function(d) { return +d.all; }) ]);
            alltoggle.attr("fill", "limegreen");
            bobtoggle.attr("fill", "black");
            jaytoggle.attr("fill", "black");
            svg.selectAll("rect")
                .data(dataset)
                .on("mouseover", function(d){ return tooltip.text(d.all + ((d.all == 1) ? " commit" : " commits")).style("visibility", "visible");})
                .transition().duration(1000)
                .style("fill", function(d) { return colorScale(d.all); });
        });
    var bobtoggle = svg.append("text")
        .text("Bob")
        .attr("x", width - 80)
        .attr("y", 0)
        .attr("transform", "translate(-6,-20)")
        .attr("font-family", "sans-serif")
        .attr("font-size", "15px")
        .attr("fill", "black")
        .style("cursor", "pointer")
        .on("click", function(d) {
            colorScale.domain([0, 2, d3.max(dataset, function(d) { return +d.bob; }) ]);
            alltoggle.attr("fill", "black");
            bobtoggle.attr("fill", "limegreen");
            jaytoggle.attr("fill", "black");
            svg.selectAll("rect")
                .data(dataset)
                .on("mouseover", function(d){ return tooltip.text(d.bob + ((d.bob == 1) ? " commit" : " commits")).style("visibility", "visible"); })
                .transition().duration(1000)
                .style("fill", function(d) { return colorScale(d.bob); });
        });
    var jaytoggle = svg.append("text")
        .text("Jay")
        .attr("x", width - 40)
        .attr("y", 0)
        .attr("transform", "translate(-6,-20)")
        .attr("font-family", "sans-serif")
        .attr("font-size", "15px")
        .attr("fill", "black")
        .style("cursor", "pointer")
        .on("click", function(d) {
            colorScale.domain([0, 2, d3.max(dataset, function(d) { return +d.jay; }) ]);
            alltoggle.attr("fill", "black");
            bobtoggle.attr("fill", "black");
            jaytoggle.attr("fill", "limegreen");
            svg.selectAll("rect")
                .data(dataset)
                .on("mouseover", function(d){ return tooltip.text(d.jay + ((d.jay == 1) ? " commit" : " commits")).style("visibility", "visible");})
                .transition().duration(1000)
                .style("fill", function(d) { return colorScale(d.jay); 
            });
        });
    var dayLabels = svg.selectAll(".dayLabel")
        .data(days)
        .enter().append("text")
        .text(function (d) { return d; })
        .attr("x", 0)
        .attr("y", function (d, i) { return i * gridSize; })
        .style("text-anchor", "end")
        .attr("transform", "translate(-6," + gridSize / 1.5 + ")")
        .attr("class", function (d, i) { return ((i >= 1 && i <= 5) ? "dayLabel mono axis axis-workweek" : "dayLabel mono axis"); });
    var timeLabels = svg.selectAll(".timeLabel")
        .data(times)
        .enter().append("text")
        .text(function(d) { return d; })
        .attr("x", function(d, i) { return i * gridSize; })
        .attr("y", 0)
        .style("text-anchor", "middle")
        .attr("transform", "translate(" + gridSize / 2 + ", -6)")
        .attr("class", "timeLabel mono axis axis-worktime");
        // .attr("class", function(d, i) { return ((i >= 7 && i <= 16) ? "timeLabel mono axis axis-worktime" : "timeLabel mono axis"); });
    var tooltip = d3.select("body")
        .append("div")
        .style("background-color", "white")
        .style("text-align", "center")
        .style("padding", "5px")
        .style("border", "1px solid black")
        .style("border-radius", "4px")
        .style("box-shadow", "2px 2px 5px #888888")
        .style("position", "absolute")
        .style("z-index", "10")
        .style("visibility", "hidden")
        .text("a simple tooltip");
    var heatMap = svg.selectAll(".hour")
        .data(dataset)
        .enter().append("rect")
        .attr("x", function(d) { return (d.hour) * gridSize; })
        .attr("y", function(d) { return (d.day) * gridSize; })
        .attr("rx", 4)
        .attr("ry", 4)
        .attr("class", "hour bordered")
        .attr("width", gridSize)
        .attr("height", gridSize)
        .style("fill", "white")
        .on("mouseover", function(d){ return tooltip.text(d.all + ((d.all == 1) ? " commit" : " commits")).style("visibility", "visible");})
        // .on('mouseover', function(d){ return tooltip.text(d.ct).style("visibility", "visibile"); })
        .on("mousemove", function(){return tooltip.style("top", (event.pageY-10)+"px").style("left",(event.pageX+10)+"px");})
        .on("mouseout", function(){return tooltip.style("visibility", "hidden");});

    heatMap.transition().duration(1000)
        .style("fill", function(d) { return colorScale(d.all); });
}
