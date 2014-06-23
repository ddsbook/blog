Title: Can You Track Me Now? (Visualizing Xfinity Wi-Fi Hotspot Coverage) [Part 2]
Date: 2014-06-13 10:00:00
Category: blog
Tags: rstats, r, datavis, wifi, cartography, maps, RCurl
Slug: can-you-track-me-now-part-2
Author: Bob Rudis (@hrbrmstr)

<meta property="og:image" content="http://datadrivensecurity.info/blog/images/2014/05/density/California.png" />
<meta property="og:type" content="Article" />
<meta property="og:title" content="Can You Track Me Now? (Visualizing Xfinity Wi-Fi Hotspot Coverage) [Part 2]" />
<meta property="og:description" content="Discover and visualize Xfinity hotspot coverage"/>
<meta property="og:site_name" content="Data Driven Security"/>

>This is the second of a two-part series. [Part 1](http://datadrivensecurity.info/blog/posts/2014/Jun/can-you-track-me-now-part-1/) set up the story and goes into how to discover, digest & reformat the necessary data. This concluding segment will show how to perform some basic visualizations and then how to build beautiful & informative density maps from the data and offer some suggestions as to how to prevent potential tracking.

I'll start with the disclaimer from the previous article:

>**DISCLAIMER** I have no proof&mdash;nor am I suggesting&mdash;that Xfinity or BSG Wireless **is** actually maintaining records of associations or probes from mobile devices. However, the ToS & privacy pages on each of their sites did not leave me with any tpye of warm/fuzzy feeling that this data is not&mdash;in fact&mdash;being used for tracking purposes.

Purely by coincidence, [@NPRNews](http://twitter.com/nprnews)' [Steve Henn](https://twitter.com/HennsEggs) also decided to [poke at Wi-Fi networks](http://www.npr.org/blogs/alltechconsidered/2014/06/13/321389989/heres-one-big-way-your-mobile-phone-could-be-open-to-hackers) during their cyber series this week and noted other potential insecurities of Comcast's hotspot network. That means along with tracking, you could also be leaking a great deal of information as you go from node to node. Let's see just how pervasive these nodes are.

###Visualizing Hotspots

Now, you don't need the smartphone app to see the hotspots. Xfinity has a [web-based hotspot finder](http://hotspots.wifi.comcast.com/) based on Google Maps:

<a class="mag" href="/blog/images/2014/05/xfin-web.png"><img style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-web.png"/></a>

Those "dots" are actually bitmap tiles (even as you zoom in). Xfinity either did that to "protect" the data, save bandwidth or speed up load-time (creating 260K+ points can take a few, noticeable seconds). We can reproduce this in R without (and with) Google Maps pretty easily:

    :::r
    library(maptools)
    library(maps)
    library(rgeos)
    library(ggcounty)
    
    # you can grab ggcounty via:
    # install.packages("devtools")
    # install_github("hrbrmstr/ggcounty") 
    
    # grab the US map with counties
    
    us <- ggcounty.us(color="#777777", size=0.125)
    
    # plot the points in "Xfinity red" with a 
    # reasonable alpha setting & point size
    
    gg <- us$gg
    gg <- gg %+% xfin + aes(x=longitude, y=latitude)
    gg <- gg + geom_point(color="#c90318", size=1, alpha=1/20)
    gg <- gg + coord_map(projection="mercator")
    gg <- gg + xlim(range(us$map$long))
    gg <- gg + ylim(range(us$map$lat))
    gg <- gg + labs(x="", y="")
    gg <- gg + theme_bw()
    
    # the map tends to stand out beter on a non-white background
    # but the panel background color isn't truly "necessary"
    
    gg <- gg + theme(panel.background=element_rect(fill="#878787"))
    gg <- gg + theme(panel.grid=element_blank())
    gg <- gg + theme(panel.border=element_blank())
    gg <- gg + theme(axis.ticks.x=element_blank())
    gg <- gg + theme(axis.ticks.y=element_blank())
    gg <- gg + theme(axis.text.x=element_blank())
    gg <- gg + theme(axis.text.y=element_blank())
    gg <- gg + theme(legend.position="none")
    gg

<a class="mag" href="/blog/images/2014/05/xfin-ggplot-1.png"><img style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-ggplot-1.png"/></a>

    :::r
    library(ggmap)
    
    x_map <- get_map(location = 'united states', zoom = 4, maptype="terrain", source = 'google')
    xmap_gg <- ggmap(x_map)
    
    gg <- xmap_gg %+% xfin + aes(x=longitude, y=latitude)
    gg <- gg %+% xfin + aes(x=longitude, y=latitude)
    gg <- gg + geom_point(color="#c90318", size=1.5, alpha=1/50)
    gg <- gg + coord_map(projection="mercator")
    gg <- gg + xlim(range(us$map$long))
    gg <- gg + ylim(range(us$map$lat))
    gg <- gg + labs(x="", y="")
    gg <- gg + theme_bw()
    gg <- gg + theme(panel.grid=element_blank())
    gg <- gg + theme(panel.border=element_blank())
    gg <- gg + theme(axis.ticks.x=element_blank())
    gg <- gg + theme(axis.ticks.y=element_blank())
    gg <- gg + theme(axis.text.x=element_blank())
    gg <- gg + theme(axis.text.y=element_blank())
    gg <- gg + theme(legend.position="none")
    gg

<a class="mag" href="/blog/images/2014/05/xfin-ggplot-2.png"><img style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-ggplot-2.png"/></a>

>It's a bit interesting that they claim over a million hotspots but the database has less then 300K entries.

I made the dots a bit smaller and used a fairly reasonable alpha setting for them. However, the macro- (i.e. the view of the whole U.S.) plus dot-view really doesn't give a good feel for the true scope of the coverage (or possible tracking). For that, we can turn to state-based density maps.

There are many ways to generate/display density maps. Since we'll still want to display the individual hotspot points as well as get a feel for the area, we'll use one that outlines and gradient fills in the regions, then plot the individual points on top of them.

    :::rstats
    library(ggcounty)
    
    l_ply(grep("Idaho", unique(xfin$county), value=TRUE, invert=TRUE), function(state) {
    
      print(state) # lets us know progress as this takes a few seconds/state
    
      gg.c <- ggcounty(state, color="#737373", fill="#f0f0f0", size=0.175)
    
      gg <- gg.c$gg
      gg <- gg %+% xfin[xfin$county==state,] + aes(x=longitude, y=latitude)
      gg <- gg + stat_density2d(aes(fill=..level.., alpha=..level..), 
                                size=0.01, bins=100, geom='polygon')
      gg <- gg + scale_fill_gradient(low="#fddbc7", high="#67001f")
      gg <- gg + scale_alpha_continuous(limits=c(100), 
                                        breaks=seq(0, 100, by=1.0), guide=FALSE)
      gg <- gg + geom_density2d(color="#d6604d", size=0.2, alpha=0.5, bins=100)
      gg <- gg + geom_point(color="#1a1a1a", size=0.5, alpha=1/30)
      gg <- gg + coord_map(projection="mercator")
      gg <- gg + xlim(range(gg.c$map$long))
      gg <- gg + ylim(range(gg.c$map$lat))
      gg <- gg + labs(x="", y="")
      gg <- gg + theme_bw()
      gg <- gg + theme(panel.grid=element_blank())
      gg <- gg + theme(panel.border=element_blank())
      gg <- gg + theme(axis.ticks.x=element_blank())
      gg <- gg + theme(axis.ticks.y=element_blank())
      gg <- gg + theme(axis.text.x=element_blank())
      gg <- gg + theme(axis.text.y=element_blank())
      gg <- gg + theme(legend.position="none")
    
      ggsave(sprintf("output/%s.svg", gsub(" ", "", state)), gg, width=8, height=8, units="in", dpi=140)
      ggsave(sprintf("output/%s.png", gsub(" ", "", state)), gg, width=6, height=6, units="in", dpi=140)
    
    })

The preceeding code will produce a density map per state. Below is an abbreviated gallery of (IMO) the most interesting states. You can click on each for a larger (SVG) version.

>Some of SVGs have a hefty file size, so they might take a few seconds to load.

<center><div>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/California.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/California.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Florida.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Florida.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/NewJersey.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/NewJersey.png" width=200 height=200/></a>
<br/>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Indiana.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Indiana.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Connecticut.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Connecticut.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Mississippi.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Mississippi.png" width=200 height=200/></a>
<br/>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/DistrictofColumbia.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/DistrictofColumbia.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Massachusetts.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Massachusetts.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Pennsylvania.svg"><img src="http://datadrivensecurity.info/blog/images/2014/05/density/Pennsylvania.png" width=200 height=200/></a>
</div></center>
 
You can also single out your own state for examination:

<center><select id="items"></select></center>
<center>
  <div id="statediv">
   <a class="mag" id="statemag" href="http://datadrivensecurity.info/blog/images/2014/05/density/Alabama.svg">
     <img width=400 height=400 id="stateimg" src="http://datadrivensecurity.info/blog/images/2014/05/density/Alabama.png"/>
   </a>
 </div>
</center>

<script>

var states = [ "Alabama", "Arizona", "Arkansas", "California", "Colorado", 
               "Connecticut", "Delaware", "District of Columbia", "Florida", "Georgia",
               "Hawaii", "Idaho", "Illinois", "Indiana", "Kansas", "Kentucky", "Louisiana",
               "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi", 
               "Missouri", "New Hampshire", "New Jersey", "New Mexico", "New York", 
               "North Carolina", "Ohio", "Oregon", "Pennsylvania", "South Carolina", "Tennessee", 
               "Texas", "Utah", "Vermont", "Virginia", "Washington", "West Virginia", "Wisconsin" ];

$(document).ready(function() {

 $.each(states, function(val, text) { $('#items').append( $('<option></option>').val(text.replace(" ", "")).html(text) ) });
 
 $( "#items" ).change(function() {
   console.log("here");
   $('#stateimg').attr('src', 'http://datadrivensecurity.info/blog/images/2014/05/density/'+this.value+".png");
   $('#statemag').prop('href', 'http://datadrivensecurity.info/blog/images/2014/05/density/'+this.value+".svg");
 });

})

</script>

Now, these are just basic density maps. They don't take into account Wi-Fi range, so the areas are larger than actual signal coverage. The purpose was to show just how widespread (or minimal) the coverage is vs convey discrete tracking precision. As you jump from association to association, it would be trivial for any provider to "connect the dots".

###Covering Your Tracks

Comcast (Xfinity) and AT&amp;T aren't the only places where this tracking can occur. [CreepyDOL](http://arstechnica.com/security/2013/08/diy-stalker-boxes-spy-on-wi-fi-users-cheaply-and-with-maximum-creep-value/) was demoed at BlackHat in 2013 (making it pretty simple for almost anyone to setup tracking). Stores already [use your Wi-Fi associations](http://www.washingtonpost.com/blogs/the-switch/wp/2013/10/19/how-stores-use-your-phones-wifi-to-track-your-shopping-habits/) to [track you](http://www.ftc.gov/news-events/blogs/techftc/2014/02/my-phone-your-service). Navizon has a whole [product/service](http://www.navizon.com/product-navizon-indoor-triangulation-system) based on the concept.

Apple is trying to help with a [new  feature](http://9to5mac.com/2014/06/09/ios-8-randomizes-mac-address-while-scanning-wifi-blocks-marketers-tracking-you/) in iOS 8 that will randomize MAC addresses when probing for access points and [David Schuetz](http://twitter.com/darthnull) has advocated [deleting preferred networks](http://darthnull.org/2013/06/19/istupid) from your iOS networks list.

What can you do while you wait for iOS (and wait even longer for the framented Android world to catch up)? Android users can give AVG's new [PrivacyFix](https://play.google.com/store/apps/details?id=com.avg.privacyfix) a go, but one of your only direct controls is to disable Wi-Fi, but that might not truly help if your mobile operating system does not deal well with passive Wi-Fi probes. Another option (as mentioned above) is to regularly purge the list of previously associated networks. You could even go so far as to [bundle up your phone](http://www.popsci.com/gadgets/article/2013-08/how-protect-yourself-your-phone) and stop all signales coming in and out, but that somewhat defeats the purpose of having your mobile with you.

Remain aware that the tracking can happen invisibly anywhere and, perhaps more importantly, the dangers that open Wi-Fi networks pose in general. Use a VPN service like [Cloak](https://www.getcloak.com/) to at least ensure all your transmissions are free from local prying eyes so the trackers have as little data to associate with you as possible.

Finally, keep putting pressure on the FTC to [help with this privacy issue](http://www.privatewifi.com/5-ways-the-ftc-hopes-to-protect-your-privacy-on-mobile-devices/). While FTC/FCC efforts won't stop malicious actors, it might help reign in businesses and encourage more privacy innovation on the part of Apple/Android/Microsoft.















 