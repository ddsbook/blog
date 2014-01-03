library(XML)
library(maptools)
library(rgdal)
library(sp)
library(plyr)
library(ggplot2)
library(ggthemes)

# https://zeustracker.abuse.ch/images/googlemaps/googledb.php

# read in the XML file
zeus <- xmlTreeParse("/path/to/zeus.xml", useInternalNodes=TRUE)

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

zeus.df$country <- gsub("\ *$","",gsub("^.*> ","",zeus.df$name))
country.bots <- count(zeus.df, "country")
country.bots[country.bots$country=="",]$country <- "UNRESOLVED"

gg <- ggplot(country.bots, aes(reorder(country,-freq),freq))
gg <- gg + geom_bar(stat="identity")
gg <- gg + theme_few()
gg <- gg + labs(x="", y="# bots")
gg <- gg + theme(axis.text.x = element_text(angle = 90, hjust = 1))
gg



