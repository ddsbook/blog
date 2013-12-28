Title: Second Post!
Date: 2013-12-28 08:23:00
Category: News
Tags: book, blog
Slug: second-post
Author: Bob Rudis (@hrbrmstr)

Lorem markdownum neque. [Celsoque](http://www.reddit.com/r/haskell) et habebat
pascua armo quoque. Regna erat me mediis coluit, est verba forsitan Rhodopeius
ille, nequiquam mecum oculosque faventum: [est](http://jaspervdj.be/).

> Velox monedula mandabat salve; extremos natis mitissima neque velantibus sibi:
> tenet. Erat Achilles, ut intrat temporis timeam. Amari isto, quod.

Taurusque inmedicabile Delon. Das super prosunt haberet; et dixit Troica
sanguinis hominum ambiguus ultima. Fuit auro digitis nisi operosa qua inde
sequens fidibusque incesto. Nunc quae, tam nec aptato terris praetentaque forma
petis pennas, culpa lacertis terris: si!

- Inque mihi pes exiguus poscunt neque sit
- Consolor et potes visa prius Thebae unda
- Veterem illas ferox etiam
- Est dedit signatum
- Hoc Idan forti pervenit auras

### Tu tecti contento

Celsoque exstinguere **Clytien** facto; atra aquas faces primordia indigno
inexpleto Ausoniis rursusque filia populos vidit Ampycides molimine Tenedon vix.
Huc cornibus Ammon. Pati tangit animus; et saepe se munera canum. Dum coma
ritusque; Caesaris spargit inter tanti pulvereumque **nefas lacertis**,
frondere.

	:::SLexer
	library(XML)
	library(maptools)
	library(sp)
	library(plyr)

	# Small script to get county-level outage info from Bangor Hydro
	# Electric's town(-ish) level info
	#
	# BHE's outage google push-pin map is at
	#   http://apps.bhe.com/about/outages/outage_map.cfm

	# read BHE outage XML file that was intended for the google map
	# yep. One. Line. #takethatpython

	doc <- xmlTreeParse("http://apps.bhe.com/about/outages/outage_map.xml", 
	                    useInternalNodes=TRUE)

	# xmlToDataFrame() coughed up blood on that simple file, so we have to
	# resort to menial labor to bend the XML to our will

	doc.ls <- xmlToList(doc)
	doc.attrs <- doc.ls$.attrs
	doc.ls$.attrs <- NULL

	# this does the data frame conversion magic, tho it winces a bit

	suppressWarnings(doc.df <- data.frame(do.call(rbind, doc.ls), 
	                                      stringsAsFactors=FALSE))

	# need numbers for some of the columns (vs strings)

	doc.df$outages <- as.numeric(doc.df$outages)
	doc.df$lat <- as.numeric(doc.df$lat)
	doc.df$lng <- as.numeric(doc.df$lng)

	# SpatialPoints likes matrices, note that it's in LON, LAT order
	# that always messes me up for some reason

	doc.m <- as.matrix(doc.df[,c(4,3)])
	doc.pts <- SpatialPoints(doc.m)

	# I trimmed down the country-wide counties file from
	#   http://www.baruch.cuny.edu/geoportal/data/esri/usa/census/counties.zip
	# with
	#   ogr2ogr -f "ESRI Shapefile" -where "STATE_NAME = 'MAINE'" maine.shp counties.shp
	# to both save load time and reduce the number of iterations for over() later

	counties <- readShapePoly("/Users/bob/Desktop/counties/maine.shp", 
	                          repair=TRUE, IDvar="NAME")

	# So, all the above was pretty much just for this next line which does  
	# the "is this point 'a' in polygon 'b' automagically for us. 

	found.pts <- over(doc.pts, counties)

	# steal the column we need (county name) and squirrel it away with outage count

	doc.df$county <- found.pts$NAME
	doc.sub <- doc.df[,c(2,7)]

	# aggregate the result to get outage count by county

	count(doc.sub, c("county"), wt_var="outages")

	# where are the unresolved points?
	doc.df[is.na(doc.df$county),c(1:4)]

	# i only really want the data, but maps are spiffy. let's build our
	# own (i.e. not-google-y) map, keeping the "dots"

	library(ggplot2)

	ff = fortify(counties, region = "NAME")

	missing <- doc.df[is.na(doc.df$county),]

	gg <- ggplot(ff, aes(x = long, y = lat))
	gg <- gg + geom_path(aes(group = group), size=0.15, fill="black")
	gg <- gg + geom_point(data=missing, aes(x=lng, y=lat), 
	                      color="#feb24c", size=3)
	gg <- gg + coord_map(xlim=extendrange(range(missing$lng)), ylim=extendrange(range(missing$lat)))
	gg <- gg + theme_bw()
	gg <- gg + labs(x="", y="")
	gg <- gg + theme(plot.background = element_rect(fill = "transparent",colour = NA),
	                 panel.border = element_blank(),
	                 panel.background =element_rect(fill = "transparent",colour = NA),
	                 panel.grid = element_blank(),
	                 axis.text = element_blank(),
	                 axis.ticks = element_blank(),
	                 legend.position="right",
	                 legend.title=element_blank())
	gg

	range(missing$lng)
	range(missing$lat)

	extendrange(range(missing$lng))
	extendrange(range(missing$lat))

	gg <- ggplot(ff, aes(x = long, y = lat))
	gg <- gg + geom_polygon(aes(group = group), size=0.15, fill="black", color="#7f7f7f")
	gg <- gg + geom_point(data=doc.df, shape=21, aes(x=lng, y=lat, size=outages), 
	                      fill="#feb24c", color="yellow")
	gg <- gg + coord_map(xlim=extendrange(range(doc.df$lng)), ylim=extendrange(range(doc.df$lat)))
	# gg <- gg + coord_map(xlim=c(-71.5,-66.75), ylim=c(43,47.5))
	gg <- gg + theme_bw()
	gg <- gg + labs(x="", y="")
	gg <- gg + theme(plot.background = element_rect(fill = "transparent",colour = NA),
	                 panel.border = element_blank(),
	                 panel.background =element_rect(fill = "transparent",colour = NA),
	                 panel.grid = element_blank(),
	                 axis.text = element_blank(),
	                 axis.ticks = element_blank(),
	                 legend.position="right",
	                 legend.title=element_blank())
	gg

	ggsave("~/Desktop/map.svg", gg)


It modo misit *toto ab coniugium* hominesque, summos adeam! *Cum* dubium strage,
exquirere Cephalum offensa faciam, ubi sucos hic.

- Timidi nomen Notus
- Viro laudabat iussus
- Est parte damnare ululatibus felix squamas et
- Eget mihi Graecia ripa semihomines inpediit corpora

Lentae inscribenda orbe vulnere tendentemque caede pede contagia est haud
parantem dixit. Cornua tu terque morari, sumusve ut
[sumus](http://news.ycombinator.com/) mentita adspexerit fide furtiva aquarum!
Haeret tibi [elisi](http://zombo.com/) de portas virorum itum.

Parato et rostro operum et agresti ne nec *Philomela* murmurat. Parem elige
pullosque adstupet hostem cacumen Echionides ignes effugiam pes alma: mare toro,
motu.

[Celsoque]: http://www.reddit.com/r/haskell
[elisi]: http://zombo.com/
[est]: http://jaspervdj.be/
[sumus]: http://news.ycombinator.com/