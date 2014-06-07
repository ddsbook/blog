Title: Can You Track Me Now? (Visualizing Xfinity Wi-Fi Hotspot Coverage)
Date: 2014-05-31 12:04:29
Category: blog
Status: draft
Tags: rstats, r, datavis
Slug: can-you-track-me-now
Author: Bob Rudis (@hrbrmstr)

Xfinity has a [Wi-Fi hotspot offering](http://wifi.comcast.com/) that they offer through a partnership with [BSG Wireless](http://bsgwireless.com/). Customers of Xfinity get access to the hotspots for "free" and you can pay for access to them if you aren't already a customer. I used the service a while back in near area where I live (which is just southwest of the middle of nowhere) when I needed internet access and 3G/4G connectivity was non-existent.

Since that time, I started noticing regular associations to Xfinity hotspots and also indicators saying it was available (i.e. when Wi-Fi was "off" on my phone but not *really* off). When driving, that caused some hiccups with streaming live audio since I wasn't in a particular roaming area long enough to associate and grab data, but was often in range **just* long enough to temporarily disrupt the stream.

On a recent family+school trip to D.C., I noticed nigh pervasive coverage of Xfinity Wi-Fi as we went around the sights (with varied levels of efficacy when connecting to them). That finally triggered a "Hrm. Somewhere in their vast database, they know I was in Maine a little while ago and now am in D.C.". There have been plenty of articles over the years on the privacy issues of hotspots, but this made me want to dig into just how pervasive the potential for tracking was on Xfinity Wi-Fi.

>**DISCLAIMER** I have no proof&mdash;nor am I suggesting&mdash;that Xfinity or BSG Wireless **is** actually maintaining records of associations or probes from mobile devices. However, the ToS & privacy pages on each of their sites did not leave me with any tpye of warm/fuzzy feeling that this data is not&mdash;in fact&mdash;being used for tracking purposes.

### Digging for data

Since the Xfinity Wi-Fi site suggests using their mobible app to find hotspots, I decided to grab it for both my iPhone & Galaxy S3 and see what type of data might be available. I first zoomed out to the seacoast region to get a feel for the Xfinity Wi-Fi coverage:

<center><a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-android.png"><img width=200 style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-android.png"/></a></center>

Yikes! If BSG (or any similar service) is, indeed, recording all associations & probes, it looks like there's almost nowhere to go in the seacoast area without being tracked.

Not wanting to use a tiny screen to continue my investigations, I decided to poke around the app a bit to see if there might be any way to get the locations of the hotspots to work with in R. Sure enough, there was:

<center>
  <a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-database-1.png"><img width=200 style="max-width:50%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-database-1.png"/></a>
  <a class="mag" href="http://datadrivensecurity/blog/images/2014/05/xfin-database-2.png"><img width=200 style="max-width:50%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-database-2.png"/></a>
</center>

I fired up [Burp Proxy](http://portswigger.net/burp/proxy.html), reconfigured my devices to use it and recorded session as I poked around the tool. There were "are you there?" checks before almost every API call, but I was able to see calls to a "discovery" service as well as the URLs for the region datasets.

The following Burp Proxy intercept shows that the app retrieving data from the "discovery" API and receiving a JSON response:

**REQUEST**

    (Host: http://datafeed.bsgwireless.com)

    POST /ajax/finderDataService/discover.php HTTP/1.1
    Accept-Encoding: gzip,deflate
    Content-Length: 40
    Content-Type: application/x-www-form-urlencoded
    Host: datafeed.bsgwireless.com
    Connection: Keep-Alive

    api_key=API_KEY_STRING_FROM_BURP_INTERCEPT

**RESPONSE**

    HTTP/1.1 200 OK
    Date: Sat, 31 May 2014 16:20:41 GMT
    Server: Apache/2.2.22 (Debian)
    X-Powered-By: PHP/5.4.4-14+deb7u9
    Set-Cookie: PHPSESSID=mci434v907571ihq7d16vtmce0; path=/
    Expires: Thu, 19 Nov 1981 08:52:00 GMT
    Cache-Control: no-store, no-cache, must-revalidate, post-check=0, pre-check=0
    Pragma: no-cache
    Vary: Accept-Encoding
    Content-Length: 1306
    Keep-Alive: timeout=5, max=100
    Connection: Keep-Alive
    Content-Type: text/html
            {"success":true,"results":{"baseURL":"http:\/\/comcast.datafeed.bsgwireless.com\/data\/comcast","fileList":[{"id":"45","name":"metadata.sqlite","title":"Metadata","description":null,"lastUpdated":"20140513","fileSize":"11264","txSize":"3210","isMeta":true},{"id":"51","name":"finder_comcast_matlantic.sqlite","title":"Mid-Atlantic","description":"DC, DE, MD, NJ, PA, VA, WV","lastUpdated":"20140513","fileSize":"9963520","txSize":"2839603","isMeta":false},{"id":"52","name":"finder_comcast_west.sqlite","title":"West","description":"AK, AZ, CA, CO, HI, ID, MT, NV, NM, ND, OR, SD, UT, WA, WY","lastUpdated":"20140513","fileSize":"5770240","txSize":"1644518","isMeta":false},{"id":"53","name":"finder_comcast_midwest.sqlite","title":"Midwest","description":"AR, IL, IN, IA, KS, KY, MI, MN, MO, NE, OH, OK, WI","lastUpdated":"20140513","fileSize":"3235840","txSize":"922214","isMeta":false},{"id":"54","name":"finder_comcast_nengland.sqlite","title":"Northeast","description":"CT, ME, MA, NH, NY, RI, VT","lastUpdated":"20140513","fileSize":"10811392","txSize":"3081246","isMeta":false},{"id":"55","name":"finder_comcast_south.sqlite","title":"South","description":"AL, FL, GA, LA, MS, NC, SC, TN, TX","lastUpdated":"20140513","fileSize":"5476352","txSize":"1560760","isMeta":false}],"generated":1401553245}}

We can use R to make the same request and also turn the JSON into R objects we can work with via the `jsonlite` library:

    :::rsplus
    library(RCurl)
    library(jsonlite)
    
    # post the same form/query via RCurl
    
    resp <- postForm("http://datafeed.bsgwireless.com/ajax/finderDataService/discover.php", 
                     api_key="API_KEY_STRING_FROM_BURP_INTERCEPT")
    
    # convert the JSON response to R objects
    
    resp <- fromJSON(as.character(resp))
    
    # take a peek at what we've got
    
    print(resp)
    ## $success
    ## [1] TRUE
    ## 
    ## $results
    ## $results$baseURL
    ## [1] "http://comcast.datafeed.bsgwireless.com/data/comcast"
    ## 
    ## $results$fileList
    ##   id                            name        title
    ## 1 45                 metadata.sqlite     Metadata
    ## 2 51 finder_comcast_matlantic.sqlite Mid-Atlantic
    ## 3 52      finder_comcast_west.sqlite         West
    ## 4 53   finder_comcast_midwest.sqlite      Midwest
    ## 5 54  finder_comcast_nengland.sqlite    Northeast
    ## 6 55     finder_comcast_south.sqlite        South
    ##                                                  description lastUpdated
    ## 1                                                       <NA>    20140513
    ## 2                                 DC, DE, MD, NJ, PA, VA, WV    20140513
    ## 3 AK, AZ, CA, CO, HI, ID, MT, NV, NM, ND, OR, SD, UT, WA, WY    20140513
    ## 4         AR, IL, IN, IA, KS, KY, MI, MN, MO, NE, OH, OK, WI    20140513
    ## 5                                 CT, ME, MA, NH, NY, RI, VT    20140513
    ## 6                         AL, FL, GA, LA, MS, NC, SC, TN, TX    20140513
    ##   fileSize  txSize isMeta
    ## 1    11264    3210   TRUE
    ## 2  9963520 2839603  FALSE
    ## 3  5770240 1644518  FALSE
    ## 4  3235840  922214  FALSE
    ## 5 10811392 3081246  FALSE
    ## 6  5476352 1560760  FALSE
    ## 
    ## $results$generated
    ## [1] 1401553861

We can see that each region from the app screen capture has an entry in the `resp$results$fileList` data frame that obviously corresponds to a SQLite database for that region. Furthermore, each one also shows when it was last updated (which you can then use to determine if you need to re-download it). There's also a `metadata.sqlite` file that might be interesting to poke around at as well.

The API also gives us the base URL which matches the request from the Burp Proxy session (when retrieving an individal dataset file). The following is the Burp Proxy request capture from the iOS app:

    (Host: http://comcast.datafeed.bsgwireless.com)

    GET /data/comcast/finder_comcast_nengland.sqlite HTTP/1.1
    Host: comcast.datafeed.bsgwireless.com
    Pragma: no-cache
    Proxy-Connection: keep-alive
    Accept: */*
    User-Agent: XFINITY%20WiFi/232 CFNetwork/672.1.14 Darwin/14.0.0
    Accept-Language: en-us
    Accept-Encoding: gzip
    Connection: keep-alive

The Android version of the app sends somewhat different request headers, including an `Authorization` header that Base64 decodes to `csl:123456` (and isn't used by the API):

    GET /data/comcast/finder_comcast_midwest.sqlite HTTP/1.1
    Accept-Encoding: gzip
    Host: comcast.datafeed.bsgwireless.com
    Connection: Keep-Alive
    User-Agent: Apache-HttpClient/UNAVAILABLE (java 1.4)
    Authorization: Basic Y3NsOjEyMzQ1Ng==

Given that there are no special requirements for downloading the data files (even the `User-Agent` isn't standardized between operating system versions), we can use plain ol' `download.file` from the "built-in" `utils` package to handle retrieval:

    :::rsplus
    # plyr isn't truly necessary, but I like the syntax standardization it provides
    
    library(plyr)
    
    l_ply(resp$results$fileList$name, function(x) {
      download.file(sprintf("http://comcast.datafeed.bsgwireless.com/data/comcast/%s", x),
                    sprintf("data/%s",x))
    })

>NOTE: As you can see in the example, I'm storing all the data files in a `data` subdirectory of the project I started for this exaple.

While the `metadata.sqlite` file *is* interesting, the data really isn't all that useful for this post since the Xfinity app doesn't use most of it (and is very US-centric). I suspect that data is far more interesting in the full BSG hotspot data set (which we aren't using here). Therefore, we'll just focus on taking a look at the hotspot data, specifically the `sites` table:

    :::sql
    CREATE TABLE "sites" (
      "siteUID"               integer PRIMARY KEY NOT NULL DEFAULT null, 
      "siteTypeUID"           integer NOT NULL DEFAULT null,
      "siteCategory"          integer DEFAULT null, 
      "siteName"              varchar NOT NULL DEFAULT null, 
      "address1"              varchar DEFAULT null, 
      "address2"              varchar DEFAULT null, 
      "town"                  varchar,
      "county"                varchar, 
      "postcode"              varchar, 
      "countryUID"            integer DEFAULT null, 
      "latitude"              double NOT NULL, 
      "longitude"             double NOT NULL, 
      "siteDescription"       text DEFAULT null, 
      "siteWebsite"           varchar DEFAULT null, 
      "sitePhone"             varchar DEFAULT null, 
      "operatorUID"           integer NOT NULL DEFAULT null, 
      "ssid"                  varchar(50), 
      "connectionTypeUID"     integer DEFAULT null, 
      "serviceProviderBrand"  varchar(50) DEFAULT null, 
      "additionalSearchTerms" varchar); 

>You can get an overview on how to use the SQLite command line tool in [the SQLite CLI documentation](http://www.sqlite.org/cli.html) if you're unfamiliar with SQL/SQLite.

The app most likely uses individual databases to save device space and bandwith, but it would be helpful if we had all the hotspot data in one data frame. We can do this pretty easily in R since we can work with SQLite databases via the `RSQLite` package and use `ldply` to combine results for us:

    :::rsplus
    library(RSQLite)
    library(sqldf)
    
    # the 'grep' is here since we don't want to process the 'metadata' file
    
    xfin <- ldply(grep("metadata.sqlite", 
                       resp$results$fileList$name, 
                       invert=TRUE, value=TRUE), function(x) {
    
      db <- dbConnect(SQLite(), dbname=sprintf("data/%s", x))
    
      query <- "SELECT siteCategory, siteName, address1, town, county, postcode, latitude, longitude, siteWebsite, sitePhone FROM sites"
    
      results <- dbSendQuery(db, query)
      
      # this makes a data frame from the entirety of the results
    
      aps <- fetch(results, -1)
    
      # the operation can take a little while, so this just shows progress
      # and also whether we retrieved all the results from thery for each call
      
      print(dbHasCompleted(results))
    
      dbClearResult(results)
    
      return(aps)
    
    })

>I had intended to use more than just `latitude` & `longitude` with this post, but ended up not using it. I left it in the query since a future post might use it and also as an example for those unfamiliar with using `SQLite`/`RSQLite`.

The function in the `ldply` combines each region's data frame into one. We can get a quick overview of what it looks like:

    :::rsplus
    str(xfin) 
    ## 'data.frame':	261365 obs. of  10 variables:
    ##  $ siteCategory: int  2 2 2 2 2 2 2 2 3 2 ...
    ##  $ siteName    : chr  "CableWiFi" "CableWiFi" "CableWiFi" "CableWiFi" ...
    ##  $ address1    : chr  "7 ELM ST" "603 BROADWAY" "6501 HUDSON AVE" "1607 CORLIES AVE" ...
    ##  $ town        : chr  "Morristown" "Bayonne" "West New York" "Neptune" ...
    ##  $ county      : chr  "New Jersey" "New Jersey" "New Jersey" "New Jersey" ...
    ##  $ postcode    : chr  "07960" "07002" "07093" "07753" ...
    ##  $ latitude    : num  40.8 40.7 40.8 40.2 40.9 ...
    ##  $ longitude   : num  -74.5 -74.1 -74 -74 -74.6 ...
    ##  $ siteWebsite : chr  "" "" "" "" ...
    ##  $ sitePhone   : chr  "" "" "" "" ...

###Visualizing Hotspots

Now, you don't need the smartphone app to see the hotspots. Xfinity has a [web-based hotspot finder](http://hotspots.wifi.comcast.com/) based on Google Maps:

<a class="mag" href="/blog/images/2014/05/xfin-web.png"><img style="max-width:100%" src="http://datadrivensecurity.info/blog/images/2014/05/xfin-web.png"/></a>

Those "dots" are actually bitmap tiles (even as you zoom in). Xfinity either did that to "protect" the data, save bandwidth or speed up load-time (creating 260K+ points can take a few, noticeable seconds). We can reproduce this in R without (and with) Google Maps pretty easily:

    :::rsplus
    library(maptools)
    library(maps)
    library(rgeos)
    library(ggcounty)
    
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

    :::rsplus
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

<center><div>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/California.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/California.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Florida.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Florida.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/NewJersey.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/NewJersey.png" width=200 height=200/></a>
<br/>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Indiana.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Indiana.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Connecticut.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Connecticut.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Mississippi.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Mississippi.png" width=200 height=200/></a>
<br/>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/DistrictofColumbia.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/DistrictofColumbia.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Massachusetts.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Massachusetts.png" width=200 height=200/></a>
<a class="mag" href="http://datadrivensecurity.info//blog/images/2014/05/density/Pennsylvania.svg"><img src="http://datadrivensecurity.info//blog/images/2014/05/density/Pennsylvania.png" width=200 height=200/></a>
</div></center>
 
 
 
 
 